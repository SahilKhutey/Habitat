# Security & Anti-Cheat Protocols (`docs/security`)

## Anti-Cheat Verification Pipeline
1. **Freshness Verification**: Rejects proof media captured $> 3\text{ minutes}$ prior to submission.
2. **Illumination Verification**: Rejects dark photos $< 30\text{ lux}$ to prevent fake under-blanket submissions.
3. **Motion Vector & Duration Verification**: Requires minimum video durations ($\ge 10\text{s}$) with active accelerometer motion.
4. **Presigned Object Storage**: S3 uploads use short-lived presigned URLs directly targeting MinIO/S3.
5. **Never Trust the Client**: Server authoritatively evaluates and enforces state transitions.
