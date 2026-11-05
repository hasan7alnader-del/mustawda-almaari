-- مستودع المعري: إعداد قاعدة البيانات في Supabase
-- 1) غيّر البريد في الدالة is_owner إلى بريدك أنت (المالك) ثم نفّذ الملف كاملاً في SQL Editor.

create table if not exists companies(
  id bigint generated always as identity primary key,
  name text not null, sort int default 0, icon text, created_at timestamptz default now());
create table if not exists products(
  id bigint generated always as identity primary key,
  company_id bigint not null references companies(id) on delete cascade,
  name text not null, descr text, offer text, cat text, img text,
  sort int default 0, created_at timestamptz default now());
create table if not exists reps(
  id bigint generated always as identity primary key,
  name text not null, phone text not null, active boolean default true);
create table if not exists offers(
  id bigint generated always as identity primary key,
  title text not null, body text,
  company_id bigint references companies(id) on delete set null,
  starts_at timestamptz default now(), ends_at timestamptz, launched_at timestamptz,
  auto_fire boolean default true, active boolean default true, created_at timestamptz default now());
create table if not exists settings(key text primary key, value text);

create or replace function public.is_owner() returns boolean
language sql stable as $$ select coalesce(auth.jwt()->>'email','') = 'OWNER_EMAIL_HERE' $$;

alter table companies enable row level security;
alter table products  enable row level security;
alter table reps      enable row level security;
alter table offers    enable row level security;
alter table settings  enable row level security;

create policy "read companies" on companies for select using (true);
create policy "read products"  on products  for select using (true);
create policy "read reps"      on reps      for select using (true);
create policy "read offers"    on offers    for select using (true);
create policy "read settings"  on settings  for select using (true);
create policy "owner companies" on companies for all using (public.is_owner()) with check (public.is_owner());
create policy "owner products"  on products  for all using (public.is_owner()) with check (public.is_owner());
create policy "owner reps"      on reps      for all using (public.is_owner()) with check (public.is_owner());
create policy "owner offers"    on offers    for all using (public.is_owner()) with check (public.is_owner());
create policy "owner settings"  on settings  for all using (public.is_owner()) with check (public.is_owner());

insert into storage.buckets(id,name,public) values('img','img',true) on conflict (id) do nothing;
create policy "img read"   on storage.objects for select using (bucket_id='img');
create policy "img insert" on storage.objects for insert with check (bucket_id='img' and public.is_owner());
create policy "img update" on storage.objects for update using (bucket_id='img' and public.is_owner());
create policy "img delete" on storage.objects for delete using (bucket_id='img' and public.is_owner());

alter publication supabase_realtime add table companies, products, reps, offers, settings;
