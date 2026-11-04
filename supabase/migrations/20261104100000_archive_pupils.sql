-- Archiviazione dei pupilli: un pupillo archiviato (mandato concluso) sparisce
-- dalla Home ma conserva tutte le sue attività per i rendiconti.
-- NULL = attivo, una data = archiviato in quel momento.
--
-- Aggiunge solo una colonna vuota: i dati esistenti non vengono toccati e
-- tutti i pupilli restano attivi. Le policy RLS su pupils valgono anche
-- per questa colonna.
--
-- Da eseguire una volta nel SQL Editor di Supabase, PRIMA di pubblicare la
-- versione dell'app che la usa.

alter table public.pupils
  add column if not exists archived_at timestamptz;
