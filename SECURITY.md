# Security Policy

- Report vulnerabilities privately via email or issue with `security` label (no PoC details publicly).
- Never commit secrets; use `backend/config/.env.local.example` as reference.
- RLS must remain enabled on all public tables; migrations that alter policies require review.
- Images are served via signed URLs; ensure expiry and least-privilege policies.
