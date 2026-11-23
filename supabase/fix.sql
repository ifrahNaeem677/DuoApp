-- =====================================================================
-- DuoDeen V2 — small OPTIONAL fixes for your EXISTING tables.
-- Does NOT create or delete any table. Safe to run more than once.
-- Supabase → SQL Editor → New query → paste → Run.
-- =====================================================================

-- 1) Column for the Tasbeeh counter
alter table public.daily_entries
  add column if not exists tasbeeh_count int not null default 0;

-- 2) Turn on Realtime so your friend's ticks appear on your phone in 1–2 s
do $$
begin
  begin
    alter publication supabase_realtime add table public.daily_entries;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.profiles;
  exception when duplicate_object then null;
  end;
end $$;

-- 3) Safe pairing. Your security rules (correctly) stop the app from
--    reading or editing a stranger's profile, so pairing runs here on
--    the server instead. The app uses these automatically if they exist.
create or replace function public.pair_with_code(code text)
returns json language plpgsql security definer set search_path = public as $$
declare
  me_id    uuid := auth.uid();
  mine     public.profiles;
  friend   public.profiles;
  new_pair uuid;
begin
  if me_id is null then raise exception 'Please log in again.'; end if;

  select * into mine from public.profiles where id = me_id;
  if mine.pair_id is not null then
    raise exception 'You are already paired. Unpair first.';
  end if;

  select * into friend from public.profiles where pair_code = upper(trim(code));
  if friend.id is null then raise exception 'Invalid Code'; end if;
  if friend.id = me_id then raise exception 'That is your own code'; end if;
  if friend.pair_id is not null then
    raise exception 'Your friend is already paired with someone else.';
  end if;

  insert into public.pairs (user1_id, user2_id) values (me_id, friend.id)
  returning id into new_pair;

  update public.profiles set pair_id = new_pair where id in (me_id, friend.id);

  update public.daily_entries set pair_id = new_pair
  where user_id in (me_id, friend.id) and date >= current_date - 1;

  return json_build_object('pair_id', new_pair, 'partner_name', friend.name);
end $$;

create or replace function public.unpair()
returns void language plpgsql security definer set search_path = public as $$
declare
  pid uuid;
begin
  select pair_id into pid from public.profiles where id = auth.uid();
  if pid is null then return; end if;
  update public.pairs set status = 'ended' where id = pid;
  update public.profiles set pair_id = null where pair_id = pid;
end $$;

grant execute on function public.pair_with_code(text) to authenticated;
grant execute on function public.unpair() to authenticated;
