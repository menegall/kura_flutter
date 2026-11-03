-- Eliminazione dell'account: corregge due problemi.
--
-- 1. "permission denied for function delete_user" (42501): il ruolo
--    authenticated non ha il permesso EXECUTE sulla funzione.
-- 2. L'utente non si elimina nemmeno dalla dashboard: le foreign key verso
--    auth.users / pupils non hanno ON DELETE CASCADE e bloccano la delete.
--
-- Da eseguire una volta nel SQL Editor di Supabase.

begin;

-- Foreign key con ON DELETE CASCADE: eliminando un utente spariscono anche
-- i suoi pupilli e le loro attività. Si eliminano prima quelle esistenti,
-- qualunque nome abbiano.
do $$
declare
  r record;
begin
  for r in
    select con.conname, rel.relname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where con.contype = 'f'
      and nsp.nspname = 'public'
      and (
        (rel.relname = 'pupils' and con.confrelid = 'auth.users'::regclass)
        or (rel.relname = 'activities' and con.confrelid = 'public.pupils'::regclass)
      )
  loop
    execute format('alter table public.%I drop constraint %I', r.relname, r.conname);
  end loop;
end $$;

-- NOT VALID: non controlla le righe già presenti, così l'operazione non
-- fallisce per eventuali dati orfani. Le nuove righe vengono verificate.
alter table public.pupils
  add constraint pupils_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade not valid;

alter table public.activities
  add constraint activities_pupil_id_fkey
  foreign key (pupil_id) references public.pupils (id) on delete cascade not valid;

-- Funzione chiamata dall'app (Impostazioni -> Elimina account).
-- SECURITY DEFINER: gira con i privilegi del proprietario (postgres), che
-- può cancellare da auth.users; auth.uid() limita la delete all'utente
-- che la chiama.
drop function if exists public.delete_user();

create function public.delete_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Utente non autenticato';
  end if;

  delete from public.activities
  where pupil_id in (select id from public.pupils where user_id = uid);
  delete from public.pupils where user_id = uid;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;

commit;

-- Verifica (facoltativa): deve restituire una riga con can_execute = true.
-- select has_function_privilege('authenticated', 'public.delete_user()', 'execute') as can_execute;
