# Teleconsultation Video & WebRTC Architecture

This reference outlines architecture and resilient frontend patterns for teleconsultation video calls (WebRTC, Twilio Video, Daily.co, Agora, LiveKit).

---

## 1. Security & Token Lifecycle

1. **Short-Lived Ephemeral Tokens:**
   - Video room access tokens (JWTs) must have a short TTL (e.g., 30–60 minutes) and match the scheduled appointment window.
   - Tokens must be scoped specifically to `room_id = appointment_id` and restricted by user role.
2. **Dynamic Generation Endpoint:**
   - Client requests token via authenticated API: `GET /api/appointments/[id]/video-token`.
   - Backend verifies:
     - User is authenticated and is either the assigned doctor or patient.
     - Current time is within the allowed consultation window (e.g. up to 10 minutes prior to appointment start until scheduled end + grace period).
3. **Automatic Refresh / Reconnection:**
   - If consultation exceeds token duration, provide seamless background token refresh without disconnecting media tracks.

---

## 2. Pre-Flight Device & Hardware Diagnostics

Never throw a patient directly into a WebRTC room without a pre-flight device check. Most teleconsultation failures stem from missing browser permissions or wrong input devices.

### Pre-Flight Checklist:
1. **Permission Check:** Query `navigator.permissions.query({ name: 'camera' as any })` and `microphone`.
2. **Device Enumeration:** Query `navigator.mediaDevices.enumerateDevices()` to ensure active audioinput and videoinput exist.
3. **Local Stream Preview:** Acquire temporary stream via `navigator.mediaDevices.getUserMedia({ video: true, audio: true })` to display local camera preview and microphone volume meter.
4. **Bandwidth / Network Check:** Test WebRTC ICE candidate gathering or ping signaling server.

---

## 3. Video Room State Machine

Represent the teleconsultation room state explicitly in React state or finite state machine:

```typescript
export type VideoCallState =
  | 'DEVICE_CHECK'      // Testing mic/camera
  | 'WAITING_ROOM'      // Patient waiting for doctor to admit/join
  | 'CONNECTING'        // Establishing peer/SFU connection
  | 'CONNECTED'         // Active consultation
  | 'RECONNECTING'      // Transient network drop
  | 'FAILED'            // Fatal WebRTC error (ICE failure, forbidden)
  | 'COMPLETED';        // Consultation formally finished
```

### Virtual Waiting Room Pattern
- When the patient connects before the doctor, transition to `WAITING_ROOM`.
- Display reassuring status: "Aguardando o médico entrar na sala... Mantenha a câmera pronta."
- Doctor receives real-time notification (WebSocket or Server-Sent Events) that patient is waiting.
- When doctor joins, automatically transition both participants to `CONNECTING` -> `CONNECTED`.

---

## 4. Network Resilience & Fallbacks

1. **Simulcast & Quality Adaptation:** Enable video simulcast so clients with low mobile bandwidth drop to 360p/240p instead of freezing.
2. **Audio-Only Fallback:** If packet loss exceeds 25% or round-trip time (RTT) exceeds 500ms, offer an instant "Desativar vídeo e continuar apenas com áudio" button.
3. **Clean Teardown:** When leaving the room, explicitly stop all media tracks (`track.stop()`) and release hardware locks:
```typescript
export function releaseMediaStream(stream: MediaStream | null) {
  if (!stream) return;
  stream.getTracks().forEach((track) => {
    track.stop();
  });
}
```
