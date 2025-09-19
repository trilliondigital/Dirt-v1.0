# Dirt — Anonymous Dating Feedback for Men (MVP Whitepaper)

Dirt is a male-focused counterpart to Tea: an anonymous, community-moderated space for men to share and discover dating experiences, patterns, and safety signals. The MVP mirrors Tea’s successful flows with adaptations for men, privacy-by-default, and App Store compliance.

## 1) Product Vision
- Empower men to learn from collective dating experiences.
- Encourage constructive, pattern-based feedback (red/green flags) vs. personal attacks.
- Balance openness with strong moderation and safety.

## 2) Personas
- New-to-dating learner
- Returning dater seeking patterns
- Safety-conscious user (alerts and best practices)

## 3) MVP Features
- Feed: scroll posts with tags, media, upvotes, comments, saves.
- Create Post: text + optional image, tag chips (red/green flag, ghosting, etc.), anonymous by default.
- Topics: curated categories (Ghosting, Green Flags, First Dates, Safety Tips).
- Lookup (Lite): two-step wizard to explore public hints; strictly no doxxing.
- Notifications: likes, comments, follows, alerts.
- Settings: account, app preferences, support/legal, invite friends.
- Invite: share referral code to unlock perks.

## 4) UX Flows
- Feed → Post Detail → Like/Comment/Share/Save
- Feed/Search → Topics → Filtered feed
- Search → Lookup Wizard (Step 1 input → Step 2 summary; optional upsell)
- Settings → Invite Friends (copy/share)

## 5) Safety & Moderation
- Community Guidelines: no PII/doxxing, no hate/harassment, no minors, no threats.
- AI Moderation: pre- or post-insert screening; quarantine high-risk content.
- Human Review: admin queue, takedowns, bans.
- Reporting: user flags with progressive enforcement.
- Images: auto-blur by default, strip EXIF, signed URLs; sensitive-content warnings.

## 6) Privacy Principles
- Minimal PII; anonymous by default.
- Clear consent and transparency around lookups and community conduct.
- Data retention policy; owner deletion; logs for fraud/moderation only.
- Compliance: App Store policies; 18+ only.

## 7) Data Model (public)
- users (id, apple_id?, created_at, last_active, reputation_score, is_admin)
- reviews (id, user_id, flag_type enum [red|green], category text, tags text[], body text, media_url text, created_at)
- votes (user_id, review_id, value int [-1|0|1])
- reports (id, review_id, reporter_id, reason, status [open|closed], created_at)
- alerts (id, user_id, keywords text[], enabled bool)
All with RLS enabled.

## 8) Backend (Supabase)
- Auth: Sign in with Apple; authenticated for writes.
- Storage: `media` bucket; owners can delete; signed URLs or public read per policy.
- Edge Functions: moderation pipeline, analytics webhook, media cleanup on delete.
- Observability: Supabase logs; minimal analytics, no PII.

## 9) AI Moderation
- Text: toxicity, harassment, hate, sexual content, PII risk.
- Images: nudity/violence flags; auto-blur or block.
- Outcomes: allow, quarantine, block.

## 10) MVP vs Future
- MVP: Feed, Create Post, Topics, Lookup Lite, Notifications, Invite, Settings, basic moderation.
- Future: Premium lookup details, advanced filters, reputation system, DM/requests, on-device ML hints, analytics dashboard.

## 11) Launch Plan
- Local iPhone testing: verify SwiftUI flows and navigation.
- QA: posting, tags, media placeholder, details, topics, lookup steps, notifications, settings/invite.
- Moderation stubs: simulate quarantine; validate display states.
- TestFlight: closed beta via invites; collect feedback on clarity/safety.

## 12) Risks & Mitigations
- Abuse/Harassment → Strict policy + AI + human review; quick takedowns.
- Privacy incidents → Minimal PII, signed URLs, auto-blur, redaction controls.
- App Store rejection → Avoid background-check claims; emphasize education/community.

## 13) Design Tenets
- Privacy-first defaults.
- Clear, calm copy.
- Haptics and obvious affordances.

---
© Dirt. Proprietary & confidential.
