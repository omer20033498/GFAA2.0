-- Find a Grief Specialist: practitioner applications, directory, and (a
-- placeholder for) subscriptions. Apply in the Supabase SQL Editor (or
-- `supabase db push`) for the project referenced in .env before running the
-- app against this branch.
--
-- Stripe is NOT wired up yet (deliberately deferred — see CLAUDE.md). This
-- migration creates `subscriptions` and the visibility rule that depends on
-- it, so a listing genuinely cannot go live until a later branch adds real
-- payment — but no rows will ever land in `subscriptions` until then, so
-- the public directory stays empty. That's expected, not a bug.

create table if not exists public.practitioners (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text not null,
  profession text not null check (
    profession in ('psychologist', 'counsellor', 'psychotherapist', 'social_worker', 'grief_educator', 'other')
  ),
  qualifications text not null,
  expertise text,
  state text not null,
  location text not null,
  delivery_options text[] not null default '{}'
    check (delivery_options <@ array['face_to_face', 'online', 'phone']::text[])
    check (array_length(delivery_options, 1) > 0),
  website text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'suspended')),
  created_at timestamptz not null default now()
);

create index if not exists practitioners_status_idx on public.practitioners (status);

alter table public.practitioners enable row level security;

-- Placeholder for Stripe (deferred). RLS enabled, no policies at all —
-- fully locked down; the only access path is practitioner_has_active_subscription()
-- below. A later branch adds real INSERT/UPDATE from a webhook Edge Function.
-- Created here, before practitioner_has_active_subscription(), because
-- Postgres validates a LANGUAGE SQL function's body — including that
-- referenced tables exist — at CREATE FUNCTION time, unlike PL/pgSQL.
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  practitioner_id uuid not null unique references public.practitioners (id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  status text not null default 'inactive' check (status in ('inactive', 'active', 'past_due', 'canceled')),
  current_period_end timestamptz
);

alter table public.subscriptions enable row level security;

-- Whether a practitioner has an active subscription, without exposing the
-- `subscriptions` table (billing IDs) to every authenticated user just to
-- let them check a boolean. SECURITY DEFINER + no direct SELECT policy on
-- subscriptions means this is the only way to read that state at all.
create or replace function public.practitioner_has_active_subscription(p_practitioner_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.subscriptions
    where practitioner_id = p_practitioner_id and status = 'active'
  );
$$;

-- Publicly listed (approved + paid) practitioners are visible to everyone;
-- a practitioner also sees their own listing regardless of status (so they
-- know if it's pending/rejected/suspended); admins see everything.
create policy "View publicly-listed, own, or all as admin"
  on public.practitioners for select
  to authenticated
  using (
    (status = 'approved' and public.practitioner_has_active_subscription(id))
    or user_id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- No INSERT policy: applications are created only via the
-- handle_new_user() trigger below (SECURITY DEFINER, runs regardless of
-- RLS), never a direct client insert.

create policy "Practitioner can update their own listing, admin can update any"
  on public.practitioners for update
  using (
    user_id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  )
  with check (
    user_id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Forces `status` server-side: a practitioner editing their own listing
-- (name, phone, etc.) can never also sneak in an approval. Mirrors
-- profiles' prevent_role_self_escalation trigger (migration 0001).
create or replace function public.protect_practitioner_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status and not exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  ) then
    new.status := old.status;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_practitioner_status on public.practitioners;
create trigger trg_protect_practitioner_status
  before update on public.practitioners
  for each row execute function public.protect_practitioner_status();

-- When an admin approves a practitioner, promote their profiles.role so
-- `_AuthGate` routes them to the Practitioner Portal from then on. If a
-- previously-approved practitioner is later rejected/suspended, demote
-- them back to `user`.
create or replace function public.sync_practitioner_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    update public.profiles set role = 'practitioner' where id = new.user_id;
  elsif new.status is distinct from 'approved' and old.status = 'approved' then
    update public.profiles set role = 'user' where id = new.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_practitioner_role on public.practitioners;
create trigger trg_sync_practitioner_role
  after update on public.practitioners
  for each row execute function public.sync_practitioner_role();

-- Extends the existing sign-up trigger (migration 0002) to also create a
-- pending practitioner application when the client's sign-up metadata
-- indicates one (see PractitionerRepository.applyAsPractitioner) — done
-- this way, not via a direct client insert after signUp(), because a
-- freshly-created account has no active session yet (email confirmation is
-- required first in this project), so auth.uid() wouldn't resolve for a
-- separate authenticated insert call.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  is_practitioner_application boolean := coalesce(
    (new.raw_user_meta_data ->> 'practitioner_application')::boolean, false
  );
begin
  insert into public.profiles (id, email, role, display_name, full_name)
  values (
    new.id,
    new.email,
    'user',
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'full_name'
  )
  on conflict (id) do nothing;

  if is_practitioner_application then
    insert into public.practitioners (
      user_id, full_name, email, phone, profession, qualifications,
      expertise, state, location, delivery_options, website
    )
    values (
      new.id,
      new.raw_user_meta_data ->> 'full_name',
      new.email,
      new.raw_user_meta_data ->> 'phone',
      new.raw_user_meta_data ->> 'profession',
      new.raw_user_meta_data ->> 'qualifications',
      new.raw_user_meta_data ->> 'expertise',
      new.raw_user_meta_data ->> 'state',
      new.raw_user_meta_data ->> 'location',
      coalesce(
        (select array_agg(value) from jsonb_array_elements_text(new.raw_user_meta_data -> 'delivery_options')),
        '{}'
      ),
      new.raw_user_meta_data ->> 'website'
    );
  end if;

  return new;
end;
$$;
