-- KLEREK KASIR v3.4 — jalankan sekali di SQL Editor proyek Supabase.
-- Tabel tidak menerima INSERT/UPDATE/DELETE dari browser; penulisan lewat RPC
-- dengan validasi role, identitas auth.uid(), dan revision (optimistic locking).
-- Gunakan publishable/anon key di browser; JANGAN gunakan service_role/secret key.

create extension if not exists pgcrypto;

create table if not exists public.klerek_stores (
  id uuid primary key default gen_random_uuid(),
  name text not null check(length(name) between 2 and 100),
  owner_id uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.klerek_members (
  store_id uuid not null references public.klerek_stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'kasir' check(role in ('admin','kepala_toko','kasir')),
  joined_at timestamptz not null default now(),
  primary key (store_id, user_id)
);
create index if not exists klerek_members_user_id_idx on public.klerek_members(user_id);

create table if not exists public.klerek_invites (
  store_id uuid primary key references public.klerek_stores(id) on delete cascade,
  invite_code uuid not null unique default gen_random_uuid()
);

create table if not exists public.klerek_documents (
  store_id uuid not null references public.klerek_stores(id) on delete cascade,
  doc_key text not null,
  payload jsonb not null default '{}'::jsonb,
  revision bigint not null default 1 check(revision >= 1),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id),
  primary key (store_id, doc_key),
  check(length(doc_key) <= 65),
  check(octet_length(payload::text) <= 120000)
);
create index if not exists klerek_documents_recent_idx on public.klerek_documents(store_id,updated_at desc);

-- SECURITY DEFINER mencegah rekursi pada RLS member.
create or replace function public.klerek_is_member(p_store uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.klerek_members where store_id=p_store and user_id=(select auth.uid()));
$$;

alter table public.klerek_stores enable row level security;
alter table public.klerek_members enable row level security;
alter table public.klerek_invites enable row level security;
alter table public.klerek_documents enable row level security;

-- Jangan expose tabel invite ke browser; hanya pengelola yang dapat mengambil kode melalui RPC.
revoke all on public.klerek_stores from anon, authenticated;
revoke all on public.klerek_members from anon, authenticated;
revoke all on public.klerek_invites from anon, authenticated;
revoke all on public.klerek_documents from anon, authenticated;
grant select on public.klerek_stores, public.klerek_members, public.klerek_documents to authenticated;

-- Batasi pembacaan hanya anggota toko yang sah.
drop policy if exists klerek_store_read on public.klerek_stores;
create policy klerek_store_read on public.klerek_stores for select to authenticated
 using (public.klerek_is_member(id));
drop policy if exists klerek_member_read on public.klerek_members;
create policy klerek_member_read on public.klerek_members for select to authenticated
 using (user_id=(select auth.uid()) or public.klerek_is_member(store_id));
drop policy if exists klerek_doc_read on public.klerek_documents;
create policy klerek_doc_read on public.klerek_documents for select to authenticated
 using (public.klerek_is_member(store_id));

create or replace function public.klerek_create_store(p_name text)
returns table(store_id uuid, invite_code uuid)
language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_invite uuid;
begin
  if auth.uid() is null then raise exception 'Harus login'; end if;
  if length(trim(coalesce(p_name,''))) not between 2 and 100 then raise exception 'Nama toko 2–100 karakter'; end if;
  insert into public.klerek_stores(name,owner_id) values(trim(p_name),auth.uid()) returning id into v_id;
  insert into public.klerek_members(store_id,user_id,role) values(v_id,auth.uid(),'admin');
  insert into public.klerek_invites(store_id) values(v_id) returning klerek_invites.invite_code into v_invite;
  return query select v_id,v_invite;
end $$;

create or replace function public.klerek_join_store(p_invite_code uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_store uuid;
begin
  if auth.uid() is null then raise exception 'Harus login'; end if;
  select store_id into v_store from public.klerek_invites where invite_code=p_invite_code;
  if v_store is null then raise exception 'Kode undangan tidak berlaku'; end if;
  insert into public.klerek_members(store_id,user_id,role) values(v_store,auth.uid(),'kasir')
    on conflict (store_id,user_id) do nothing;
  return v_store;
end $$;

create or replace function public.klerek_get_invite(p_store_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_code uuid;
begin
  if not exists(select 1 from public.klerek_members where store_id=p_store_id and user_id=auth.uid() and role='admin')
    then raise exception 'Hanya admin yang dapat melihat undangan'; end if;
  select invite_code into v_code from public.klerek_invites where store_id=p_store_id;
  return v_code;
end $$;

create or replace function public.klerek_rotate_invite(p_store_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_code uuid;
begin
  if not exists(select 1 from public.klerek_members where store_id=p_store_id and user_id=auth.uid() and role='admin')
    then raise exception 'Hanya admin yang dapat mengganti undangan'; end if;
  update public.klerek_invites set invite_code=gen_random_uuid() where store_id=p_store_id returning invite_code into v_code;
  return v_code;
end $$;

create or replace function public.klerek_list_members(p_store_id uuid)
returns table(user_id uuid,email text,role text)
language plpgsql security definer set search_path = '' as $$
begin
  if not exists(select 1 from public.klerek_members where store_id=p_store_id and user_id=auth.uid() and role='admin')
    then raise exception 'Hanya admin dapat melihat daftar anggota'; end if;
  return query select m.user_id,u.email::text,m.role from public.klerek_members m
    join auth.users u on u.id=m.user_id where m.store_id=p_store_id order by m.joined_at;
end $$;

create or replace function public.klerek_set_member_role(p_store_id uuid,p_user_id uuid,p_role text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists(select 1 from public.klerek_members where store_id=p_store_id and user_id=auth.uid() and role='admin')
    then raise exception 'Hanya admin'; end if;
  if p_role not in ('kasir','kepala_toko','admin') then raise exception 'Role tidak dikenal'; end if;
  if exists(select 1 from public.klerek_stores where id=p_store_id and owner_id=p_user_id)
    then raise exception 'Role pemilik tidak boleh diubah'; end if;
  update public.klerek_members set role=p_role where store_id=p_store_id and user_id=p_user_id;
  if not found then raise exception 'Anggota tidak ditemukan'; end if;
end $$;

create or replace function public.klerek_remove_member(p_store_id uuid,p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists(select 1 from public.klerek_members where store_id=p_store_id and user_id=auth.uid() and role='admin')
    then raise exception 'Hanya admin'; end if;
  if exists(select 1 from public.klerek_stores where id=p_store_id and owner_id=p_user_id)
    then raise exception 'Pemilik toko tidak boleh dihapus'; end if;
  delete from public.klerek_members where store_id=p_store_id and user_id=p_user_id;
end $$;

-- Revision: 0 hanya untuk data baru; jika versi server berbeda, transaksi ditolak.
-- Penerapan per kasir (bukan satu dokumen satu hari) mengurangi bentrok saat input bersamaan.
create or replace function public.klerek_put_document(
  p_store_id uuid,p_doc_key text,p_payload jsonb,p_expected_revision bigint
)
returns table(revision bigint,updated_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare v_role text;v_rev bigint;v_time timestamptz;v_existing bigint;
begin
  if auth.uid() is null then raise exception 'Harus login'; end if;
  select m.role into v_role from public.klerek_members m where m.store_id=p_store_id and m.user_id=auth.uid();
  if v_role is null then raise exception 'Bukan anggota toko'; end if;
  if p_doc_key <> 'staff' and p_doc_key !~ '^head:[0-9]{4}-[0-9]{2}-[0-9]{2}$'
   and p_doc_key !~ '^cashier:[0-9]{4}-[0-9]{2}-[0-9]{2}:[123]:[123]$'
    then raise exception 'Kunci data tidak dikenal'; end if;
  if p_doc_key ~ ':1:3$' or p_doc_key ~ ':2:3$' then raise exception 'Shift 1/2 maksimal 2 kasir'; end if;
  if (p_doc_key='staff' or p_doc_key like 'head:%') and v_role='kasir'
    then raise exception 'Hanya kepala toko/admin dapat mengubah data ini'; end if;
  if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>120000
    then raise exception 'Payload tidak valid atau terlalu besar'; end if;
  if coalesce(p_expected_revision,-1)<0 then raise exception 'Revision tidak valid'; end if;
  select d.revision into v_existing from public.klerek_documents d
     where d.store_id=p_store_id and d.doc_key=p_doc_key for update;
  if coalesce(v_existing,0) <> p_expected_revision then raise exception 'CLOUD_CONFLICT'; end if;
  insert into public.klerek_documents as d (store_id,doc_key,payload,revision,updated_by)
    values(p_store_id,p_doc_key,p_payload,1,auth.uid())
  on conflict (store_id,doc_key) do update set payload=excluded.payload,
    revision=d.revision+1,updated_at=now(),updated_by=auth.uid()
    where d.revision=p_expected_revision
  returning d.revision,d.updated_at into v_rev,v_time;
  if not found then raise exception 'CLOUD_CONFLICT'; end if;
  return query select v_rev,v_time;
end $$;

-- Hindari pemberian hak eksekusi default kepada anon.
revoke all on function public.klerek_is_member(uuid) from public;
revoke all on function public.klerek_create_store(text) from public;
revoke all on function public.klerek_join_store(uuid) from public;
revoke all on function public.klerek_get_invite(uuid) from public;
revoke all on function public.klerek_rotate_invite(uuid) from public;
revoke all on function public.klerek_list_members(uuid) from public;
revoke all on function public.klerek_set_member_role(uuid,uuid,text) from public;
revoke all on function public.klerek_remove_member(uuid,uuid) from public;
revoke all on function public.klerek_put_document(uuid,text,jsonb,bigint) from public;
grant execute on function public.klerek_is_member(uuid) to authenticated;
grant execute on function public.klerek_create_store(text) to authenticated;
grant execute on function public.klerek_join_store(uuid) to authenticated;
grant execute on function public.klerek_get_invite(uuid) to authenticated;
grant execute on function public.klerek_rotate_invite(uuid) to authenticated;
grant execute on function public.klerek_list_members(uuid) to authenticated;
grant execute on function public.klerek_set_member_role(uuid,uuid,text) to authenticated;
grant execute on function public.klerek_remove_member(uuid,uuid) to authenticated;
grant execute on function public.klerek_put_document(uuid,text,jsonb,bigint) to authenticated;

-- Realtime Postgres Changes; operasi penulisan di broadcast ke anggota lewat RLS SELECT.
do $$ begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') and
     not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='klerek_documents') then
       alter publication supabase_realtime add table public.klerek_documents;
  end if;
end $$;

-- Opsional: atur Auth > URL Configuration (Site URL = situs GitHub Pages)
-- dan Auth > Providers > Email. Konfirmasi email mungkin diwajibkan oleh proyek.
