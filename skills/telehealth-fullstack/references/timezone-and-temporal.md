# Timezone & Temporal Safety Architecture

This reference outlines strict rules for date, time, and timezone handling in Telehealth platforms to prevent scheduling drift and cross-timezone miscommunications.

---

## 1. Golden Rules of Temporal Safety

1. **Storage Rule:** All timestamps stored in databases (PostgreSQL, MySQL, MongoDB) MUST be UTC (`TIMESTAMP WITH TIME ZONE` or ISO 8601 UTC string: `YYYY-MM-DDTHH:mm:ss.sssZ`).
2. **API Contract Rule:** All JSON payloads sent across HTTP endpoints, Server Actions, or WebSockets MUST transmit timestamps in ISO 8601 UTC (`2026-10-25T21:30:00.000Z`).
3. **Presentation Rule:** Never format or localize a timestamp on the server unless the target recipient's specific IANA timezone (e.g. `America/Sao_Paulo`, `America/Manaus`) is explicitly passed and verified.
4. **Client-Side Rendering Rule:** Prefer formatting dates on the client using the browser's resolved timezone or the clinic's standard timezone to prevent Next.js SSR hydration mismatches.

---

## 2. Cross-Timezone Consultations

In telehealth, the healthcare professional and the patient often reside in different time zones:
- Example: Doctor in São Paulo (`America/Sao_Paulo`, UTC-3), Patient in Manaus (`America/Manaus`, UTC-4).
- If the appointment is booked for 14:00 Brasília time:
  - Canonical UTC: `17:00:00Z`.
  - Doctor UI displays: `14:00 (Horário de Brasília)`.
  - Patient UI displays: `13:00 (Horário do Amazonas)`.

### Email & Notification Template Pattern
Whenever emitting SMS, WhatsApp, or Email reminders, explicitly state the timezone name to eliminate patient confusion:
> "Sua consulta está confirmada para **25/10/2026 às 14:00 (Horário de Brasília)**."

---

## 3. Recommended Code Patterns (TypeScript)

### Using `date-fns-tz`
```typescript
import { formatInTimeZone, zonedTimeToUtc, utcToZonedTime } from 'date-fns-tz';

const CLINIC_TIMEZONE = 'America/Sao_Paulo';

// Converting local input (e.g. datepicker "2026-10-25" and time "14:00") to UTC for API
export function createUtcAppointment(dateStr: string, timeStr: string, timeZone = CLINIC_TIMEZONE): Date {
  const localDateTimeStr = `${dateStr}T${timeStr}:00`;
  return zonedTimeToUtc(localDateTimeStr, timeZone);
}

// Formatting UTC date for UI display in target timezone
export function formatAppointmentForUser(utcDate: Date | string, timeZone = CLINIC_TIMEZONE): string {
  return formatInTimeZone(new Date(utcDate), timeZone, 'dd/MM/yyyy HH:mm (zzz)');
}
```

### Avoiding Next.js SSR Hydration Mismatches
When rendering localized times in Next.js Server Components, the server (running in UTC in Docker/Vercel) and the client (running in user's browser local time) will produce different strings, causing a hydration error.

**Solution: Dedicated Time Formatter Component with Mounted Guard:**
```tsx
'use client';
import { useEffect, useState } from 'react';
import { formatInTimeZone } from 'date-fns-tz';

interface LocalTimeProps {
  isoUtcString: string;
  formatStr?: string;
  timeZone?: string;
}

export function LocalizedTime({ isoUtcString, formatStr = 'dd/MM/yyyy HH:mm', timeZone }: LocalTimeProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    // Render static fallback or server-safe UTC presentation
    return <span className="opacity-0">--:--</span>;
  }

  const resolvedTz = timeZone || Intl.DateTimeFormat().resolvedOptions().timeZone;
  const formatted = formatInTimeZone(new Date(isoUtcString), resolvedTz, formatStr);

  return <time dateTime={isoUtcString}>{formatted}</time>;
}
```

---

## 4. Date Manipulation Anti-Patterns to Avoid

| Anti-Pattern | Why it Fails | Safe Alternative |
| :--- | :--- | :--- |
| `new Date("2026-10-25")` | Parsed as UTC midnight in some JS runtimes and local midnight in others, shifting the day backward | Use explicit ISO string with time: `"2026-10-25T00:00:00Z"` or parse with `parseISO` |
| `date.setHours(date.getHours() + 3)` | Breaks across Daylight Saving Time boundaries and month roll-overs | Use `addHours(date, 3)` from `date-fns` |
| Storing local date without timezone offset | Unusable across multi-region clinics | Always store UTC timestamp |
