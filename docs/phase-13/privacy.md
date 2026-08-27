# Health Privacy, Consent & Granular Data Deletion

## 1. Privacy Principles & Non-Clinical Framing

* **Non-Clinical Framing**: Habitat never claims medical or diagnostic authority. All insights are framed as personal goal progress and observed behavioral associations.
* **Granular Consent**: Users explicitly authorize health providers and categories (`exercise`, `steps`, `sleep`, `heartRate`).

---

## 2. Granular Data Deletion Endpoints

Users can independently delete sensitive health categories without deleting their discipline account, XP history, or streak tokens:

* `DELETE /api/v1/health/data/exercise`
* `DELETE /api/v1/health/data/hydration`
* `DELETE /api/v1/health/data/sleep`
* `POST /api/v1/health/providers/disconnect`
