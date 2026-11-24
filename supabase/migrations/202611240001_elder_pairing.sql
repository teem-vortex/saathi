-- Elder creates a short-lived single-use code. Entering it connects the guardian.
create or replace function public.connect_elder(code text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  invite public.pairing_codes%rowtype;
  connected uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  select * into invite from public.pairing_codes
    where code_hash = encode(extensions.digest(lower(trim(code)), 'sha256'), 'hex')
      and used_at is null and expires_at > now() for update;
  if not found or invite.owner_id = auth.uid() then
    raise exception 'Invalid or expired code';
  end if;
  select id into connected from public.pairings
    where primary_id = invite.owner_id and guardian_id = auth.uid()
      and status in ('pending', 'accepted') for update;
  if connected is null then
    insert into public.pairings(primary_id, guardian_id, status)
      values (invite.owner_id, auth.uid(), 'accepted') returning id into connected;
  else
    update public.pairings set status = 'accepted' where id = connected;
  end if;
  update public.pairing_codes set used_at = now() where id = invite.id;
  return connected;
end $$;

create or replace function public.connected_elders()
returns table(pairing_id uuid, elder_email text, connected_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select p.id, u.email::text, p.created_at
  from public.pairings p
  join auth.users u on u.id = p.primary_id
  where p.guardian_id = auth.uid() and p.status = 'accepted'
  order by p.created_at desc;
$$;
revoke all on function public.connect_elder(text), public.connected_elders() from public, anon;
grant execute on function public.connect_elder(text), public.connected_elders() to authenticated;
