-- Indexuri pentru FK, conform schemei din 01_schema.sql.
-- Executare manuală, numai după aprobarea modificării bazei.
-- Nu adăugăm indexuri pentru FK deja acoperite de PK/UNIQUE:
-- antrenori_specializari.id_antrenor; rezervari_clase.id_membru;
-- utilizatori.id_membru și utilizatori.id_antrenor.
BEGIN;
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT * FROM (VALUES
        ('abonamente', 'id_membru', 'idx_abonamente_id_membru'),
        ('abonamente', 'id_tip', 'idx_abonamente_id_tip'),
        ('antrenori_specializari', 'id_specializare', 'idx_antrenori_specializari_id_specializare'),
        ('clase_fitness', 'id_antrenor', 'idx_clase_fitness_id_antrenor'),
        ('plati', 'id_abonament', 'idx_plati_id_abonament'),
        ('programari_personale', 'id_membru', 'idx_programari_personale_id_membru'),
        ('programari_personale', 'id_antrenor', 'idx_programari_personale_id_antrenor'),
        ('rezervari_clase', 'id_clasa', 'idx_rezervari_clase_id_clasa'),
        ('utilizatori', 'id_rol', 'idx_utilizatori_id_rol')
    ) AS lista(tabel, coloana, nume_index)
    LOOP
        -- Un index B-tree valid, neparțial, cu FK pe prima poziție
        -- acoperă deja căutările necesare, chiar dacă are alt nume.
        IF NOT EXISTS (
            SELECT 1
            FROM pg_index i
            JOIN pg_class t ON t.oid = i.indrelid
            JOIN pg_namespace n ON n.oid = t.relnamespace
            JOIN pg_class ix ON ix.oid = i.indexrelid
            JOIN pg_am am ON am.oid = ix.relam
            JOIN pg_attribute a ON a.attrelid = t.oid
                                  AND a.attname = r.coloana
            WHERE n.nspname = 'public' AND t.relname = r.tabel
              AND i.indisvalid AND i.indisready
              AND i.indpred IS NULL AND am.amname = 'btree'
              AND i.indkey[0] = a.attnum
        ) THEN
            -- Un nume ocupat de un alt obiect produce eroare, nu este ignorat.
            EXECUTE format('CREATE INDEX %I ON public.%I (%I)',
                           r.nume_index, r.tabel, r.coloana);
        END IF;
    END LOOP;
END;
$$;
COMMIT;
