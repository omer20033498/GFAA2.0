-- Lets admins remove a practitioner listing entirely (as distinct from
-- suspending it, which keeps the record but hides it). Apply in the
-- Supabase SQL Editor (or `supabase db push`) for the project referenced
-- in .env before running the app against this branch.

create policy "Only admins can delete practitioner listings"
  on public.practitioners for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
