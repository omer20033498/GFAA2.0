-- Lets admins delete a sent message (e.g. an accidental post). Apply in
-- the Supabase SQL Editor (or `supabase db push`) for the project
-- referenced in .env before running the app against this branch.
--
-- No extra cleanup needed here: user_messages.message_id already has
-- `on delete cascade` (see migration 0005), so deleting a daily_messages
-- row removes it from every user's saved/favourited state and feed in
-- the same statement.

create policy "Only admins can delete daily messages"
  on public.daily_messages for delete
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );
