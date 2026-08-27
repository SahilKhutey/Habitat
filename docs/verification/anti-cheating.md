# Anti-Cheat & Sensor Authenticity Heuristics

## 1. Anti-Cheat Principle
A discipline platform that permits effortless cheating (such as snapping black photos under blankets, selecting photos from the device gallery, or re-uploading yesterday's video) immediately breaks its behavioral pact with the user.

---

## 2. Implemented Defense Gates

### Gate 1: Hardware Capture Freshness
* **Rule**: Timestamp of captured media must be within 180 seconds of submission.
* **Failure Code**: `PROOF_EXPIRED`
* **Feedback**: *"Proof capture is stale. Live action required."*

### Gate 2: Ambient Lux Illumination
* **Rule**: Optical ambient lux measurement must meet or exceed task threshold ($\ge 25\text{ lux}$).
* **Failure Code**: `TOO_DARK`
* **Feedback**: *"Scene illumination too dark. Turn on room lighting or step outside."*

### Gate 3: Optical Entropy & Lens Occlusion
* **Rule**: Scene spatial entropy must exceed $0.15$.
* **Defense**: Detects solid black frames resulting from covered lenses (fingers, tape, blankets).
* **Failure Code**: `LENS_COVERED`
* **Feedback**: *"Camera lens appears covered or obscured."*

### Gate 4: Live Viewfinder Sensor Enforcement
* **Rule**: Direct camera sensor hardware stream only; system gallery file picker is disabled.
* **Failure Code**: `GALLERY_PROHIBITED`
* **Feedback**: *"Gallery uploads are prohibited. Live camera capture required."*

### Gate 5: Replay & Cross-User Protection
* Proofs are tied to `{userId, missionId, attemptId}`. A proof generated for User A or Mission 1 cannot be submitted for User B or Mission 2.
