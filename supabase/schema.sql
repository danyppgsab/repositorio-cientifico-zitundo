-- Repositório Científico de Zitundo
-- Schema inicial: documentos públicos/restritos, equipa e armazenamento.
-- Autorize o primeiro administrador após criar a conta (ver README.md).

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table if not exists public.team_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'researcher' check (role in ('admin','researcher')),
  created_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'Outros',
  description text,
  visibility text not null check (visibility in ('public','restricted')),
  storage_path text not null,
  source_url text,
  original_filename text not null,
  uploaded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

alter table public.team_members enable row level security;
alter table public.documents enable row level security;

-- Funções auxiliares fora do schema exposto. SECURITY DEFINER evita
-- recursão de RLS ao consultar team_members; auth.uid() é sempre validado.
create or replace function private.is_team_member()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.team_members
    where user_id = (select auth.uid())
  );
$$;

create or replace function private.is_team_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.team_members
    where user_id = (select auth.uid()) and role = 'admin'
  );
$$;

revoke all on function private.is_team_member() from public;
revoke all on function private.is_team_admin() from public;
grant execute on function private.is_team_member() to authenticated;
grant execute on function private.is_team_admin() to authenticated;

drop policy if exists "Team members can read team list" on public.team_members;
create policy "Team members can read team list" on public.team_members
for select to authenticated using ((select private.is_team_member()));

drop policy if exists "Public documents visible to everyone" on public.documents;
drop policy if exists "Public documents visible to anon" on public.documents;
create policy "Public documents visible to anon" on public.documents
for select to anon using (visibility = 'public');
create policy "Public and team documents visible to authenticated" on public.documents
for select to authenticated using (visibility = 'public' or (select private.is_team_member()));

drop policy if exists "Team can upload documents" on public.documents;
create policy "Team can upload documents" on public.documents
for insert to authenticated with check (
  (select private.is_team_member()) and uploaded_by = (select auth.uid())
);

drop policy if exists "Team can delete documents" on public.documents;
create policy "Team can delete documents" on public.documents
for delete to authenticated using ((select private.is_team_member()));

insert into storage.buckets (id,name,public,file_size_limit)
values
 ('public-documents','public-documents',true,26214400),
 ('restricted-documents','restricted-documents',false,26214400)
on conflict (id) do update
set public = excluded.public, file_size_limit = excluded.file_size_limit;

drop policy if exists "Public files readable by everyone" on storage.objects;
create policy "Public files readable by everyone" on storage.objects
for select to anon, authenticated using (bucket_id = 'public-documents');

drop policy if exists "Team can read restricted files" on storage.objects;
create policy "Team can read restricted files" on storage.objects
for select to authenticated using (
  bucket_id = 'restricted-documents' and (select private.is_team_member())
);

drop policy if exists "Team can upload files" on storage.objects;
create policy "Team can upload files" on storage.objects
for insert to authenticated with check (
  (select private.is_team_member())
  and bucket_id in ('public-documents','restricted-documents')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Team can delete files" on storage.objects;
create policy "Team can delete files" on storage.objects
for delete to authenticated using (
  (select private.is_team_member())
  and bucket_id in ('public-documents','restricted-documents')
);
