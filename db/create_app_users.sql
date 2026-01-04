-- =====================================================
-- TABLA DE USUARIOS DE LA APLICACIÓN
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- Crear tabla de usuarios de la app (independiente de Supabase Auth)
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT DEFAULT '',
    role TEXT DEFAULT 'user' CHECK (role IN ('owner', 'admin', 'user')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    avatar_url TEXT,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);
CREATE INDEX IF NOT EXISTS idx_app_users_role ON app_users(role);
CREATE INDEX IF NOT EXISTS idx_app_users_status ON app_users(status);

-- Habilitar RLS
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura pública (temporalmente)
CREATE POLICY "Allow public read" ON app_users FOR SELECT USING (true);

-- Política para permitir inserción pública (temporalmente) 
CREATE POLICY "Allow public insert" ON app_users FOR INSERT WITH CHECK (true);

-- Política para permitir actualización pública (temporalmente)
CREATE POLICY "Allow public update" ON app_users FOR UPDATE USING (true);

-- Crear usuario administrador por defecto
INSERT INTO app_users (email, password_hash, name, role, status)
VALUES (
    'codelylabs.tech@yahoo.com',
    'bWF5YTIwMjYu', -- maya2026. en base64
    'CodelyLabs Admin',
    'owner',
    'active'
) ON CONFLICT (email) DO NOTHING;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Tabla app_users creada exitosamente';
    RAISE NOTICE '✅ Usuario admin creado: codelylabs.tech@yahoo.com';
END $$;
