-- =====================================================
-- CMNS CORE - 009: CRM Seed Data
-- Fase 3 (Semana 2): Pipelines y Stages Default
-- =====================================================

-- =====================================================
-- PIPELINE DEFAULT: CodelyLabs - Ventas de Landings
-- =====================================================
INSERT INTO pipelines (id, organization_id, brand_id, name)
VALUES (
  '00000000-0000-0000-0000-000000000401',
  '00000000-0000-0000-0000-000000000001',  -- GRUPO CMNS
  '00000000-0000-0000-0000-000000000012',  -- CodelyLabs
  'Ventas de Landings'
);

-- Stages del pipeline CodelyLabs
INSERT INTO pipeline_stages (id, pipeline_id, name, order_num, color) VALUES
  ('00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000401', 'Lead Nuevo', 1, '#94a3b8'),
  ('00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000401', 'Prospectado', 2, '#3b82f6'),
  ('00000000-0000-0000-0000-000000000413', '00000000-0000-0000-0000-000000000401', 'Propuesta Enviada', 3, '#f59e0b'),
  ('00000000-0000-0000-0000-000000000414', '00000000-0000-0000-0000-000000000401', 'Negociación', 4, '#8b5cf6'),
  ('00000000-0000-0000-0000-000000000415', '00000000-0000-0000-0000-000000000401', 'Ganado', 5, '#10b981'),
  ('00000000-0000-0000-0000-000000000416', '00000000-0000-0000-0000-000000000401', 'Perdido', 6, '#ef4444');

-- =====================================================
-- PIPELINE DEFAULT: Camvys - Ventas E-commerce
-- =====================================================
INSERT INTO pipelines (id, organization_id, brand_id, name)
VALUES (
  '00000000-0000-0000-0000-000000000402',
  '00000000-0000-0000-0000-000000000001',  -- GRUPO CMNS
  '00000000-0000-0000-0000-000000000011',  -- Camvys
  'Ventas de Productos'
);

-- Stages del pipeline Camvys
INSERT INTO pipeline_stages (id, pipeline_id, name, order_num, color) VALUES
  ('00000000-0000-0000-0000-000000000421', '00000000-0000-0000-0000-000000000402', 'Contacto Inicial', 1, '#94a3b8'),
  ('00000000-0000-0000-0000-000000000422', '00000000-0000-0000-0000-000000000402', 'Cotización', 2, '#3b82f6'),
  ('00000000-0000-0000-0000-000000000423', '00000000-0000-0000-0000-000000000402', 'Pedido', 3, '#f59e0b'),
  ('00000000-0000-0000-0000-000000000424', '00000000-0000-0000-0000-000000000402', 'Pagado', 4, '#10b981'),
  ('00000000-0000-0000-0000-000000000425', '00000000-0000-0000-0000-000000000402', 'Cancelado', 5, '#ef4444');

-- =====================================================
-- CONTACTOS DE EJEMPLO (Opcional - para testing)
-- =====================================================
-- Descomentar para crear contactos de prueba:

/*
INSERT INTO contacts (id, organization_id, name, phone, business_name, city, tags, source)
VALUES
  (
    '00000000-0000-0000-0000-000000000501',
    '00000000-0000-0000-0000-000000000001',
    'Juan Pérez',
    '+593987654321',
    'Restaurante El Buen Sabor',
    'Quito',
    '["restaurante", "delivery"]'::jsonb,
    'maps'
  ),
  (
    '00000000-0000-0000-0000-000000000502',
    '00000000-0000-0000-0000-000000000001',
    'María García',
    '+593912345678',
    'Boutique Fashion',
    'Guayaquil',
    '["retail", "moda"]'::jsonb,
    'tiktok'
  ),
  (
    '00000000-0000-0000-0000-000000000503',
    '00000000-0000-0000-0000-000000000001',
    'Carlos Rodríguez',
    '+593998877665',
    'Gym FitLife',
    'Cuenca',
    '["gym", "wellness"]'::jsonb,
    'referral'
  );

-- LEADS DE EJEMPLO
INSERT INTO leads (id, organization_id, brand_id, contact_id, product, value_estimated, stage_id, status, created_by)
VALUES
  (
    '00000000-0000-0000-0000-000000000601',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000012',  -- CodelyLabs
    '00000000-0000-0000-0000-000000000501',
    'Landing Page + Hosting 1 año',
    350.00,
    '00000000-0000-0000-0000-000000000412',  -- Prospectado
    'active',
    (SELECT id FROM auth.users LIMIT 1)
  ),
  (
    '00000000-0000-0000-0000-000000000602',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000012',  -- CodelyLabs
    '00000000-0000-0000-0000-000000000502',
    'Landing + Catálogo Digital',
    450.00,
    '00000000-0000-0000-0000-000000000413',  -- Propuesta Enviada
    'active',
    (SELECT id FROM auth.users LIMIT 1)
  );
*/

-- ✅ COMPLETADO! Pipelines default configurados para CodelyLabs y Camvys.
