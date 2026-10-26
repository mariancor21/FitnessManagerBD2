-- public.antrenori definition

-- Drop table

-- DROP TABLE public.antrenori;

CREATE TABLE public.antrenori (
	id_antrenor int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nume varchar(50) NOT NULL,
	prenume varchar(50) NOT NULL,
	email varchar(100) NOT NULL,
	telefon varchar(20) NULL,
	data_angajare date DEFAULT CURRENT_DATE NOT NULL,
	salariu numeric(10, 2) NULL,
	CONSTRAINT antrenori_email_key UNIQUE (email),
	CONSTRAINT antrenori_pkey PRIMARY KEY (id_antrenor),
	CONSTRAINT antrenori_salariu_check CHECK ((salariu >= (0)::numeric))
);


-- public.membri definition

-- Drop table

-- DROP TABLE public.membri;

CREATE TABLE public.membri (
	id_membru int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nume varchar(50) NOT NULL,
	prenume varchar(50) NOT NULL,
	email varchar(100) NOT NULL,
	telefon varchar(20) NULL,
	data_nasterii date NULL,
	data_inscriere date DEFAULT CURRENT_DATE NOT NULL,
	CONSTRAINT membri_email_key UNIQUE (email),
	CONSTRAINT membri_pkey PRIMARY KEY (id_membru)
);


-- public.roluri definition

-- Drop table

-- DROP TABLE public.roluri;

CREATE TABLE public.roluri (
	id_rol int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	denumire varchar(30) NOT NULL,
	descriere text NULL,
	CONSTRAINT roluri_denumire_key UNIQUE (denumire),
	CONSTRAINT roluri_pkey PRIMARY KEY (id_rol)
);


-- public.specializari definition

-- Drop table

-- DROP TABLE public.specializari;

CREATE TABLE public.specializari (
	id_specializare int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	denumire varchar(100) NOT NULL,
	descriere text NULL,
	CONSTRAINT specializari_denumire_key UNIQUE (denumire),
	CONSTRAINT specializari_pkey PRIMARY KEY (id_specializare)
);


-- public.tipuri_abonamente definition

-- Drop table

-- DROP TABLE public.tipuri_abonamente;

CREATE TABLE public.tipuri_abonamente (
	id_tip int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	denumire varchar(50) NOT NULL,
	durata_zile int4 NOT NULL,
	pret numeric(10, 2) NOT NULL,
	descriere text NULL,
	CONSTRAINT tipuri_abonamente_denumire_key UNIQUE (denumire),
	CONSTRAINT tipuri_abonamente_durata_zile_check CHECK ((durata_zile > 0)),
	CONSTRAINT tipuri_abonamente_pkey PRIMARY KEY (id_tip),
	CONSTRAINT tipuri_abonamente_pret_check CHECK ((pret >= (0)::numeric))
);


-- public.abonamente definition

-- Drop table

-- DROP TABLE public.abonamente;

CREATE TABLE public.abonamente (
	id_abonament int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_membru int4 NOT NULL,
	id_tip int4 NOT NULL,
	data_start date NOT NULL,
	data_sfarsit date NOT NULL,
	status varchar(20) DEFAULT 'ACTIV'::character varying NOT NULL,
	CONSTRAINT abonamente_pkey PRIMARY KEY (id_abonament),
	CONSTRAINT ck_abonament_date CHECK ((data_sfarsit > data_start)),
	CONSTRAINT ck_abonament_status CHECK (((status)::text = ANY ((ARRAY['ACTIV'::character varying, 'EXPIRAT'::character varying, 'SUSPENDAT'::character varying, 'ANULAT'::character varying])::text[]))),
	CONSTRAINT fk_abonament_membru FOREIGN KEY (id_membru) REFERENCES public.membri(id_membru),
	CONSTRAINT fk_abonament_tip FOREIGN KEY (id_tip) REFERENCES public.tipuri_abonamente(id_tip)
);


-- public.antrenori_specializari definition

-- Drop table

-- DROP TABLE public.antrenori_specializari;

CREATE TABLE public.antrenori_specializari (
	id_antrenor int4 NOT NULL,
	id_specializare int4 NOT NULL,
	CONSTRAINT antrenori_specializari_pkey PRIMARY KEY (id_antrenor, id_specializare),
	CONSTRAINT fk_as_antrenor FOREIGN KEY (id_antrenor) REFERENCES public.antrenori(id_antrenor),
	CONSTRAINT fk_as_specializare FOREIGN KEY (id_specializare) REFERENCES public.specializari(id_specializare)
);


-- public.clase_fitness definition

-- Drop table

-- DROP TABLE public.clase_fitness;

CREATE TABLE public.clase_fitness (
	id_clasa int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_antrenor int4 NOT NULL,
	denumire varchar(100) NOT NULL,
	data_ora_start timestamp NOT NULL,
	durata_minute int4 NOT NULL,
	capacitate int4 NOT NULL,
	descriere text NULL,
	CONSTRAINT clase_fitness_capacitate_check CHECK ((capacitate > 0)),
	CONSTRAINT clase_fitness_durata_minute_check CHECK ((durata_minute > 0)),
	CONSTRAINT clase_fitness_pkey PRIMARY KEY (id_clasa),
	CONSTRAINT fk_clasa_antrenor FOREIGN KEY (id_antrenor) REFERENCES public.antrenori(id_antrenor)
);


-- public.plati definition

-- Drop table

-- DROP TABLE public.plati;

CREATE TABLE public.plati (
	id_plata int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_abonament int4 NOT NULL,
	suma numeric(10, 2) NOT NULL,
	data_plata timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	metoda_plata varchar(20) NOT NULL,
	status_plata varchar(20) DEFAULT 'EFECTUATA'::character varying NOT NULL,
	CONSTRAINT ck_metoda_plata CHECK (((metoda_plata)::text = ANY ((ARRAY['CASH'::character varying, 'CARD'::character varying, 'TRANSFER'::character varying])::text[]))),
	CONSTRAINT ck_status_plata CHECK (((status_plata)::text = ANY ((ARRAY['EFECTUATA'::character varying, 'IN_ASTEPTARE'::character varying, 'RESPINSA'::character varying])::text[]))),
	CONSTRAINT plati_pkey PRIMARY KEY (id_plata),
	CONSTRAINT plati_suma_check CHECK ((suma > (0)::numeric)),
	CONSTRAINT fk_plata_abonament FOREIGN KEY (id_abonament) REFERENCES public.abonamente(id_abonament)
);


-- public.programari_personale definition

-- Drop table

-- DROP TABLE public.programari_personale;

CREATE TABLE public.programari_personale (
	id_programare int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_membru int4 NOT NULL,
	id_antrenor int4 NOT NULL,
	data_ora_start timestamp NOT NULL,
	durata_minute int4 DEFAULT 60 NOT NULL,
	status varchar(20) DEFAULT 'PROGRAMATA'::character varying NOT NULL,
	observatii text NULL,
	CONSTRAINT ck_programare_status CHECK (((status)::text = ANY ((ARRAY['PROGRAMATA'::character varying, 'FINALIZATA'::character varying, 'ANULATA'::character varying])::text[]))),
	CONSTRAINT programari_personale_durata_minute_check CHECK ((durata_minute > 0)),
	CONSTRAINT programari_personale_pkey PRIMARY KEY (id_programare),
	CONSTRAINT fk_programare_antrenor FOREIGN KEY (id_antrenor) REFERENCES public.antrenori(id_antrenor),
	CONSTRAINT fk_programare_membru FOREIGN KEY (id_membru) REFERENCES public.membri(id_membru)
);


-- public.rezervari_clase definition

-- Drop table

-- DROP TABLE public.rezervari_clase;

CREATE TABLE public.rezervari_clase (
	id_rezervare int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_membru int4 NOT NULL,
	id_clasa int4 NOT NULL,
	data_rezervare timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	status varchar(20) DEFAULT 'CONFIRMATA'::character varying NOT NULL,
	CONSTRAINT ck_rezervare_status CHECK (((status)::text = ANY ((ARRAY['CONFIRMATA'::character varying, 'ANULATA'::character varying, 'FINALIZATA'::character varying])::text[]))),
	CONSTRAINT rezervari_clase_pkey PRIMARY KEY (id_rezervare),
	CONSTRAINT uq_rezervare UNIQUE (id_membru, id_clasa),
	CONSTRAINT fk_rezervare_clasa FOREIGN KEY (id_clasa) REFERENCES public.clase_fitness(id_clasa),
	CONSTRAINT fk_rezervare_membru FOREIGN KEY (id_membru) REFERENCES public.membri(id_membru)
);


-- public.utilizatori definition

-- Drop table

-- DROP TABLE public.utilizatori;

CREATE TABLE public.utilizatori (
	id_utilizator int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	username varchar(50) NOT NULL,
	email varchar(100) NOT NULL,
	parola_hash text NOT NULL,
	id_rol int4 NOT NULL,
	id_membru int4 NULL,
	id_antrenor int4 NULL,
	activ bool DEFAULT true NOT NULL,
	data_creare timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT ck_utilizator_profil CHECK (((id_membru IS NULL) OR (id_antrenor IS NULL))),
	CONSTRAINT utilizatori_email_key UNIQUE (email),
	CONSTRAINT utilizatori_id_antrenor_key UNIQUE (id_antrenor),
	CONSTRAINT utilizatori_id_membru_key UNIQUE (id_membru),
	CONSTRAINT utilizatori_pkey PRIMARY KEY (id_utilizator),
	CONSTRAINT utilizatori_username_key UNIQUE (username),
	CONSTRAINT fk_utilizator_antrenor FOREIGN KEY (id_antrenor) REFERENCES public.antrenori(id_antrenor),
	CONSTRAINT fk_utilizator_membru FOREIGN KEY (id_membru) REFERENCES public.membri(id_membru),
	CONSTRAINT fk_utilizator_rol FOREIGN KEY (id_rol) REFERENCES public.roluri(id_rol)
);