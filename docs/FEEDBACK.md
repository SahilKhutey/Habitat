# Offline Feedback & Diagnostic Collection System

## Feedback Model
Testers can submit feedback entirely offline. Records are stored in the local SQLite `feedback` table:
- **Type:** `Bug`, `Suggestion`, `Task Idea`, `UI/UX`, `Alarm Problem`, `Camera Problem`, `Other`
- **Rating:** 1 to 5 Stars
- **Title & Description:** Detailed user observations
- **Screenshot Path:** Optional attached local media

## Sharing & Diagnostics
Testers can export their feedback and diagnostic reports:
1. Tap **Settings $\to$ Export Feedback**.
2. A structured JSON report (`discipline-feedback-YYYY-MM-DD.json`) is generated.
3. The native OS share sheet opens (sharing via WhatsApp, Email, Drive, AirDrop, etc.).
