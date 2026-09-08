# Grief First Aid Australia (GFAA) — App

> **Before you do anything else:** all feature work lives at the current tip
> of `feature/admin-dashboard`, not on `main`. The branches in this repo were
> used as sequential checkpoints rather than merged back into `main`, so if
> `main` has not been fast-forwarded to the latest work by the time you clone
> this, checking out `main` will give you an empty Flutter scaffold with none
> of the app's features. Check out the branch (or tag) your handover contact
> points you to, and confirm it's not `main` before assuming something is
> missing.

## Prerequisites

- **Flutter 3.44.9** (stable channel)
- **Dart 3.12.2** (bundled with the above Flutter version — you don't install
  this separately)

Newer Flutter/Dart versions will very likely work too, but the above is what
this app was built and last verified against.

## Clean-clone setup

```bash
git clone <this-repo-url>
cd "GFAA2.0 App"
flutter pub get
```

## Supabase setup

1. Create a new Supabase project.
2. Apply the 14 migrations in `supabase/migrations/`, **in numbered order,
   0001 through 0014** — either with `supabase db push`, or by pasting each
   file into the SQL Editor one at a time in order. The numbering is a real
   dependency order (later migrations reference functions and tables that
   earlier ones create), so don't skip around.

   **The migrations are not safely re-runnable.** Together they contain 36
   `create policy` statements, and PostgreSQL has no `IF NOT EXISTS` form for
   row-level security policies. If a migration fails partway through, do not
   just re-run it — every `create policy` it already got past will error with
   "policy already exists" on a second attempt. Instead, check what actually
   applied (`\d+ <table>` in `psql`, or the Policies tab in the dashboard),
   manually clean up anything left half-applied, and re-run only from that
   point.

## Dashboard configuration — not in this repository

Everything schema-, RLS-, and trigger-related lives in the migrations above.
The following does **not** live in this repo and has to be set up by hand in
the Supabase dashboard for a new project:

- **Auth email templates** (confirmation email, password-reset email) —
  Authentication → Email Templates. Supabase's defaults will technically
  work but won't carry GFAA branding.
- **Redirect URL allow-list** — Authentication → URL Configuration. Must
  explicitly include both:
  - `au.org.grieffirstaid.gfaa://reset-password`
  - `au.org.grieffirstaid.gfaa://login-callback`

  Both are hardcoded in the app (`lib/features/auth/data/auth_repository.dart`)
  and the app assumes the dashboard already allows them — sign-in and
  password reset will silently fail to redirect correctly if they're missing.
- **Google OAuth provider** — Authentication → Providers → Google. This
  needs a separate Google Cloud OAuth client (its own project in Google
  Cloud Console, with a configured consent screen and redirect URI) — that
  client ID/secret is what you paste into the Supabase provider settings.
  This is entirely outside Supabase and outside this repo.
- **Project "Site URL"** — Authentication → URL Configuration. Not
  referenced anywhere in the app code, so its correct value for a new
  project has to be set sensibly by hand rather than copied from anything
  here.

## Environment variables

Copy the template and fill in your new project's real values:

```bash
cp .env.example .env
```

Then edit `.env` and set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the values
from your Supabase project's Settings → API page. `.env` is gitignored and
must never be committed.

## Running and building

```bash
# Run on a connected device/emulator, or a chosen target
flutter run

# Android release build (see "Not yet configured" below before distributing it)
flutter build apk

# iOS release build (requires a Mac with Xcode)
flutter build ios
```

## Not yet configured

- **Release signing** — the Android release build type still signs with the
  shared, publicly-known Flutter **debug keystore**
  (`android/app/build.gradle.kts`). A `flutter build apk --release` today
  produces an APK that is **not distributable** to the Play Store or anyone
  outside development. A real upload keystore needs to be generated and
  wired in before any release build is shipped.
- **Stripe** — the practitioner subscription flow ($10/month to stay listed)
  is fully designed and enforced in the database (`subscriptions` table,
  `practitioner_has_active_subscription()`), but no Stripe integration or
  webhook exists yet. Every practitioner listing will stay invisible in the
  public directory until this is wired up.
- **OneSignal** — push notifications are planned but not implemented; no
  OneSignal package or Edge Function exists in this codebase yet.
- **Supabase Storage** — no Storage buckets are used anywhere in the app
  (no file/image upload features exist yet).
- **Edge Functions** — none exist in this repository.
