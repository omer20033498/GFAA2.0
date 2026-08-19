# Grief Support App — Project Context for Claude Code

Client: **Grief First Aid Australia (GFAA)**
A calming, cross-platform mobile app giving users a safe space to express
feelings, reflect on emotions, track wellbeing, and connect to grief support —
personal, community, and professional.

---

## My rules for building with AI

1. Plan first. Show me the plan and wait for my ok before you write any code.
2. Make the smallest change that works. Do not touch anything I did not ask about.
3. Fix the real cause, not the symptom. Then tell me what changed and why it is safe.
4. One task, one fresh copy (a git branch). Never pile new work on finished work.
5. If you are unsure, stop and ask me. Never guess. Never make things up.
6. Read my real files before you change them. Check facts, do not go from memory.
7. On a big choice I cannot undo, show me the options first, then your pick and why.

---

## Testing discipline

Automated coordinate-tap testing on the emulator is unreliable (stale UI
state, timing issues, false positives/negatives) and must not be treated as
verification that a feature works. For any feature involving user input or
multi-step flow (auth, onboarding, journaling, check-ins, community posting,
practitioner registration):

- Claude Code may use the emulator to sanity-check that a screen renders and
  the app doesn't crash.
- The **person** (not automated taps) must walk the real end-to-end flow
  before a feature branch is considered done — e.g. actually registering,
  confirming an email, logging in, answering onboarding questions, landing on
  the right screen.
- Do not report a flow as "working" based on automated taps alone. Say
  clearly what was verified by Claude Code vs. what still needs human
  verification.

---

## Tech stack

| Layer | Tool |
|---|---|
| Frontend | Flutter |
| Language | Dart |
| Backend / Database | Supabase (Postgres) |
| Auth | Supabase Auth (roles: `user`, `admin`, `practitioner`) |
| File storage | Supabase Storage |
| Realtime (community group) | Supabase Realtime |
| Push notifications | OneSignal |
| Payments | Stripe + Supabase Edge Function |
| State management | Riverpod |
| Dev environment | VS Code / Claude Code Desktop |
| Version control | GitHub |
| Package identifier | `au.org.grieffirstaid.gfaa` (Android + iOS, must match) |

Do not introduce a different backend, state-management library, or major
package without asking first (see Rule 7).

---

## User roles

Three roles, enforced via Supabase Auth + Postgres row-level security:

- **user** — grieving individual using the app's support features
- **admin** — GFAA staff; manages content, moderation, practitioner approvals
- **practitioner** — grief professional listed in the directory; has their own
  self-service portal, separate from the main user experience

Onboarding questions (below) are shown to `user` role only. Admin and
practitioner accounts skip straight to their respective dashboards after
email verification.

---

## Finalised features

**1. Onboarding & Authentication**
- Register/login with email verification, across the three roles above
- The login screen has a User/Practitioner toggle — it doesn't change how
  login itself works (routing after sign-in is always driven by the
  account's real `profiles.role`), it only changes where "Register" leads:
  the normal register form for User, the practitioner application form
  (finalised feature 8) for Practitioner
- Registration asks a required "preferred name" (shown anywhere the app
  displays the user's name) and an optional "full name" (records only)
- Forgot/reset password: user requests a reset link by email; opening it
  deep-links back into the app (custom URL scheme
  `au.org.grieffirstaid.gfaa://reset-password`) straight to a set-new-password
  screen, bypassing normal auth/role routing
- Users only, at first login, answer two multi-select questions (no separate
  category-selection step — the second question already covers loss context):
  - *"What kinds of support interest you?"* — safe space to share feelings,
    daily guidance, resources/practical tips, a friendly chat, joining a
    group, managing overwhelming emotions, referral to health services,
    learning more about grief, something else
  - *"What brings you to GFAA?"* — general grief help, loss of
    spouse/partner, loss of friend/family member, loss of parent, loss of
    child, loss during pregnancy, infertility/childlessness, loss of someone
    to suicide, caring for someone ageing

**2. Daily Messages**
- No AI. Admin sends messages directly to users.
- Users can save, favourite, and share messages.

**3. Journaling**
- Users write, edit, manage private journal entries.
- Row-level security: entries readable/writable only by their owner.

**4. Emotional Check-ins**
- Mood logging (e.g. emoji selection).
- Progress shown over time via charts/trends. No AI.

**5. Community Group**
- One single group only, admin-managed.
- Admin posts directly; users can reply/comment.
- Users can also post, but posts require manual admin approval before going live.
- Realtime updates via Supabase Realtime.

**6. Resources**
- Scope simplified by the client during build: a single "Resources" row on
  the user Home screen, opening the GFAA resources page
  (grieffirstaid.au/resources/) in an external browser — same pattern as
  the Training rows, not a browsable/filterable in-app list. No database
  table, no admin management, no Supabase Storage.

**7. Training**
- Three static rows: For Individuals, For Workplaces, For Instructors.
- Each: short description + "Learn more" button linking out to the GFAA website.

**8. Find a Grief Specialist**
- Searchable, filterable directory of approved + paying practitioners.
- Filters: state, location, profession, delivery service (face-to-face /
  online / telephone).
- Listing fields: full name, profession, qualifications, expertise
  (optional), state, location, delivery options, phone, email, website
  (optional).
- No in-app booking or messaging — users contact practitioners directly.
- Practitioners pay $10 AUD/month via Stripe to stay listed — **not yet
  wired up** (client's explicit call, to avoid new infra before they have a
  Stripe account). A listing cannot go live without an active subscription,
  enforced in Postgres (`practitioner_has_active_subscription()`), so the
  directory is genuinely empty until a follow-up branch adds real payment.
- Registration flow, as actually built: the login screen's Practitioner tab
  leads to an application form (not the normal register form) collecting
  full name, email, password, phone, profession, qualifications, optional
  expertise, state, location, delivery options, optional website.
  Submitting creates the auth account immediately (same confirmation email
  as normal registration — no separate "approved" email exists; the
  practitioner just checks back by logging in) and a `pending` practitioner
  application in one step, via the sign-up trigger reading the account's
  metadata (not a separate authenticated insert — there's no session yet at
  that point since email confirmation is required first). While
  pending/rejected/suspended, logging in shows a status screen instead of
  the normal user Home. Admin approving promotes `profiles.role` to
  `practitioner` server-side (a trigger, not a client-side profiles write —
  profiles UPDATE stays owner-only); rejecting/suspending demotes back to
  `user`. That promotion is deliberately allowed through the
  `prevent_role_self_escalation` guard (migration 0001) via a transaction-
  local `app.bypass_role_guard` flag the trigger sets right before its own
  write (migration 0010) — the guard still fully blocks a real client-side
  role change; it only lets this one trusted server-side trigger through.
  The login screen's User/Practitioner tabs also gate sign-in itself, not
  just post-login routing: an approved practitioner (`profiles.role ==
  'practitioner'`) is rejected with an inline message if they try the User
  tab, and an account with no practitioner application at all is rejected
  on the Practitioner tab — both cases sign the session back out rather
  than letting them in and routing them away.
  Practitioner Portal covers full self-service editing (name, phone,
  profession, qualifications, expertise, state, location, delivery
  options, website) plus a separate account-email change (Supabase's own
  confirm-by-link flow) and a Subscription section — currently a status
  placeholder plus disabled "Update payment details" / "Cancel
  subscription" buttons, since Stripe isn't wired up yet. Once Stripe
  lands, add: real subscription creation/webhook, and wire those two
  buttons to it.

**9. Admin Dashboard**
- Manage users, daily messages, resources, training content.
- Approve/reject/edit/remove/suspend practitioner listings; view
  active/inactive members, payment status, failed payments, export data.
- Community moderation: approve/reject user posts, manage the group.

**10. Push Notifications**
- OneSignal, triggered from a Supabase Edge Function on relevant events
  (new daily message, user post approved, subscription issue, etc.)

**Explicitly out of scope:** no AI-generated content anywhere in the app, no
clinical/therapy features, no in-app booking or messaging with practitioners,
no health/medication advice.

---

## Brand & design system

Source: GFAA Brand Style Guide (Dec 2025). Match this, don't default to
generic Material/iOS styling — the Figma prototype is a structural reference
only, not a visual spec to copy exactly. Keep the UI clean, calm, and
interactive.

**Colour palette** (muted, a little greyed — grief "can suck the colour from
life"; green is soothing/stress-reducing; the neon is a rare accent, never a
button colour):

| Name | Hex | Use |
|---|---|---|
| Off-white | `#F0F1EB` | Primary background |
| Cool white | `#F4F6FC` | Secondary background/cards |
| Sage green | `#A9C1A9` | Primary brand colour |
| Soft sage | `#DAE4D7` | Light fills/backgrounds |
| Deep green | `#355438` | Dark accent, headings on light bg |
| Near-black | `#192227` | Text ("Dark Grey Azure") |
| Neon yellow | `#E6FE54` | Rare accent only — highlight a word/moment, **never** UI buttons |

**Typography**
- **Perpetua** (serif) — headings, reflective/long-form text (journaling
  prompts, message content). Generously spaced, column-aligned where
  possible; feels soothing and unhurried.
- **Ordine** (Extra Light / Medium) — subheads, UI labels, section titles.
  Warm and open. Use Medium sparingly (short titles only — drop to Extra
  Light if a line wraps).
- **Helvetica** — small captions, bold caps for tiny labels (≤15pt).

**Tone**: warm, human, inclusive, trauma-informed. Never clinical. Copy and
UI microtext should feel like "practical care," not a medical app.

**Logo**: "Grief FIRST AID™" — standard stacked lockup or horizontal. Drop
the ™ symbol below 8pt.

---

## Data model (live in Supabase — keep this section in sync with the actual migration)

- `profiles` (id, role, email, display_name, full_name, onboarding_answers
  jsonb, created_at) — `display_name` is the required "preferred name" shown
  anywhere the app displays the user's name; `full_name` is optional,
  records-only, never shown in the UI. Both are populated at sign-up from
  auth metadata via the `handle_new_user` trigger.
- `daily_messages` (id, body, sent_by_admin_id, created_at)
- `user_messages` (id, user_id, message_id, saved, favourited, shared_at)
- `journal_entries` (id, user_id, body, created_at, updated_at) — RLS: owner-only
- `checkins` (id, user_id, mood, note, created_at)
- `community_posts` (id, author_id, author_display_name, body, status
  [pending/approved/rejected], created_at) — status is set server-side by a
  trigger based on the author's role, not by the client
- `community_comments` (id, post_id, author_id, author_display_name, body,
  created_at)
- `practitioners` (id, user_id, full_name, email, phone, profession
  [psychologist/counsellor/psychotherapist/social_worker/grief_educator/other],
  qualifications, expertise, state, location, delivery_options[]
  [face_to_face/online/phone], website, status
  [pending/approved/rejected/suspended], created_at) — status is set
  server-side (protect_practitioner_status trigger); approving/suspending
  syncs profiles.role via sync_practitioner_role trigger. Rows are created
  only via the sign-up trigger (handle_new_user reading sign-up metadata),
  never a direct client insert.
- `subscriptions` (id, practitioner_id, stripe_customer_id,
  stripe_subscription_id, status, current_period_end) — placeholder table,
  RLS enabled with **no policies at all** (fully locked down); visibility is
  only ever checked indirectly via `practitioner_has_active_subscription()`.
  Real rows only start appearing once Stripe is wired up in a later branch.

Resources (finalised feature 6) has no table — see that feature's note above.

If Claude Code changes the live schema, update this section in the same
commit — this file must always describe what's actually in the database.

---

## Conventions

- State management: **Riverpod** (confirmed — see `lib/features/*/application/`).
- Folder structure: feature-first (e.g. `lib/features/journal/`, `lib/features/community/`).
- One feature = one branch, per Rule 4. Do not stack unrelated work on a
  branch whose feature isn't finished and reviewed.
- Never loosen a Supabase row-level security policy without explicitly
  asking first (Rule 7 — this is the kind of change that's hard to undo safely).
- Payments and subscription status are the source of truth in Stripe;
  Supabase mirrors it via webhook, never the other way around.
- No AI/LLM calls anywhere in this app — this was an explicit client
  decision, not a cost-saving default. Don't reintroduce it "to improve" a
  feature without asking.
- When reporting progress, separate clearly what Claude Code verified itself
  vs. what still needs the person to verify by hand (see Testing discipline above).
