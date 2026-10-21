---
name: telehealth-fullstack
description: Best practices for Full Stack development in Telehealth and Healthtech platforms (Next.js, TypeScript, React, APIs, booking/scheduling, data security, and compliance).
---

# Telehealth & Healthtech Full Stack Best Practices

This skill guides full-stack development for telehealth platforms (scheduling, video consultations, medical records, patient/professional flows, and payments) built with Next.js, React, TypeScript, and Node.js.

## 1. Scheduling & Availability Rules (Agendamentos e Horários)

- **Minimum Advance Notice (Antecedência Mínima):**
  - Always enforce business rules for scheduling and rescheduling (e.g., minimum 3 hours notice before the appointment time).
  - Filter out unavailable slots proactively in frontend selectors (`filterAvailableTimes`, `professionalAvailability`) to avoid user frustration.
- **Timezone Safety (Fusos Horários):**
  - Always store timestamps in UTC (`ISO 8601`) on the backend/database.
  - Convert to the user's / clinic's timezone (`America/Sao_Paulo`) only at presentation time using reliable date libraries (e.g. `moment`, `date-fns`).
- **Concurrency & Double-Booking Protection:**
  - Assume race conditions can occur when multiple patients try to book the same slot simultaneously.
  - Implement transactional locks, optimistic locking, or database constraints on appointment reservations.
- **Rescheduling & Cancellation States:**
  - Maintain a strict finite state machine for appointments: `SCHEDULED`, `CONFIRMED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`, `RESCHEDULED`, `NO_SHOW`.
  - Validate state transitions before allowing actions.

## 2. Privacy & Compliance (LGPD / HIPAA / CFM)

- **Zero PHI in Logs:**
  - NEVER log Protected Health Information (PHI) such as CPF, patient full names, medical histories, diagnoses, or JWT tokens in console outputs, server logs, or third-party error trackers.
  - Mask sensitive identifiers in audit trails (e.g., `CPF: ***.456.789-**`).
- **Role-Based Access Control (RBAC):**
  - Strictly enforce user role separation: `PACIENTE`, `PROFISSIONAL`, `OPERADOR`, `ADMIN`.
  - Validate authorization at both API middleware level and UI presentation level. A patient must NEVER have access to another patient's appointments or clinical data.
- **Auditability:**
  - Every access, edit, or cancellation of appointments and medical records must be tracked with timestamp, user ID, and action performed.

## 3. Frontend Architecture (Next.js & React)

- **Domain vs UI Separation:**
  - Keep domain logic (e.g., `src/domain/booking/`, time filtering, slot calculation) separated from UI components (`src/features/`, modals, buttons).
- **TanStack React Query Cache Strategy:**
  - Use deterministic query keys: `['appointments', { professionalId, date }]`.
  - Invalidate queries selectively upon mutation (e.g. reschedule modal should invalidate only the affected professional's availability and the user's booking list).
- **Resilient Form Handling:**
  - Use React Hook Form with strict schema validation (Zod or Yup) for all appointment and medical forms.
- **Payment & Webhook Reliability:**
  - Ensure Stripe or gateway checkouts handle pending, failed, and webhook retries gracefully without duplicating appointment records.
