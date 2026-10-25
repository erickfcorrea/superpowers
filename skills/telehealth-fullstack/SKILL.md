---
name: telehealth-fullstack
description: Best practices for Full Stack development in Telehealth and Healthtech platforms (Next.js, TypeScript, React, APIs, booking/scheduling, data security, and compliance).
---

# Telehealth & Healthtech Full Stack Best Practices

This skill guides full-stack development for telehealth platforms (scheduling, video consultations, medical records, patient/professional flows, and payments) built with Next.js, React, TypeScript, and Node.js.

When working on deep domain modules, read the dedicated reference files:
- **Scheduling & Concurrency:** [references/scheduling-engine.md](references/scheduling-engine.md)
- **Timezones & Temporal Safety:** [references/timezone-and-temporal.md](references/timezone-and-temporal.md)
- **Compliance & PHI Protection:** [references/compliance-and-phi-protection.md](references/compliance-and-phi-protection.md)
- **Video & WebRTC:** [references/video-and-webrtc.md](references/video-and-webrtc.md)
- **Cache & Form Synchronization:** [references/tanstack-cache-and-forms.md](references/tanstack-cache-and-forms.md)

---

## 1. Scheduling & Availability Rules (Agendamentos e Horários)

- **Minimum Advance Notice (Antecedência Mínima):**
  - Always enforce business rules for scheduling and rescheduling (e.g., minimum 3 hours notice before the appointment time).
  - Filter out unavailable slots proactively in frontend selectors (`filterAvailableTimes`, `professionalAvailability`) to avoid user frustration.
- **Timezone Safety (Fusos Horários):**
  - Always store timestamps in UTC (`ISO 8601`) on the backend/database (`TIMESTAMP WITH TIME ZONE`).
  - Convert to the user's / clinic's timezone (`America/Sao_Paulo`) only at presentation time using reliable date libraries (e.g. `date-fns-tz`, `dayjs`).
  - Read [references/timezone-and-temporal.md](references/timezone-and-temporal.md) for hydration-safe Next.js SSR patterns.
- **Concurrency & Double-Booking Protection:**
  - Assume race conditions can occur when multiple patients try to book the same slot simultaneously.
  - Implement transactional locks, pessimistic DB locks (`SELECT ... FOR UPDATE`), or database exclusion constraints (`EXCLUDE USING gist`) on reservations.
- **Rescheduling & Cancellation States:**
  - Maintain a strict finite state machine for appointments: `SCHEDULED`, `CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`, `RESCHEDULED`, `NO_SHOW`.
  - Validate state transitions before allowing actions. Read [references/scheduling-engine.md](references/scheduling-engine.md).

---

## 2. Privacy & Compliance (LGPD / CFM / HIPAA)

- **Zero PHI in Logs:**
  - NEVER log Protected Health Information (PHI) such as CPF, patient full names, medical histories, diagnoses, or JWT tokens in console outputs, server logs, or third-party error trackers (Sentry/Datadog).
  - Mask sensitive identifiers in audit trails (e.g., `CPF: ***.456.789-**`). Read [references/compliance-and-phi-protection.md](references/compliance-and-phi-protection.md).
- **Role-Based Access Control (RBAC):**
  - Strictly enforce user role separation: `PACIENTE`, `PROFISSIONAL`, `RECEPCAO`, `ADMIN`.
  - Validate authorization at both API middleware level and UI presentation level. A patient must NEVER have access to another patient's appointments or clinical data.
- **Electronic Health Record (PEP) Immutability:**
  - Medical consultation notes and anamnesis cannot be edited after final sign-off; only signed addenda (`Adendos`) with timestamps can be appended.
  - Track every access and change with an immutable audit log.

---

## 3. Video Teleconsultation Architecture

- **Token Lifecycle:** Issue short-lived, ephemeral consultation tokens (30–60 min TTL) scoped strictly to the appointment room.
- **Pre-Flight Diagnostics:** Always run pre-flight camera, microphone, and permission checks before connecting to the video room.
- **Virtual Waiting Room:** Keep the patient in a polite waiting room until the doctor connects.
- **Teardown & Cleanup:** Explicitly stop all media tracks (`track.stop()`) when unmounting the consultation view to avoid lingering camera locks. Read [references/video-and-webrtc.md](references/video-and-webrtc.md).

---

## 4. Frontend Architecture (Next.js & React)

- **Domain vs UI Separation:**
  - Keep domain logic (e.g., `src/domain/booking/`, time filtering, slot calculation) separated from UI components (`src/features/`, modals, buttons).
- **TanStack React Query Cache Strategy:**
  - Use deterministic query key factories: `appointmentKeys.availability(professionalId, date)`.
  - Apply optimistic updates with automatic rollback for rescheduling and cancellations. Read [references/tanstack-cache-and-forms.md](references/tanstack-cache-and-forms.md).
- **Resilient Form Handling:**
  - Use React Hook Form with strict schema validation (Zod) for all appointment, patient registration, and medical forms.
- **Payment & Webhook Reliability:**
  - Ensure Stripe or Pix checkouts handle pending, failed, and webhook retries gracefully with idempotency keys to avoid duplicating appointment records.
