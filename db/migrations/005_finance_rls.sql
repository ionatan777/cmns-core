-- =====================================================
-- CMNS CORE - 005: Row Level Security (Finanzas)
-- Fase 2: Políticas de Seguridad para Módulo Financiero
-- =====================================================

-- =====================================================
-- ACTIVAR RLS EN TODAS LAS TABLAS DE FINANZAS
-- =====================================================
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE allocation_rules ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS: ACCOUNTS
-- =====================================================

-- Los usuarios pueden ver cuentas de su organización
CREATE POLICY "Users can view accounts in their organization"
  ON accounts FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Owners, admins y ops pueden crear cuentas
CREATE POLICY "Owners, admins and ops can create accounts"
  ON accounts FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = accounts.organization_id
      AND role IN ('owner', 'admin', 'ops')
    )
  );

-- Owners, admins y ops pueden actualizar cuentas
CREATE POLICY "Owners, admins and ops can update accounts"
  ON accounts FOR UPDATE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = accounts.organization_id
      AND role IN ('owner', 'admin', 'ops')
    )
  );

-- Solo owners y admins pueden eliminar cuentas
CREATE POLICY "Owners and admins can delete accounts"
  ON accounts FOR DELETE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = accounts.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- =====================================================
-- POLÍTICAS: FUNDS
-- =====================================================

-- Los usuarios pueden ver fondos de su organización
CREATE POLICY "Users can view funds in their organization"
  ON funds FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Owners y admins pueden crear fondos
CREATE POLICY "Owners and admins can create funds"
  ON funds FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = funds.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- Owners y admins pueden actualizar fondos
CREATE POLICY "Owners and admins can update funds"
  ON funds FOR UPDATE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = funds.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- Solo owners pueden eliminar fondos
CREATE POLICY "Owners can delete funds"
  ON funds FOR DELETE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = funds.organization_id
      AND role = 'owner'
    )
  );

-- =====================================================
-- POLÍTICAS: TRANSACTIONS
-- =====================================================

-- Los usuarios pueden ver transacciones de su organización
CREATE POLICY "Users can view transactions in their organization"
  ON transactions FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Todos los usuarios autenticados pueden crear transacciones
-- (la función create_transaction() maneja la lógica)
CREATE POLICY "Users can create transactions in their organization"
  ON transactions FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
  );

-- Solo el creador, owners y admins pueden actualizar transacciones
-- IMPORTANTE: En producción, considera NO permitir ediciones, solo reversos
CREATE POLICY "Creator, owners and admins can update transactions"
  ON transactions FOR UPDATE
  USING (
    organization_id = auth.user_organization_id()
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

-- Solo owners pueden eliminar transacciones
-- IMPORTANTE: En producción, considera NO permitir deletes, solo reversos
CREATE POLICY "Only owners can delete transactions"
  ON transactions FOR DELETE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = transactions.organization_id
      AND role = 'owner'
    )
  );

-- =====================================================
-- POLÍTICAS: TRANSACTION_SPLITS
-- =====================================================

-- Los usuarios pueden ver splits de transacciones de su organización
CREATE POLICY "Users can view transaction splits in their organization"
  ON transaction_splits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM transactions
      WHERE transactions.id = transaction_splits.transaction_id
      AND transactions.organization_id = auth.user_organization_id()
    )
  );

-- La creación de splits se maneja desde create_transaction()
CREATE POLICY "Allow insert of splits via function"
  ON transaction_splits FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM transactions
      WHERE transactions.id = transaction_splits.transaction_id
      AND transactions.organization_id = auth.user_organization_id()
    )
  );

-- Solo owners y admins pueden actualizar splits
CREATE POLICY "Owners and admins can update splits"
  ON transaction_splits FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN memberships m ON m.organization_id = t.organization_id
      WHERE t.id = transaction_splits.transaction_id
      AND m.user_id = auth.uid()
      AND m.role IN ('owner', 'admin')
    )
  );

-- Solo owners pueden eliminar splits
CREATE POLICY "Only owners can delete splits"
  ON transaction_splits FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN memberships m ON m.organization_id = t.organization_id
      WHERE t.id = transaction_splits.transaction_id
      AND m.user_id = auth.uid()
      AND m.role = 'owner'
    )
  );

-- =====================================================
-- POLÍTICAS: ALLOCATION_RULES
-- =====================================================

-- Los usuarios pueden ver reglas de su organización
CREATE POLICY "Users can view allocation rules in their organization"
  ON allocation_rules FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Owners y admins pueden crear reglas
CREATE POLICY "Owners and admins can create allocation rules"
  ON allocation_rules FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = allocation_rules.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- Owners y admins pueden actualizar reglas
CREATE POLICY "Owners and admins can update allocation rules"
  ON allocation_rules FOR UPDATE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = allocation_rules.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- Solo owners pueden eliminar reglas
CREATE POLICY "Only owners can delete allocation rules"
  ON allocation_rules FOR DELETE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = allocation_rules.organization_id
      AND role = 'owner'
    )
  );

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON POLICY "Users can view accounts in their organization" ON accounts 
  IS 'Los usuarios pueden ver todas las cuentas de su organización';
COMMENT ON POLICY "Users can view funds in their organization" ON funds 
  IS 'Los usuarios pueden ver todos los fondos de su organización';
COMMENT ON POLICY "Users can view transactions in their organization" ON transactions 
  IS 'Los usuarios pueden ver todas las transacciones de su organización';
COMMENT ON POLICY "Users can create transactions in their organization" ON transactions 
  IS 'Todos los usuarios pueden crear transacciones (se valida en la función)';
COMMENT ON POLICY "Creator, owners and admins can update transactions" ON transactions 
  IS 'Solo el creador, owners y admins pueden editar transacciones (considerar desactivar en producción)';
