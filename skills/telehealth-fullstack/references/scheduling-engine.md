# Scheduling & Availability Engine Architecture

This reference outlines the technical standards for appointment scheduling, slot generation, concurrency locks, and state machines in Telehealth platforms.

---

## 1. Slot Generation & Filtering

### Configuration Parameters
- `slotDurationMinutes`: Consultation interval (e.g. 15, 30, 45, 60 minutes).
- `bufferBetweenAppointmentsMinutes`: Rest/cleanup interval between sessions (e.g. 5 or 10 minutes).
- `minimumAdvanceNoticeHours`: Minimum hours before start time required to book or reschedule (e.g. 3 hours).
- `maximumAdvanceBookingDays`: Furthest date in the future a patient can book (e.g. 30 or 60 days).

### Generation Workflow
1. **Fetch Professional Rules:** Retrieve working shifts (e.g. Monday 08:00–12:00, 14:00–18:00), lunch breaks, and unavailabilities (holidays, vacations, doctor leaves).
2. **Retrieve Existing Commitments:** Query booked, confirmed, and temporarily locked slots for the professional within the query date range in UTC.
3. **Generate Discrete Slots:** Iterate from shift start to shift end stepping by `(slotDuration + bufferMinutes)`.
4. **Filter Invalids Proactively:**
   - Drop slots in the past or within the `minimumAdvanceNoticeHours` window (`slotStart <= nowUTC + 3h`).
   - Drop slots overlapping with existing appointments or blockages.
   - Return clean array of `{ startTimeUTC, endTimeUTC, professionalId, isAvailable: true }`.

---

## 2. Concurrency & Double-Booking Protection

Never rely solely on frontend validation. Telehealth platforms face simultaneous booking attempts during peak traffic.

### Level 1: Database Exclusion Constraints
Ensure the database schema enforces non-overlapping bookings per professional:
```sql
-- PostgreSQL with btree_gist extension
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE appointments
ADD CONSTRAINT no_overlapping_appointments
EXCLUDE USING gist (
  professional_id WITH =,
  tstzrange(start_time, end_time, '[)') WITH &&
)
WHERE (status NOT IN ('CANCELLED', 'NO_SHOW'));
```

### Level 2: Transactional Locking (Pessimistic Hold)
When confirming an appointment:
```typescript
await prisma.$transaction(async (tx) => {
  // Lock the professional schedule for the specific timeframe
  const conflicts = await tx.$queryRaw`
    SELECT id FROM appointments
    WHERE professional_id = ${professionalId}
      AND status NOT IN ('CANCELLED', 'NO_SHOW')
      AND tstzrange(start_time, end_time, '[)') && tstzrange(${startTime}::timestamptz, ${endTime}::timestamptz, '[)')
    FOR UPDATE
  `;

  if (conflicts.length > 0) {
    throw new SlotConflictError("Horário já selecionado por outro paciente.");
  }

  return tx.appointment.create({
    data: { professionalId, patientId, startTime, endTime, status: 'SCHEDULED' }
  });
});
```

### Level 3: Temporary Slot Hold (TTL Lock via Redis/Cache)
For checkout or payment flows requiring up to 10-15 minutes to pay:
- Key: `slot:lock:${professionalId}:${slotTimestamp}`
- Value: `patientId`
- TTL: 600–900 seconds (10–15 min).
- Release on successful payment, explicit cancellation, or TTL expiration.

---

## 3. Finite State Machine (FSM)

An appointment must follow explicit valid transitions:

```
[SCHEDULED] ───(payment / check-in)───► [CONFIRMED] ───(doctor starts)───► [IN_PROGRESS] ───(call ends)───► [COMPLETED]
      │                                       │
      ├───────(patient/dr cancels)────────────┼───────────────────────────► [CANCELLED]
      │                                       │
      ├───────(reschedule request)────────────┼───────────────────────────► [RESCHEDULED]
      │                                       │
      └───────(patient fails to attend)───────┴───────────────────────────► [NO_SHOW]
```

### Valid Transition Matrix
| Current State | Permitted Next States |
| :--- | :--- |
| `SCHEDULED` | `CONFIRMED`, `CANCELLED`, `RESCHEDULED` |
| `CONFIRMED` | `IN_PROGRESS`, `CANCELLED`, `RESCHEDULED`, `NO_SHOW` |
| `IN_PROGRESS` | `COMPLETED`, `CANCELLED` (emergency only) |
| `COMPLETED` | *Terminal state* (No further transitions) |
| `CANCELLED` | *Terminal state* |
| `RESCHEDULED`| *Terminal state* (A new appointment record is created) |
| `NO_SHOW` | *Terminal state* |

---

## 4. Cancellation & Rescheduling Rules
- **Rescheduling Notice:** Must enforce the same or stricter minimum notice as booking (e.g., minimum 3h before start).
- **Audit Requirement:** Always store `cancelledBy` (`PATIENT`, `PROFESSIONAL`, `SYSTEM`, `ADMIN`), `cancellationReason`, and `cancelledAt` in UTC.
- **Refund / Credit Triggers:** Integrate state changes with financial service events (e.g. automatic refund or credit generation if cancelled within policy).
