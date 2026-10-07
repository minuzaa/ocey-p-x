create extension if not exists pgcrypto;
create table if not exists public.admins(id uuid primary key references auth.users(id) on delete cascade,created_at timestamptz default now());
create table if not exists public.media(id uuid primary key default gen_random_uuid(),name text not null,type text not null check(type in ('image','video')),mime text,path text unique not null,size_bytes bigint default 0,created_at timestamptz default now(),updated_at timestamptz default now());
alter table public.admins enable row level security; alter table public.media enable row level security;
drop policy if exists "admin own" on public.admins; create policy "admin own" on public.admins for select to authenticated using(id=auth.uid());
drop policy if exists "media read" on public.media; create policy "media read" on public.media for select to anon,authenticated using(true);
drop policy if exists "media insert" on public.media; create policy "media insert" on public.media for insert to anon,authenticated with check(true);
drop policy if exists "admin update" on public.media; create policy "admin update" on public.media for update to authenticated using(exists(select 1 from public.admins where id=auth.uid())) with check(exists(select 1 from public.admins where id=auth.uid()));
drop policy if exists "admin delete" on public.media; create policy "admin delete" on public.media for delete to authenticated using(exists(select 1 from public.admins where id=auth.uid()));
insert into storage.buckets(id,name,public) values('ocey-media','ocey-media',true) on conflict(id) do update set public=true;
drop policy if exists "media files read" on storage.objects; create policy "media files read" on storage.objects for select to anon,authenticated using(bucket_id='ocey-media');
drop policy if exists "media files upload" on storage.objects; create policy "media files upload" on storage.objects for insert to anon,authenticated with check(bucket_id='ocey-media');
drop policy if exists "media files update" on storage.objects; create policy "media files update" on storage.objects for update to authenticated using(bucket_id='ocey-media' and exists(select 1 from public.admins where id=auth.uid())) with check(bucket_id='ocey-media' and exists(select 1 from public.admins where id=auth.uid()));
drop policy if exists "media files delete" on storage.objects; create policy "media files delete" on storage.objects for delete to authenticated using(bucket_id='ocey-media' and exists(select 1 from public.admins where id=auth.uid()));
-- Setelah membuat user Auth admin:
-- insert into public.admins(id) select id from auth.users where email='EMAIL_ADMIN_KAMU';
