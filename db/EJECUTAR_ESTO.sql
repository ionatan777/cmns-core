-- =====================================================
-- CMNS CORE - MIGRACIONES COMPLETAS (Corregidas)
-- Ejecuta esto en Supabase SQL Editor
-- =====================================================

-- =====================================================
-- PARTE 1: RLS PARA FINANZAS (005)
-- =====================================================

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE allocation_rules ENABLE ROW LEVEL SECURITY;

-- ACCOUNTS
CREATE POLICY "Users can view accounts in their organization"
  ON accounts FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Owners, admins and ops can create accounts"
  ON accounts FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = accounts.organization_id
      AND role IN ('owner', 'admin', 'ops')
    )
  );

CREATE POLICY "Owners, admins and ops can update accounts"
  ON accounts FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = accounts.organization_id
      AND role IN ('owner', 'admin', 'ops')
    )
  );

CREATE POLICY "Owners and admins can delete accounts"
  ON accounts FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = accounts.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- FUNDS
CREATE POLICY "Users can view funds in their organization"
  ON funds FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Owners and admins can create funds"
  ON funds FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = funds.organization_id
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners and admins can update funds"
  ON funds FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = funds.organization_id
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners can delete funds"
  ON funds FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = funds.organization_id
      AND role = 'owner'
    )
  );

-- TRANSACTIONS
CREATE POLICY "Users can view transactions in their organization"
  ON transactions FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Users can create transactions in their organization"
  ON transactions FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Creator, owners and admins can update transactions"
  ON transactions FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND (
      created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM memberships
        WHERE user_id = auth.uid()
        AND organization_id = transactions.organization_id
        AND role IN ('owner', 'admin')
      )
    )
  );

CREATE POLICY "Only owners can delete transactions"
  ON transactions FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = transactions.organization_id
      AND role = 'owner'
    )
  );

-- TRANSACTION_SPLITS
CREATE POLICY "Users can view transaction splits in their organization"
  ON transaction_splits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM transactions
      WHERE transactions.id = transaction_splits.transaction_id
      AND transactions.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    )
  );

CREATE POLICY "Allow insert of splits via function"
  ON transaction_splits FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM transactions
      WHERE transactions.id = transaction_splits.transaction_id
      AND transactions.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    )
  );

-- ALLOCATION_RULES
CREATE POLICY "Users can view allocation rules in their organization"
  ON allocation_rules FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Owners and admins can create allocation rules"
  ON allocation_rules FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = allocation_rules.organization_id
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners and admins can update allocation rules"
  ON allocation_rules FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = allocation_rules.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- =====================================================
-- PARTE 2: SEED DATA FINANZAS (006)
-- =====================================================

-- FONDOS
INSERT INTO funds (id, organization_id, name, description, goal_amount, goal_date, color, locked)
VALUES
  ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'Universidad', 'Fondo para matrícula universitaria (meta marzo 2026)', 3000.00, '2026-03-01', '#10b981', false),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001', 'Deuda', 'Fondo para liquidación de deudas pendientes', 2500.00, NULL, '#ef4444', false),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001', 'Reposición Camvys', 'Fondo para reposición de inventario Camvys (tope mensual: $115)', NULL, NULL, '#f59e0b', false),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001', 'Marketing', 'Fondo para inversión en publicidad y marketing', NULL, NULL, '#8b5cf6', false),
  ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000001', 'Carros', 'Fondo para mantenimiento y gastos de vehículos', NULL, NULL, '#06b6d4', false),
  ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000001', 'Caja Libre', 'Fondos no asignados disponibles para uso general', NULL, NULL, '#64748b', false);

-- CUENTAS
INSERT INTO accounts (id, organization_id, brand_id, name, type, currency, balance, bank_name)
VALUES
  ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', NULL, 'Banco Principal', 'bank', 'USD', 0.00, 'Banco Nacional'),
  ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000001', NULL, 'Efectivo', 'cash', 'USD', 0.00, NULL),
  ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000011', 'Banco Camvys', 'bank', 'USD', 0.00, 'Banco Nacional');

-- REGLAS DE ASIGNACIÓN
INSERT INTO allocation_rules (id, organization_id, brand_id, category, tx_type, split_config, active, description)
VALUES
  ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 'Venta Landing', 'income',
   '[{"fund_id": "00000000-0000-0000-0000-000000000101", "percentage": 40}, {"fund_id": "00000000-0000-0000-0000-000000000102", "percentage": 20}, {"fund_id": "00000000-0000-0000-0000-000000000106", "percentage": 40}]'::jsonb,
   true, 'Distribución default para ventas de landings CodelyLabs'),
  
  ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000011', NULL, 'income',
   '[{"fund_id": "00000000-0000-0000-0000-000000000101", "percentage": 30}, {"fund_id": "00000000-0000-0000-0000-000000000102", "percentage": 15}, {"fund_id": "00000000-0000-0000-0000-000000000103", "percentage": 25}, {"fund_id": "00000000-0000-0000-0000-000000000106", "percentage": 30}]'::jsonb,
   true, 'Distribución default para ingresos de Camvys (incluye reposición)'),
  
  ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000001', NULL, 'Marketing', 'expense',
   '[{"fund_id": "00000000-0000-0000-0000-000000000104", "percentage": 100}]'::jsonb,
   true, 'Gastos de marketing se asignan al fondo de Marketing');

-- ✅ COMPLETADO! Todas las políticas RLS y datos iniciales creados.
