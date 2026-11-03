-- Date integral fictive, identificabile prin prefixul DEMO_BD2 / domeniul example.com.
-- Executare manuală, numai după aprobarea modificării bazei reale.
-- Nu specificăm ID-urile identity și nu actualizăm rândurile existente.
-- Date fixe: rulările repetate folosesc aceleași chei de identificare.
BEGIN;
-- Serializăm scrierile pe durata importului pentru a proteja și tabelele
-- fără constrângeri UNIQUE potrivite. Blocările se eliberează la COMMIT.
LOCK TABLE public.membri, public.antrenori, public.specializari,
 public.antrenori_specializari, public.tipuri_abonamente, public.abonamente,
 public.plati, public.clase_fitness, public.rezervari_clase,
 public.programari_personale, public.roluri, public.utilizatori
 IN SHARE ROW EXCLUSIVE MODE;

INSERT INTO public.roluri (denumire, descriere) VALUES
 ('DEMO_BD2_MEMBRU', 'Rol fictiv pentru membri'),
 ('DEMO_BD2_ANTRENOR', 'Rol fictiv pentru antrenori')
ON CONFLICT (denumire) DO NOTHING;

INSERT INTO public.specializari (denumire, descriere) VALUES
 ('DEMO_BD2_YOGA', 'Mobilitate și echilibru'),
 ('DEMO_BD2_FORTA', 'Antrenamente de forță')
ON CONFLICT (denumire) DO NOTHING;

INSERT INTO public.tipuri_abonamente (denumire, durata_zile, pret, descriere) VALUES
 ('DEMO_BD2_LUNAR', 30, 180.00, 'Abonament fictiv de 30 zile'),
 ('DEMO_BD2_TRIMESTRIAL', 90, 450.00, 'Abonament fictiv de 90 zile')
ON CONFLICT (denumire) DO NOTHING;

INSERT INTO public.antrenori (nume, prenume, email, data_angajare, salariu) VALUES
 ('Demonstrativ', 'Ana', 'demo.bd2.antrenor1@example.com', DATE '2025-01-10', 5000),
 ('Demonstrativ', 'Mihai', 'demo.bd2.antrenor2@example.com', DATE '2025-02-10', 5500)
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.membri
 (nume, prenume, email, data_nasterii, data_inscriere) VALUES
 ('Exemplu', 'Ioana', 'demo.bd2.membru1@example.com', DATE '2000-04-12', DATE '2026-01-05'),
 ('Exemplu', 'Andrei', 'demo.bd2.membru2@example.com', DATE '1998-07-20', DATE '2026-01-05'),
 ('Exemplu', 'Elena', 'demo.bd2.membru3@example.com', DATE '2002-09-15', DATE '2026-01-05'),
 ('Exemplu', 'Vlad', 'demo.bd2.membru4@example.com', DATE '1995-12-03', DATE '2026-01-05')
ON CONFLICT (email) DO NOTHING;

DO $$
DECLARE
    k INTEGER;
    membru INTEGER;
    antrenor INTEGER;
    tip INTEGER;
    abonament INTEGER;
    clasa INTEGER;
    specializare INTEGER;
    rol INTEGER;
    inceput DATE;
    sfarsit DATE;
    moment TIMESTAMP;
    pret NUMERIC;
BEGIN
    FOR k IN 1..4 LOOP
        SELECT id_membru INTO STRICT membru FROM public.membri
        WHERE email = format('demo.bd2.membru%s@example.com', k);
        SELECT id_antrenor INTO STRICT antrenor FROM public.antrenori
        WHERE email = format('demo.bd2.antrenor%s@example.com', CASE WHEN k % 2 = 1 THEN 1 ELSE 2 END);
        SELECT id_specializare INTO STRICT specializare FROM public.specializari
        WHERE denumire = CASE WHEN k % 2 = 1 THEN 'DEMO_BD2_YOGA' ELSE 'DEMO_BD2_FORTA' END;
        INSERT INTO public.antrenori_specializari (id_antrenor, id_specializare)
        VALUES (antrenor, specializare) ON CONFLICT DO NOTHING;

        SELECT id_tip, t.pret INTO STRICT tip, pret FROM public.tipuri_abonamente t
        WHERE denumire = CASE WHEN k % 2 = 1 THEN 'DEMO_BD2_LUNAR' ELSE 'DEMO_BD2_TRIMESTRIAL' END;
        inceput := DATE '2026-01-05';
        SELECT inceput + durata_zile INTO STRICT sfarsit
        FROM public.tipuri_abonamente WHERE id_tip = tip;
        -- Intervalul istoric este încheiat; abonamentele sunt expirate.
        INSERT INTO public.abonamente (id_membru, id_tip, data_start, data_sfarsit, status)
        SELECT membru, tip, inceput, sfarsit, 'EXPIRAT'
        WHERE NOT EXISTS (SELECT 1 FROM public.abonamente a
            WHERE a.id_membru = membru AND a.id_tip = tip AND a.data_start = inceput);
        SELECT id_abonament INTO STRICT abonament FROM public.abonamente a
        WHERE a.id_membru = membru AND a.id_tip = tip AND a.data_start = inceput;

        INSERT INTO public.plati (id_abonament, suma, data_plata, metoda_plata, status_plata)
        SELECT abonament, pret, TIMESTAMP '2026-01-05 09:00:00',
               CASE WHEN k % 2 = 1 THEN 'CARD' ELSE 'TRANSFER' END, 'EFECTUATA'
        WHERE NOT EXISTS (SELECT 1 FROM public.plati p
            WHERE p.id_abonament = abonament
              AND p.data_plata = TIMESTAMP '2026-01-05 09:00:00');

        -- Patru clase în zile diferite, fără suprapuneri cu programările.
        moment := TIMESTAMP '2026-01-12 18:00:00' + (k - 1) * INTERVAL '1 day';
        INSERT INTO public.clase_fitness
            (id_antrenor, denumire, data_ora_start, durata_minute, capacitate, descriere)
        SELECT antrenor, format('DEMO_BD2_CLASA_%s', k), moment, 60, 10,
               'Clasă fictivă pentru verificarea relațiilor'
        WHERE NOT EXISTS (SELECT 1 FROM public.clase_fitness c
            WHERE c.denumire = format('DEMO_BD2_CLASA_%s', k)
              AND c.id_antrenor = antrenor AND c.data_ora_start = moment);
        SELECT id_clasa INTO STRICT clasa FROM public.clase_fitness c
        WHERE c.denumire = format('DEMO_BD2_CLASA_%s', k)
          AND c.id_antrenor = antrenor AND c.data_ora_start = moment;

        INSERT INTO public.rezervari_clase (id_membru, id_clasa, data_rezervare, status)
        VALUES (membru, clasa, TIMESTAMP '2026-01-10 10:00:00', 'FINALIZATA')
        ON CONFLICT (id_membru, id_clasa) DO NOTHING;

        INSERT INTO public.programari_personale
            (id_membru, id_antrenor, data_ora_start, durata_minute, status, observatii)
        SELECT membru, antrenor, moment - INTERVAL '2 hours', 60,
               'FINALIZATA', format('DEMO_BD2_PROGRAMARE_%s', k)
        WHERE NOT EXISTS (SELECT 1 FROM public.programari_personale p
            WHERE p.id_membru = membru AND p.id_antrenor = antrenor
              AND p.data_ora_start = moment - INTERVAL '2 hours');

        SELECT id_rol INTO STRICT rol FROM public.roluri WHERE denumire = 'DEMO_BD2_MEMBRU';
        -- Marcaj fără valoare de autentificare; conturile rămân inactive.
        INSERT INTO public.utilizatori
            (username, email, parola_hash, id_rol, id_membru, activ, data_creare)
        SELECT format('demo_bd2_membru%s', k), format('demo.bd2.membru%s@example.com', k),
               '!CONT_DE_TEST_DEZACTIVAT!', rol, membru, false, TIMESTAMP '2026-01-05 08:00:00'
        WHERE NOT EXISTS (SELECT 1 FROM public.utilizatori u
            WHERE u.id_membru = membru OR u.username = format('demo_bd2_membru%s', k)
               OR u.email = format('demo.bd2.membru%s@example.com', k));
    END LOOP;

    FOR k IN 1..2 LOOP
        SELECT id_antrenor INTO STRICT antrenor FROM public.antrenori
        WHERE email = format('demo.bd2.antrenor%s@example.com', k);
        SELECT id_rol INTO STRICT rol FROM public.roluri WHERE denumire = 'DEMO_BD2_ANTRENOR';
        INSERT INTO public.utilizatori
            (username, email, parola_hash, id_rol, id_antrenor, activ, data_creare)
        SELECT format('demo_bd2_antrenor%s', k), format('demo.bd2.antrenor%s@example.com', k),
               '!CONT_DE_TEST_DEZACTIVAT!', rol, antrenor, false, TIMESTAMP '2026-01-05 08:00:00'
        WHERE NOT EXISTS (SELECT 1 FROM public.utilizatori u
            WHERE u.id_antrenor = antrenor OR u.username = format('demo_bd2_antrenor%s', k)
               OR u.email = format('demo.bd2.antrenor%s@example.com', k));
    END LOOP;
END;
$$;
COMMIT;
