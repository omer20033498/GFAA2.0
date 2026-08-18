-- Daily messages (admin broadcast) + per-user save/favourite/share state.
-- Apply in the Supabase SQL Editor (or `supabase db push`) for the project
-- referenced in .env before running the app against this branch.

create table if not exists public.daily_messages (
  id uuid primary key default gen_random_uuid(),
  body text not null,
  sent_by_admin_id uuid not null references auth.users (id),
  created_at timestamptz not null default now()
);

create index if not exists daily_messages_created_at_idx
  on public.daily_messages (created_at desc);

alter table public.daily_messages enable row level security;

-- Every signed-in user reads the same broadcast feed — this isn't private
-- data, so there's no owner restriction on select.
create policy "Any authenticated user can view daily messages"
  on public.daily_messages for select
  to authenticated
  using (true);

-- Only admins can send. Checks the caller's own profile row, which the
-- existing "Users can view their own profile" policy (see migration 0001)
-- already permits them to read.
create policy "Only admins can send daily messages"
  on public.daily_messages for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Per-user save/favourite/share state for a message. Created lazily on
-- first interaction (see MessageRepository.setMessageState), not fanned
-- out to every user the moment a message is sent.
create table if not exists public.user_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  message_id uuid not null references public.daily_messages (id) on delete cascade,
  saved boolean not null default false,
  favourited boolean not null default false,
  shared_at timestamptz,
  unique (user_id, message_id)
);

alter table public.user_messages enable row level security;

create policy "Users can view their own message state"
  on public.user_messages for select
  using (auth.uid() = user_id);

create policy "Users can create their own message state"
  on public.user_messages for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own message state"
  on public.user_messages for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
