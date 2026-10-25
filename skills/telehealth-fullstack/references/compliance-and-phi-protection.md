# Compliance, Security & PHI Protection Architecture

This reference defines compliance guidelines (LGPD, HIPAA, CFM Telemedicine Resolution) for safeguarding Protected Health Information (PHI / Dados Sensíveis de Saúde).

---

## 1. Zero PHI in Logs & Monitoring (Mandatory)

Under LGPD (Art. 5, II and Art. 11) and HIPAA Security Rule, logging patient identifiers or clinical health information in plain text constitutes a severe regulatory violation.

### Prohibited in Logs:
- Full CPF, RG, CNS (Cartão Nacional de Saúde).
- Patient full names, dates of birth, home addresses, phone numbers.
- Medical notes, diagnoses (CID-10 / CID-11), prescriptions, examination results.
- Authentication JWTs, session tokens, passwords.

### Masking Utilities (TypeScript)
```typescript
export function maskCpf(cpf: string): string {
  const clean = cpf.replace(/\D/g, '');
  if (clean.length !== 11) return '***.***.***-**';
  return `${clean.slice(0, 3)}.***.***-${clean.slice(9, 11)}`;
}

export function maskEmail(email: string): string {
  const [user, domain] = email.split('@');
  if (!user || !domain) return '***@***.***';
  const visible = user.slice(0, 2);
  return `${visible}***@${domain}`;
}

export function maskPhone(phone: string): string {
  const clean = phone.replace(/\D/g, '');
  if (clean.length < 10) return '(**) *****-****';
  return `(${clean.slice(0, 2)}) *****-${clean.slice(-4)}`;
}
```

### Logging Sanitizer Interceptor (Pino / Winston / Sentry)
Always sanitize log context objects before writing:
```typescript
const SENSITIVE_KEYS = new Set([
  'cpf', 'rg', 'cns', 'password', 'token', 'authorization',
  'diagnosis', 'prontuario', 'prescription', 'notes', 'anamnese'
]);

export function sanitizeLogData(data: Record<string, any>): Record<string, any> {
  const sanitized: Record<string, any> = {};
  for (const [key, val] of Object.entries(data)) {
    if (SENSITIVE_KEYS.has(key.toLowerCase())) {
      sanitized[key] = '[REDACTED_PHI]';
    } else if (typeof val === 'object' && val !== null) {
      sanitized[key] = sanitizeLogData(val);
    } else {
      sanitized[key] = val;
    }
  }
  return sanitized;
}
```

---

## 2. Role-Based Access Control (RBAC) & Ownership Boundaries

### Core Roles
1. `PACIENTE`: Accesses ONLY their own appointments, prescriptions, and personal profile.
2. `PROFISSIONAL`: Accesses appointments assigned to them, and medical records of patients they have an active care relationship with.
3. `RECEPCAO` / `ATENDENTE`: Manages appointment slots, check-in status, and professional availability. **NO ACCESS** to clinical consultation notes or diagnostic summaries.
4. `ADMIN`: Manages clinic settings, professionals, financial reporting, and audit logs. No direct medical record viewing without logged clinical justification.

### Multi-Tenant & Ownership Verification Middleware
Never trust user-supplied IDs from URL parameters or request bodies:
```typescript
// Next.js Route Handler / Middleware pattern
export async function verifyAppointmentAccess(userId: string, userRole: string, appointmentId: string) {
  const appointment = await db.appointment.findUnique({
    where: { id: appointmentId },
    select: { patientId: true, professionalId: true }
  });

  if (!appointment) throw new NotFoundError("Agendamento não encontrado.");

  if (userRole === 'PACIENTE' && appointment.patientId !== userId) {
    throw new ForbiddenError("Acesso negado: agendamento pertence a outro paciente.");
  }

  if (userRole === 'PROFISSIONAL' && appointment.professionalId !== userId) {
    throw new ForbiddenError("Acesso negado: agendamento pertence a outro profissional.");
  }

  return appointment;
}
```

---

## 3. Electronic Health Record (PEP) Immutability & Audit Trails

In accordance with CFM Resolution 2.314/2022 (Telemedicine) and CFM 1.821/2007 (Electronic Medical Records):
1. **Clinical Notes Immutability:** Once signed or completed, an anamnesis or clinical entry cannot be overwritten or deleted. Any modification must be saved as an addendum (`Adendo`) with its own timestamp and author.
2. **Access Audit Log:** Every view, export, print, or edit of patient health records must append an immutable entry to an audit table:

```sql
CREATE TABLE medical_record_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID NOT NULL REFERENCES medical_records(id),
  actor_user_id UUID NOT NULL,
  actor_role VARCHAR(50) NOT NULL,
  action_type VARCHAR(50) NOT NULL, -- 'VIEW', 'CREATE_ADDENDUM', 'EXPORT_PDF', 'SIGN'
  ip_address VARCHAR(45),
  user_agent TEXT,
  accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```
