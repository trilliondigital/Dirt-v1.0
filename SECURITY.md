# Security Policy

- Report vulnerabilities privately via email or issue with `security` label (no PoC details publicly).
- Never commit secrets; use `backend/config/.env.local.example` as reference.
- RLS must remain enabled on all public tables; migrations that alter policies require review.
- Images are served via signed URLs; ensure expiry and least-privilege policies.

## App Moderation
- In-app reports collect a reason from a controlled list (`ReportReason`) and are sent via `ReportService`.
- Locally, reported posts are soft-hidden immediately for the reporter; a `ModerationQueue` applies an auto-hide threshold stub for UI-only behavior. Replace with server-side policy.
- Reasons and identifiers are logged for debugging in development builds only; remove logs in production.

## Client-side Protections
- EXIF stripping: images selected for posts have EXIF removed client-side (stubbed utility) prior to upload.
- Media privacy: images are blurred by default in Feed/Post until the user taps to reveal.
- Content validation: Create Post enforces max 500 characters and requires selecting Red/Green; tags must come from the controlled list.

## Responsible Disclosure
- Please provide a clear description, impacted components, and reproduction steps.
- Do not test on production users. Use test accounts and non-destructive methods.
