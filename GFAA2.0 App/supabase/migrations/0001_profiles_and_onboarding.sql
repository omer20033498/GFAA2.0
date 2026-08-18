-- Profiles table + auto-provisioning + row-level security.
-- Apply this in the Supabase SQL Editor (or `supabase db push`) for the
-- project referenced in .env before running the app.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'user' check (role in ('user', 'admin', 'practitioner')),
  email text,
  display_name text,
  onboarding_answers jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Prevents an end user from granting themselves admin/practitioner via a
-- normal client update. Only service-role callers (e.g. a future admin
-- Edge Function) can change `role`; ordinary "authenticated" updates have
-- their role silently reverted. Extend this when the Admin Dashboard
-- feature needs to let admins change other users' roles.
create or replace function public.prevent_role_self_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and auth.role() = 'authenticated' then
    new.role := old.role;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_role_self_escalation on public.profiles;
create trigger trg_prevent_role_self_escalation
  before update on public.profiles
  for each row execute function public.prevent_role_self_escalation();

-- Every new auth.users row gets a matching profile, defaulting to role
-- 'user'. Admin/practitioner accounts are elevated later by an admin
-- (practitioners specifically via the application/approval flow in
-- CLAUDE.md finalised feature 8), never at self-signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_handle_new_user on auth.users;
create trigger trg_handle_new_user
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Required for the app's realtime profile stream (used to detect e.g. when
-- onboarding_answers is saved) to receive updates, not just the initial read.
alter publication supabase_realtime add table public.profiles;
