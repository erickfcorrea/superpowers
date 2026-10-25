# TanStack Cache Synchronization & Form Resilience

This reference outlines patterns for TanStack React Query cache management, optimistic updates, Zod validation, and webhook idempotency in Telehealth apps.

---

## 1. Deterministic TanStack Query Key Factory

Never hardcode arbitrary strings in `useQuery` or `invalidateQueries`. Use hierarchical query key factories:

```typescript
export const appointmentKeys = {
  all: ['appointments'] as const,
  lists: () => [...appointmentKeys.all, 'list'] as const,
  list: (filters: { patientId?: string; professionalId?: string; status?: string }) =>
    [...appointmentKeys.lists(), filters] as const,
  availability: (professionalId: string, date: string) =>
    [...appointmentKeys.all, 'availability', { professionalId, date }] as const,
  detail: (id: string) => [...appointmentKeys.all, 'detail', id] as const,
};
```

---

## 2. Optimistic Updates for Rescheduling & Cancellation

When a patient reschedules or cancels, provide instant UI feedback while guaranteeing rollback if the server rejects the action (e.g. race condition or lock failure):

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useCancelAppointment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ appointmentId, reason }: { appointmentId: string; reason: string }) => {
      const res = await fetch(`/api/appointments/${appointmentId}/cancel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      });
      if (!res.ok) throw new Error('Falha ao cancelar consulta.');
      return res.json();
    },
    onMutate: async ({ appointmentId }) => {
      // 1. Cancel in-flight refetches
      await queryClient.cancelQueries({ queryKey: appointmentKeys.detail(appointmentId) });

      // 2. Snapshot previous value
      const previousAppointment = queryClient.getQueryData(appointmentKeys.detail(appointmentId));

      // 3. Optimistically set cancelled status
      queryClient.setQueryData(appointmentKeys.detail(appointmentId), (old: any) => ({
        ...old,
        status: 'CANCELLED',
      }));

      return { previousAppointment };
    },
    onError: (_err, { appointmentId }, context) => {
      // 4. Rollback on failure
      if (context?.previousAppointment) {
        queryClient.setQueryData(appointmentKeys.detail(appointmentId), context.previousAppointment);
      }
    },
    onSettled: (_data, _error, { appointmentId }) => {
      // 5. Invalidate specific detail and lists to sync with server
      queryClient.invalidateQueries({ queryKey: appointmentKeys.detail(appointmentId) });
      queryClient.invalidateQueries({ queryKey: appointmentKeys.lists() });
    },
  });
}
```

---

## 3. Resilient Form Validation with Zod & React Hook Form

Always validate user input against a shared schema across both frontend forms and backend API routes.

```typescript
import { z } from 'zod';

export const bookingFormSchema = z.object({
  professionalId: z.string().uuid("Profissional inválido."),
  slotTimeUtc: z.string().datetime({ message: "Data/hora em formato UTC inválido." }),
  reasonForVisit: z.string().min(5, "Informe o motivo da consulta (mínimo 5 caracteres).").max(500),
  patientCpf: z.string().regex(/^\d{3}\.\d{3}\.\d{3}-\d{2}$|^\d{11}$/, "CPF inválido."),
  patientPhone: z.string().min(10, "Telefone para contato obrigatório."),
  termsAccepted: z.literal(true, {
    errorMap: () => ({ message: "É obrigatório aceitar os termos de telemedicina e consentimento LGPD." })
  }),
});

export type BookingFormData = z.infer<typeof bookingFormSchema>;
```

---

## 4. Payment & Webhook Idempotency (Pix / Stripe)

When accepting payments for consultations:
1. **Idempotency Key:** Generate a unique `idempotency_key = "book_${appointmentId}_${paymentAttempt}"` to prevent accidental double-charges on network retries.
2. **Webhook Signature Verification:** Always verify webhook signatures (e.g. `stripe.webhooks.constructEvent` or HMAC-SHA256 Pix signatures) before taking action.
3. **Idempotent Webhook Processing:**
   - Store processed webhook event IDs in an `inbox_events` table.
   - If an incoming event ID was already processed, immediately return `200 OK` and ignore.
   - Transition appointment to `CONFIRMED` only if current status is `SCHEDULED`.
