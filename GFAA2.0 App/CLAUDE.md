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
- "Continue with Google" on the login screen's **User tab only** (not
  Practitioner — Google can't supply profession/qualifications/etc., so
  that path stays email/password + the application form). One button
  covers both login and first-time sign-up, since Supabase creates the
  account automatically on first use. Requires a Google Cloud OAuth
  client + Supabase's Google provider to be configured (external
  account setup, not app code) before it actually works — reuses the
  same custom-URL-scheme redirect mechanism as password reset, just a
  different path (`au.org.grieffirstaid.gfaa://login-callback`), so no
  native platform config was needed beyond what password reset already
  registered.
- Every password field has a show/hide toggle (`core/widgets/password_field.dart`).
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
- `AdminHomeScreen` now opens with a stat-tile grid (total users, live
  practitioners, new users this week, check-ins this week, applications
  awaiting review, posts awaiting approval, open bug reports, pending/
  failed practitioner payments) above the existing menu rows — see
  `admin_dashboard_stats()` in the data model section below. The
  "awaiting"/"pending" tiles link straight into the review/moderation
  screens they describe — the payments one opens
  `PractitionerReviewScreen`'s Approved tab specifically (via a new
  `initialTab` constructor param), since that's where an approved-but-
  unpaid listing actually sits. Deliberately just plain counts, no
  charts — matches how the rest of the admin screens work (fetch +
  pull-to-refresh, no realtime).

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

**Colour palette** (updated 2026-08-19 — client flagged the original tones
as reading too cool/clinical; see `lib/core/theme/app_colors.dart` for the
canonical definitions and why `ColorScheme.fromSeed` was replaced with an
explicit `ColorScheme`. Green is soothing/stress-reducing; the neon is a
rare accent, never a button colour):

| Name | Hex | Use |
|---|---|---|
| Off-white | `#F3F6F0` | Primary background |
| Cool white | `#F7F7F2` | Secondary background/cards |
| Sage green | `#8FAF9A` | Secondary brand colour |
| Soft sage | `#DCE8D8` | Icon circles, selected states, light fills |
| Deep green | `#355C45` | Primary brand/action colour — buttons, headings, selected nav |
| Near-black | `#1F2923` | Main text |
| Secondary text | `#5F6962` | Muted text/icons — use this, not `nearBlack` at reduced opacity |
| Border | `#D8DED7` | Borders and dividers |
| Neon yellow | `#E6FE54` | Rare accent only — highlight a word/moment, **never** UI buttons |

Visual hierarchy, client's own framing: warm off-white background → very
subtle neutral cards → sage accents → deep green for important actions →
dark charcoal text. No gradients, shadows, bright/saturated colours, or a
new visual style — "quiet, warm, safe, natural, reassuring, human."

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

**Visual redesign, in progress (started 2026-08-19)**: the client is
supplying real mockups screen-by-screen (not all at once — "edit step by
step") to replace the earlier placeholder-styled screens. Done so far:
- **Navigation**: `user`-role accounts (not admin, not practitioner — see
  `UserShell` in `lib/features/home/presentation/`) now get a persistent
  bottom bar (Home / Check-in / Community / Profile) on *every* screen,
  client's explicit call ("Option B"). Home/Check-in/Community are real
  tabs, each with its own nested `Navigator` so pushing into e.g. Journal
  or Training from Home still shows a back arrow and keeps that tab's
  history (Instagram/WhatsApp-style) — only switching between the three
  main tabs has no back arrow. Profile isn't a fourth tab; it opens a
  slide-over drawer (`ProfileDrawer`) via `Scaffold.drawer`, per the
  reference design.
- **Profile drawer**: avatar circle + decorative leaf sprig, "Welcome
  back, {name}", a mountain/sun decorative footer, app version, and a Log
  Out button that replaces the old AppBar logout icon. All five menu rows
  are now wired to real screens (2026-08-19 follow-up):
  - **Profile & Account** (`profile_account_screen.dart`) — edit preferred
    name and email (reuses `AuthRepository.updateEmail`, same
    confirm-by-link flow as the practitioner portal) and password (reuses
    `AuthRepository.updatePassword` — works for any active session, not
    just a password-recovery one). A "Danger zone" section lets the user
    permanently delete their own account via `delete_own_account()`
    (migration 0013, SECURITY DEFINER — the client SDK has no self-delete
    method, that needs the service-role key). Every feature table
    references `auth.users` with `on delete cascade`, so this one call
    wipes the account and all of their data. **Irreversible** — test with
    a disposable account.
  - **About GFAA** and **Privacy Policy** — placeholder copy Claude Code
    drafted, clearly marked as draft in-app; GFAA can revise anytime.
  - **Terms of Use** — the client's own provided text (adapted from a
    template that said "Griefity" throughout — replaced with "GFAA" for
    consistency; flag if that wasn't intended).
  - **Report a Bug** — a modal sheet (not a full screen), posts to a new
    `bug_reports` table rather than a `mailto:` link — Claude Code's
    recommendation when asked, since it doesn't depend on the device
    having a mail client configured, gives admin a persistent/auditable
    queue, and matches every other admin workflow in this app (fetch +
    review screen) rather than being the one feature that works
    differently. Surfaced in `AdminHomeScreen` as both a stat tile ("Open
    bug reports") and a menu row, linking to `BugReportsScreen`
    (mark-resolved, no delete — resolved reports just stop counting as
    open).
- **Home**: greeting ("Good morning, {name}") + today's-message preview +
  a 2×2 grid of feature cards (Journal, Resources, Training, Find a
  Specialist). Check-ins and Community were removed from the grid per
  client follow-up (2026-08-19) — both already live on the bottom bar, so
  a grid entry was redundant; the grid now only covers what's *not* a
  bottom-bar tab.
- **Login/Register**: pill-shaped fields with leading icons, a headline
  with one word underlined in the brand's rare neon-yellow accent,
  "Continue with Google" (with a hand-drawn approximation of Google's
  four-colour "G" — no real asset pipeline for third-party logos exists
  yet), decorative leaf sprigs in the bottom corners. The reference design
  didn't show the User/Practitioner audience toggle or the required
  preferred-name field — both are functionally necessary (see finalised
  features 1 and 8) so they were kept, just restyled to match.
- Decorative illustrations (leaf branches, the mountain/sun motif) are
  hand-drawn via `CustomPainter` (`lib/core/widgets/leaf_branch.dart`,
  `mountain_footer.dart`) rather than image assets, since no vector
  illustration export exists — approximate the reference's *feel*, not a
  pixel-exact match.
- **Not yet redesigned**: Check-ins, Community, Journal, Daily Messages,
  Find a Specialist, Training, and both admin/practitioner-portal screens
  still use the earlier placeholder styling. Update this section as each
  lands.

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

- `bug_reports` (id, user_id, email, body, status [open/resolved],
  created_at) — owner can insert only (no owner select — this is a
  one-way "send to GFAA", not a "my reports" list); admin can select/update
  all. See finalised feature 1's Profile drawer note above for why this
  exists instead of a `mailto:` link.
- `admin_dashboard_stats()` — SECURITY DEFINER Postgres function (not a
  table), admin-only, returns aggregate counts only (total users, live
  practitioners, pending applications, pending posts, new users this week,
  check-ins this week, open bug reports, pending/failed practitioner
  payments) for the Admin Dashboard's stat tiles. Exists because
  `profiles` and `checkins` SELECT are both owner-only with no admin
  exception — this reads past that safely by returning only numbers,
  never row content, rather than adding a general admin-read policy on
  either table. "Pending/failed payments" is `status = 'approved' and
  not practitioner_has_active_subscription(id)` — the exact complement of
  "live practitioners" (`approved and` that same check) — will just equal
  every approved practitioner until Stripe is wired up, since none of
  them can be paid yet; that's expected, not a bug.
- `delete_own_account()` — SECURITY DEFINER Postgres function, deletes the
  caller's own `auth.users` row (and, via cascade, everything else tied to
  it). See finalised feature 1's Profile drawer note above.

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
