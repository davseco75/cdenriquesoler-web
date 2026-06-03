-- ================================================================
--  CD ENRIQUE SOLER · Sistema de Inscripciones Federativas
--  Esquema Supabase · Versión 1.0
--
--  INSTRUCCIONES:
--  1. Ve a tu proyecto Supabase → SQL Editor → New query
--  2. Pega este script completo y pulsa Run
-- ================================================================

-- Extensión UUID (normalmente ya está activa)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── TABLA: players ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.players (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name      TEXT NOT NULL,
  last_name       TEXT NOT NULL,
  birth_date      DATE NOT NULL,
  dni             TEXT,
  category        TEXT NOT NULL,
  address         TEXT,
  phone           TEXT,
  email           TEXT,
  status          TEXT NOT NULL DEFAULT 'pendiente'
                  CHECK (status IN ('pendiente','incompleto','revisado','listo_federacion')),
  submission_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── TABLA: guardians ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guardians (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id    UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  first_name   TEXT NOT NULL,
  last_name    TEXT NOT NULL,
  dni          TEXT NOT NULL,
  phone        TEXT NOT NULL,
  email        TEXT NOT NULL,
  relationship TEXT NOT NULL,
  is_self      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── TABLA: documents ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.documents (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id     UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  type          TEXT NOT NULL
                CHECK (type IN ('dni_front','dni_back','medical','photo','signature')),
  storage_path  TEXT NOT NULL,
  original_name TEXT,
  file_size     BIGINT,
  mime_type     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── TABLA: consents ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.consents (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id        UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  consent_text     TEXT NOT NULL,
  consent_version  TEXT NOT NULL DEFAULT '1.0',
  guardian_name    TEXT NOT NULL,
  guardian_dni     TEXT NOT NULL,
  accepted_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_agent       TEXT
);

-- ── TABLA: admin_notes ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id  UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
  note       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── ÍNDICES ─────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_players_status   ON public.players(status);
CREATE INDEX IF NOT EXISTS idx_players_category ON public.players(category);
CREATE INDEX IF NOT EXISTS idx_guardians_player ON public.guardians(player_id);
CREATE INDEX IF NOT EXISTS idx_documents_player ON public.documents(player_id);
CREATE INDEX IF NOT EXISTS idx_consents_player  ON public.consents(player_id);
CREATE INDEX IF NOT EXISTS idx_notes_player     ON public.admin_notes(player_id);

-- ── TRIGGER: updated_at automático ──────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER players_updated_at
  BEFORE UPDATE ON public.players
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── ROW LEVEL SECURITY ──────────────────────────────────────────
ALTER TABLE public.players     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardians   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consents    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notes ENABLE ROW LEVEL SECURITY;

-- Usuarios anónimos (padres enviando el formulario): solo pueden insertar
CREATE POLICY "anon_insert_players"   ON public.players   FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_insert_guardians" ON public.guardians FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_insert_documents" ON public.documents FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_insert_consents"  ON public.consents  FOR INSERT TO anon WITH CHECK (true);

-- Usuarios autenticados (admin): acceso completo a todo
CREATE POLICY "auth_all_players"   ON public.players     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_guardians" ON public.guardians   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_documents" ON public.documents   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_consents"  ON public.consents    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_notes"     ON public.admin_notes FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ================================================================
--  STORAGE (ejecutar por separado en SQL Editor o desde Dashboard)
-- ================================================================
--
--  1. En Supabase Dashboard → Storage → New bucket
--     Nombre: inscriptions
--     Public: OFF (bucket privado)
--
--  2. En SQL Editor, ejecuta las siguientes políticas de storage:

INSERT INTO storage.buckets (id, name, public)
VALUES ('inscriptions', 'inscriptions', false)
ON CONFLICT (id) DO NOTHING;

-- Cualquier visitante (padre) puede subir archivos (INSERT)
CREATE POLICY "anon_upload_docs"
  ON storage.objects FOR INSERT TO anon
  WITH CHECK (bucket_id = 'inscriptions');

-- Solo el admin autenticado puede leer y eliminar
CREATE POLICY "auth_read_docs"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'inscriptions');

CREATE POLICY "auth_delete_docs"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'inscriptions');

-- ================================================================
--  CREAR USUARIO ADMINISTRADOR
-- ================================================================
--
--  1. En Supabase Dashboard → Authentication → Users → Add user
--  2. Introduce el email y contraseña del administrador del club
--  3. Confirma el email si es necesario
--  4. Ese usuario ya puede hacer login en /admin/inscripciones
--
-- ================================================================
