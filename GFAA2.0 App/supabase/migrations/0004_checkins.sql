-- Emotional check-ins (mood logging). Apply in the Supabase SQL Editor (or
-- `supabase db push`) for the project referenced in .env before running the
-- app against this branch.
--
-- Owner-only, same as journal_entries — no admin exception. No update
-- policy: check-ins are a point-in-time log, not edited after the fact
-- (the app only offers delete, for correcting a mis-tap).

create table if not exists public.checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mood text not null check (mood in ('struggling', 'low', 'okay', 'good', 'great')),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists checkins_user_id_created_at_idx
  on public.checkins (user_id, created_at desc);

alter table public.checkins enable row level security;

create policy "Users can view their own check-ins"
  on public.checkins for select
  using (auth.uid() = user_id);

create policy "Users can create their own check-ins"
  on public.checkins for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own check-ins"
  on public.checkins for delete
  using (auth.uid() = user_id);
