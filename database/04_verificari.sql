-- Fitness Manager – Baze de Date II
-- Executați în DBeaver, pe conexiunea la baza fitness_manager.
-- Scriptul doar citește baza: nu creează și nu modifică obiecte sau date.
-- Rezultatele pot include scheme diferite de public.

BEGIN TRANSACTION READ ONLY;

-- 1. Confirmați baza de date și schema conexiunii.
SELECT current_database() AS baza_de_date,
       current_schema() AS schema_curenta,
       version() AS versiune_postgresql;

-- 2. Tabelele utilizatorului. Verificați prezența celor 12 tabele așteptate.
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;

-- 3. Coloanele reale: tipuri, valori implicite, NULL și identity.
SELECT table_schema, table_name, ordinal_position, column_name,
       data_type, udt_schema, udt_name, character_maximum_length,
       numeric_precision, numeric_scale, is_nullable, column_default,
       is_identity, identity_generation, is_generated, generation_expression
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 4. Constrângerile reale, inclusiv PK, FK, UNIQUE, CHECK și EXCLUDE.
SELECT n.nspname AS schema_tabelului,
       t.relname AS tabel,
       c.conname AS constrangere,
       c.contype AS tip,
       pg_get_constraintdef(c.oid, true) AS definitie,
       c.convalidated AS validata
FROM pg_constraint AS c
JOIN pg_class AS t ON t.oid = c.conrelid
JOIN pg_namespace AS n ON n.oid = t.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, t.relname, c.conname;

-- 5. Indexurile existente: verificați-le înainte de a adăuga indexuri noi.
-- PK și UNIQUE au deja indexuri; un index compus poate acoperi un FK
-- atunci când coloanele acestuia se află la începutul indexului.
SELECT p.schemaname, p.tablename, p.indexname, p.indexdef,
       i.indisvalid AS valid, i.indisready AS pregatit
FROM pg_indexes AS p
JOIN pg_namespace AS n ON n.nspname = p.schemaname
JOIN pg_class AS idx ON idx.relnamespace = n.oid
                       AND idx.relname = p.indexname
JOIN pg_index AS i ON i.indexrelid = idx.oid
WHERE p.schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY p.schemaname, p.tablename, p.indexname;

-- 6. Număr exact de rânduri pentru fiecare dintre cele 12 tabele.
-- Rezultatele apar în panoul de mesaje/output al DBeaver (RAISE NOTICE).
-- Nu sunt citite sau afișate parole ori alte valori din rânduri.
-- Un tabel inaccesibil este semnalat fără a opri restul numărătorilor.
DO $$
DECLARE
    tabel RECORD;
    numar_randuri BIGINT;
BEGIN
    FOR tabel IN
        SELECT n.nspname AS schema_tabelului, c.relname AS nume
        FROM pg_class AS c
        JOIN pg_namespace AS n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r', 'p')
          AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          AND c.relname = ANY (ARRAY[
              'membri', 'antrenori', 'specializari', 'antrenori_specializari',
              'tipuri_abonamente', 'abonamente', 'plati', 'clase_fitness',
              'rezervari_clase', 'programari_personale', 'roluri', 'utilizatori'
          ])
        ORDER BY n.nspname, c.relname
    LOOP
        BEGIN
            EXECUTE format('SELECT count(*) FROM %I.%I',
                           tabel.schema_tabelului, tabel.nume)
                INTO numar_randuri;
            RAISE NOTICE '%.%: % rânduri',
                         tabel.schema_tabelului, tabel.nume, numar_randuri;
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE NOTICE '%.%: lipsesc permisiunile SELECT',
                         tabel.schema_tabelului, tabel.nume;
        END;
    END LOOP;
END;
$$;

-- 7. Număr de rânduri fictive: valorile așteptate presupun un import complet,
-- fără coliziuni cu rânduri existente. Rulați înainte și după repetarea
-- scriptului 03: numărătorile trebuie să rămână identice după primul import.
SELECT 'membri' AS tabel, count(*) AS randuri_demo, 4 AS asteptat
FROM public.membri WHERE email ~ '^demo[.]bd2[.]membru[1-4]@example[.]com$'
UNION ALL
SELECT 'antrenori', count(*), 2 FROM public.antrenori
WHERE email ~ '^demo[.]bd2[.]antrenor[1-2]@example[.]com$'
UNION ALL
SELECT 'specializari', count(*), 2 FROM public.specializari
WHERE denumire IN ('DEMO_BD2_YOGA', 'DEMO_BD2_FORTA')
UNION ALL
SELECT 'roluri', count(*), 2 FROM public.roluri
WHERE denumire IN ('DEMO_BD2_MEMBRU', 'DEMO_BD2_ANTRENOR')
UNION ALL
SELECT 'tipuri_abonamente', count(*), 2 FROM public.tipuri_abonamente
WHERE denumire IN ('DEMO_BD2_LUNAR', 'DEMO_BD2_TRIMESTRIAL')
UNION ALL
SELECT 'antrenori_specializari', count(*), 2
FROM public.antrenori_specializari x
JOIN public.antrenori a USING (id_antrenor)
JOIN public.specializari s USING (id_specializare)
WHERE (a.email = 'demo.bd2.antrenor1@example.com' AND s.denumire = 'DEMO_BD2_YOGA')
   OR (a.email = 'demo.bd2.antrenor2@example.com' AND s.denumire = 'DEMO_BD2_FORTA')
UNION ALL
SELECT 'abonamente', count(*), 4 FROM public.abonamente a
JOIN public.membri m USING (id_membru)
WHERE m.email ~ '^demo[.]bd2[.]membru[1-4]@example[.]com$'
  AND a.data_start = DATE '2026-01-05'
UNION ALL
SELECT 'plati', count(*), 4 FROM public.plati p
JOIN public.abonamente a USING (id_abonament)
JOIN public.membri m USING (id_membru)
WHERE m.email ~ '^demo[.]bd2[.]membru[1-4]@example[.]com$'
  AND a.data_start = DATE '2026-01-05'
  AND p.data_plata = TIMESTAMP '2026-01-05 09:00:00'
UNION ALL
SELECT 'clase_fitness', count(*), 4 FROM public.clase_fitness
WHERE denumire ~ '^DEMO_BD2_CLASA_[1-4]$'
UNION ALL
SELECT 'rezervari_clase', count(*), 4 FROM public.rezervari_clase r
JOIN public.clase_fitness c USING (id_clasa)
JOIN public.membri m USING (id_membru)
WHERE c.denumire ~ '^DEMO_BD2_CLASA_[1-4]$'
  AND m.email ~ '^demo[.]bd2[.]membru[1-4]@example[.]com$'
UNION ALL
SELECT 'programari_personale', count(*), 4 FROM public.programari_personale
WHERE observatii ~ '^DEMO_BD2_PROGRAMARE_[1-4]$'
UNION ALL
SELECT 'utilizatori', count(*), 6 FROM public.utilizatori
WHERE username ~ '^demo_bd2_(membru[1-4]|antrenor[1-2])$'
ORDER BY tabel;

-- 8. Relațiile dintre membri, abonamente, tipuri și plăți.
-- Fără parole/hash-uri în rezultate.
SELECT m.email, t.denumire, a.data_start, a.data_sfarsit, a.status,
       t.pret, p.suma, p.metoda_plata, p.status_plata
FROM public.membri m
JOIN public.abonamente a USING (id_membru)
JOIN public.tipuri_abonamente t USING (id_tip)
LEFT JOIN public.plati p USING (id_abonament)
WHERE m.email ~ '^demo[.]bd2[.]membru[1-4]@example[.]com$'
ORDER BY m.email, a.data_start, p.id_plata;

-- 9. Trebuie să returneze zero rânduri: clase demo peste capacitate.
SELECT c.id_clasa, c.denumire, c.capacitate, count(r.id_rezervare) AS rezervari
FROM public.clase_fitness c
LEFT JOIN public.rezervari_clase r ON r.id_clasa = c.id_clasa
                                    AND r.status <> 'ANULATA'
WHERE c.denumire ~ '^DEMO_BD2_CLASA_[1-4]$'
GROUP BY c.id_clasa
HAVING count(r.id_rezervare) > c.capacitate;

-- 10. Trebuie să returneze zero rânduri: conturi demo activate accidental.
SELECT username, activ FROM public.utilizatori
WHERE username ~ '^demo_bd2_(membru[1-4]|antrenor[1-2])$' AND activ;

COMMIT;
