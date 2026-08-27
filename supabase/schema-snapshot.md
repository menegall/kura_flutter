> Snapshot manuale delle policy RLS remote — 2026-08-27

> Le tabelle hanno gia' ENABLE ROW LEVEL SECURITY sul progetto remoto.

# Definizione Policies

 tablename  | policyname                                  | cmd | roles    | qual                                                                                   | with_check |
| ---------- | ------------------------------------------- | --- | -------- | -------------------------------------------------------------------------------------- | ---------- |
| activities | Users can manage activities of their pupils | ALL | {public} | (pupil_id IN ( SELECT pupils.id
   FROM pupils
  WHERE (pupils.user_id = auth.uid()))) | null       |
| pupils     | Users can manage their own pupils           | ALL | {public} | (auth.uid() = user_id)                                                                 | null       |


# Definizione Tabelle

| table_name | column_name    | data_type                | is_nullable | column_default    |
| ---------- | -------------- | ------------------------ | ----------- | ----------------- |
| activities | id             | uuid                     | NO          | gen_random_uuid() |
| activities | pupil_id       | uuid                     | NO          | null              |
| activities | activity_date  | date                     | NO          | null              |
| activities | duration       | numeric                  | YES         | null              |
| activities | description    | text                     | YES         | null              |
| activities | created_at     | timestamp with time zone | YES         | now()             |
| activities | kilometers     | numeric                  | YES         | null              |
| activities | type           | USER-DEFINED             | NO          | null              |
| activities | stamp          | numeric                  | YES         | null              |
| activities | other_expenses | numeric                  | YES         | null              |
| pupils     | id             | uuid                     | NO          | gen_random_uuid() |
| pupils     | user_id        | uuid                     | NO          | null              |
| pupils     | name           | text                     | NO          | null              |
| pupils     | max_hours      | numeric                  | NO          | null              |
| pupils     | created_at     | timestamp with time zone | YES         | now()             |
| pupils     | tarif          | numeric                  | NO          | null              |
| pupils     | km_tarif       | numeric                  | NO          | null              |