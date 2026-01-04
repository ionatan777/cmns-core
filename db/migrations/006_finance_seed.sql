-- =====================================================
-- CMNS CORE - 006: Seed Data (Finanzas)
-- Fase 2: Datos Iniciales para Módulo Financiero
-- =====================================================

-- =====================================================
-- 1. FONDOS INICIALES
-- =====================================================

-- Universidad (Meta: $3000 para Marzo 2026)
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES (
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000001',
  'Universidad',
  'Fondo para matrícula universitaria (meta marzo 2026)',
  3000.00,
  '2026-03-01',
  '#10b981',  -- Verde
  false
);

-- Deuda (Meta: $2500 para liquidar)
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES (
  '00000000-0000-0000-0000-000000000102',
  '00000000-0000-0000-0000-000000000001',
  'Deuda',
  'Fondo para liquidación de deudas pendientes',
  2500.00,
  NULL,
  '#ef4444',  -- Rojo
  false
);

-- Reposición Camvys (Tope mensual: $115)
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES (
  '00000000-0000-0000-0000-000000000103',
  '00000000-0000-0000-0000-000000000001',
  'Reposición Camvys',
  'Fondo para reposición de inventario Camvys (tope mensual: $115)',
  NULL,
  NULL,
  '#f59e0b',  -- Naranja
  false
);

-- Marketing
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES (
  '00000000-0000-0000-0000-000000000104',
  '00000000-0000-0000-0000-000000000001',
  'Marketing',
  'Fondo para inversión en publicidad y marketing',
  NULL,
  NULL,
  '#8b5cf6',  -- Violeta
  false
);

-- Carros
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES (
  '00000000-0000-0000-0000-000000000105',
  '00000000-0000-0000-0000-000000000001',
  'Carros',
  'Fondo para mantenimiento y gastos de vehículos',
  NULL,
  NULL,
  '#06b6d4',  -- Cyan
  false
);

-- Caja Libre
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES (
  '00000000-0000-0000-0000-000000000106',
  '00000000-0000-0000-0000-000000000001',
  'Caja Libre',
  'Fondos no asignados disponibles para uso general',
  NULL,
  NULL,
  '#64748b',  -- Gris
  false
);

-- =====================================================
-- 2. CUENTAS INICIALES (Opcional - para testing)
-- =====================================================

-- Banco Principal
INSERT INTO accounts (id, organization_id, brand_id, name, type, currency, balance, bank_name)
VALUES (
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000001',
  NULL,  -- Cuenta general (no específica de marca)
  'Banco Principal',
  'bank',
  'USD',
  0.00,
  'Banco Nacional'
);

-- Efectivo
INSERT INTO accounts (id, organization_id, brand_id, name, type, currency, balance)
VALUES (
  '00000000-0000-0000-0000-000000000202',
  '00000000-0000-0000-0000-000000000001',
  NULL,
  'Efectivo',
  'cash',
  'USD',
  0.00
);

-- Banco Camvys (específico para e-commerce)
INSERT INTO accounts (id, organization_id, brand_id, name, type, currency, balance, bank_name)
VALUES (
  '00000000-0000-0000-0000-000000000203',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000011',  -- Camvys brand_id
  'Banco Camvys',
  'bank',
  'USD',
  0.00,
  'Banco Nacional'
);

-- =====================================================
-- 3. REGLAS DE ASIGNACIÓN DEFAULT
-- =====================================================

-- REGLA 1: Ingresos de CodelyLabs (Venta Landing)
-- 40% Universidad, 20% Deuda, 40% Caja Libre
INSERT INTO allocation_rules (
  id,
  organization_id,
  brand_id,
  category,
  tx_type,
  split_config,
  active,
  description
)
VALUES (
  '00000000-0000-0000-0000-000000000301',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000012',  -- CodelyLabs
  'Venta Landing',
  'income',
  '[
    {"fund_id": "00000000-0000-0000-0000-000000000101", "percentage": 40},
    {"fund_id": "00000000-0000-0000-0000-000000000102", "percentage": 20},
    {"fund_id": "00000000-0000-0000-0000-000000000106", "percentage": 40}
  ]'::jsonb,
  true,
  'Distribución default para ventas de landings CodelyLabs'
);

-- REGLA 2: Ingresos de Camvys (Ventas E-commerce)
-- 30% Universidad, 15% Deuda, 25% Reposición, 30% Caja Libre
INSERT INTO allocation_rules (
  id,
  organization_id,
  brand_id,
  category,
  tx_type,
  split_config,
  active,
  description
)
VALUES (
  '00000000-0000-0000-0000-000000000302',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000011',  -- Camvys
  NULL,  -- Aplica a todas las categorías de Camvys
  'income',
  '[
    {"fund_id": "00000000-0000-0000-0000-000000000101", "percentage": 30},
    {"fund_id": "00000000-0000-0000-0000-000000000102", "percentage": 15},
    {"fund_id": "00000000-0000-0000-0000-000000000103", "percentage": 25},
    {"fund_id": "00000000-0000-0000-0000-000000000106", "percentage": 30}
  ]'::jsonb,
  true,
  'Distribución default para ingresos de Camvys (incluye reposición)'
);

-- REGLA 3: Gastos de Marketing (cualquier marca)
-- 100% al fondo de Marketing
INSERT INTO allocation_rules (
  id,
  organization_id,
  brand_id,
  category,
  tx_type,
  split_config,
  active,
  description
)
VALUES (
  '00000000-0000-0000-0000-000000000303',
  '00000000-0000-0000-0000-000000000001',
  NULL,  -- Aplica a todas las marcas
  'Marketing',
  'expense',
  '[
    {"fund_id": "00000000-0000-0000-0000-000000000104", "percentage": 100}
  ]'::jsonb,
  true,
  'Gastos de marketing se asignan al fondo de Marketing'
);

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================
-- Datos de ejemplo creados:
-- 
-- FONDOS (6):
-- - Universidad ($3000 meta para marzo 2026)
-- - Deuda ($2500 meta)
-- - Reposición Camvys (tope mensual $115)
-- - Marketing
-- - Carros
-- - Caja Libre
-- 
-- CUENTAS (3):
-- - Banco Principal (general)
-- - Efectivo (general)
-- - Banco Camvys (específico de marca)
-- 
-- REGLAS DE ASIGNACIÓN (3):
-- - CodelyLabs Landings: 40% Uni / 20% Deuda / 40% Libre
-- - Camvys General: 30% Uni / 15% Deuda / 25% Repo / 30% Libre
-- - Marketing: 100% Fondo Marketing
-- 
-- PRÓXIMO PASO:
-- Crear transacciones de prueba para verificar que las reglas funcionan
