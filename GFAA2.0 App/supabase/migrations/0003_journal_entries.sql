-- Private journal entries. Apply in the Supabase SQL Editor (or
-- `supabase db push`) for the project referenced in .env before running the
-- app against this branch.
--
-- Per CLAUDE.md: readable/writable only by the owning user, no exceptions —
-- including admin. There is deliberately no admin-bypass policy here.

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists journal_entries_user_id_created_at_idx
  on public.journal_entries (user_id, created_at desc);

alter table public.journal_entries enable row level security;

create policy "Users can view their own journal entries"
  on public.journal_entries for select
  using (auth.uid() = user_id);

create policy "Users can create their own journal entries"
  on public.journal_entries for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own journal entries"
  on public.journal_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own journal entries"
  on public.journal_entries for delete
  using (auth.uid() = user_id);

-- Required for the app's realtime journal list (JournalRepository.watchEntries)
-- to receive updates, not just the initial read.
alter publication supabase_realtime add table public.journal_entries;
