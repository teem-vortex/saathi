-- Saathi pairing and messages. All writes go through authenticated functions.
create extension if not exists pgcrypto with schema extensions;

create table public.pairing_codes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  code_hash text not null unique,
  expires_at timestamptz not null,
  used_at timestamptz
);
create table public.pairings (
  id uuid primary key default gen_random_uuid(),
  primary_id uuid not null references auth.users(id) on delete cascade,
  guardian_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'revoked')),
  created_at timestamptz not null default now(),
  check (primary_id <> guardian_id)
);
create unique index pairings_one_active_pair on public.pairings(primary_id, guardian_id)
  where status in ('pending', 'accepted');
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  pairing_id uuid not null references public.pairings(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create table public.push_tokens (
  token text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  updated_at timestamptz not null default now()
);
alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;
alter table public.pairing_codes enable row level security;
alter table public.pairings enable row level security;
alter table public.messages enable row level security;
revoke all on public.pairing_codes, public.pairings, public.messages from anon, authenticated;
grant select on public.pairings, public.messages to authenticated;
create policy pairings_read on public.pairings for select to authenticated
  using (auth.uid() in (primary_id, guardian_id));
create policy messages_read on public.messages for select to authenticated
  using (exists (select 1 from public.pairings p where p.id = pairing_id
    and p.status = 'accepted' and auth.uid() in (p.primary_id, p.guardian_id)));

-- A cryptographically random 128-bit code is shown only to its creator.
create function public.create_pairing_code() returns text language plpgsql security definer
set search_path = '' as $$
declare code text;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  update public.pairing_codes set used_at = now() where owner_id = auth.uid() and used_at is null;
  code := encode(extensions.gen_random_bytes(16), 'hex');
  insert into public.pairing_codes(owner_id, code_hash, expires_at)
    values (auth.uid(), encode(extensions.digest(code, 'sha256'), 'hex'), now() + interval '10 minutes');
  return code;
end $$;

create function public.request_pairing(code text) returns uuid language plpgsql security definer
set search_path = '' as $$
declare invite public.pairing_codes%rowtype; pairing uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  select * into invite from public.pairing_codes
    where code_hash = encode(extensions.digest(lower(trim(code)), 'sha256'), 'hex')
      and used_at is null and expires_at > now() for update;
  if not found or invite.owner_id = auth.uid() then raise exception 'Invalid or expired code'; end if;
  insert into public.pairings(primary_id, guardian_id, status)
    values (auth.uid(), invite.owner_id, 'pending') returning id into pairing;
  update public.pairing_codes set used_at = now() where id = invite.id;
  return pairing;
end $$;

create function public.respond_pairing(pairing uuid, accept_request boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or accept_request is null then raise exception 'Invalid request'; end if;
  update public.pairings set status = case when accept_request then 'accepted' else 'revoked' end
    where id = pairing and guardian_id = auth.uid() and status = 'pending';
  if not found then raise exception 'Request unavailable'; end if;
end $$;

create function public.revoke_pairing(pairing uuid) returns void language plpgsql security definer
set search_path = '' as $$
begin
  update public.pairings set status = 'revoked' where id = pairing
    and auth.uid() in (primary_id, guardian_id) and status in ('pending', 'accepted');
  if not found then raise exception 'Pairing unavailable'; end if;
end $$;

create function public.send_message(pairing uuid, message text) returns uuid language plpgsql security definer
set search_path = '' as $$
declare message_id uuid;
begin
  if auth.uid() is null or message is null or length(trim(message)) not between 1 and 2000 then
    raise exception 'Invalid message';
  end if;
  perform 1 from public.pairings where id = pairing and status = 'accepted'
    and auth.uid() in (primary_id, guardian_id) for update;
  if not found then raise exception 'Pairing unavailable'; end if;
  insert into public.messages(pairing_id, sender_id, body)
    values (pairing, auth.uid(), trim(message)) returning id into message_id;
  return message_id;
end $$;
revoke all on function public.create_pairing_code(), public.request_pairing(text), public.respond_pairing(uuid, boolean), public.revoke_pairing(uuid), public.send_message(uuid, text) from public, anon;
grant execute on function public.create_pairing_code(), public.request_pairing(text), public.respond_pairing(uuid, boolean), public.revoke_pairing(uuid), public.send_message(uuid, text) to authenticated;

create function public.register_push_token(device_token text) returns void language plpgsql security definer
set search_path = '' as $$
begin
  if auth.uid() is null or device_token is null or length(device_token) not between 20 and 4096 then
    raise exception 'Invalid device token';
  end if;
  insert into public.push_tokens(token, user_id) values (device_token, auth.uid())
    on conflict (token) do update set user_id = excluded.user_id, updated_at = now();
end $$;
create function public.unregister_push_token(device_token text) returns void language sql security definer
set search_path = '' as $$
  delete from public.push_tokens where token = device_token and user_id = auth.uid();
$$;
revoke all on function public.register_push_token(text), public.unregister_push_token(text) from public, anon;
grant execute on function public.register_push_token(text), public.unregister_push_token(text) to authenticated;
