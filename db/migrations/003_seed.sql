-- =====================================================
-- CMNS CORE - 003: Seed Data
-- Fase 1 (Semana 1): Datos Iniciales
-- =====================================================

-- =====================================================
-- 1. ORGANIZACIÓN: GRUPO CMNS
-- =====================================================
INSERT INTO organizations (id, name, slug, timezone, base_currency, primary_color, secondary_color)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'GRUPO CMNS',
  'grupo-cmns',
  'America/New_York',
  'USD',
  '#1a1a1a',  -- Color principal (negro/gris oscuro)
  '#ffffff'   -- Color secundario (blanco)
);

-- =====================================================
-- 2. MARCAS (Camvys, CodelyLabs, Zypher)
-- =====================================================
INSERT INTO brands (id, organization_id, name, status, description, channels_enabled)
VALUES
  -- Camvys (E-commerce de productos)
  (
    '00000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000001',
    'camvys',
    'active',
    'E-commerce de productos (inventario, órdenes, SKUs)',
    '{"web": true, "email": true, "phone": true, "whatsapp": true}'::jsonb
  ),
  
  -- CodelyLabs (Desarrollo de software)
  (
    '00000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000001',
    'codelylabs',
    'active',
    'Desarrollo de software y landings (proyectos, mantenimiento)',
    '{"web": true, "email": true, "phone": true, "whatsapp": true}'::jsonb
  ),
  
  -- Zypher (Marca secundaria de productos)
  (
    '00000000-0000-0000-0000-000000000013',
    '00000000-0000-0000-0000-000000000001',
    'zypher',
    'active',
    'Marca secundaria de productos (línea alternativa)',
    '{"web": true, "email": true, "whatsapp": true}'::jsonb
  );

-- =====================================================
-- 3. MEMBERSHIP: Usuario Owner
-- =====================================================
-- IMPORTANTE: Reemplaza 'YOUR_USER_ID_HERE' con el UUID de tu usuario
-- después de crear tu cuenta en Supabase Auth.
-- 
-- Para obtener tu user_id:
-- 1. Ir a Supabase → Authentication → Users
-- 2. Copiar el UUID de tu usuario
-- 3. Ejecutar:
--
-- INSERT INTO memberships (organization_id, user_id, role)
-- VALUES (
--   '00000000-0000-0000-0000-000000000001',
--   'TU_USER_ID_AQUI',  -- <-- Reemplazar con tu UUID
--   'owner'
-- );

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================
-- Datos de ejemplo creados:
-- - 1 Organización: GRUPO CMNS
-- - 3 Marcas: Camvys, CodelyLabs, Zypher
-- 
-- PRÓXIMO PASO:
-- Crear usuario en Supabase Auth y ejecutar el INSERT de membership
-- con tu user_id para tener acceso como owner.
