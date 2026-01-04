-- =====================================================
-- CMNS CORE - 004: Módulo de Finanzas
-- Fase 2 (Semana 1-2): Finanzas MVP
-- =====================================================

-- =====================================================
-- 1. ACCOUNTS (Cuentas Reales)
-- =====================================================
CREATE TYPE account_type AS ENUM ('bank', 'cash');

CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  type account_type NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  balance NUMERIC(12, 2) NOT NULL DEFAULT 0,
  
  -- Metadata adicional
  account_number TEXT,  -- Número de cuenta (opcional)
  bank_name TEXT,       -- Nombre del banco (si aplica)
  metadata JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Una cuenta debe tener nombre único por organización
  UNIQUE(organization_id, name)
);

-- =====================================================
-- 2. FUNDS (Fondos / Buckets)
-- =====================================================
CREATE TABLE funds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  
  -- Meta opcional (ej: Universidad = $3000, Deuda = $2500)
  goal_amount NUMERIC(12, 2),
  goal_date DATE,
  
  -- Si está locked, no se puede retirar dinero
  locked BOOLEAN NOT NULL DEFAULT false,
  
  -- Color para visualización (hex)
  color TEXT DEFAULT '#3b82f6',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Un fondo debe tener nombre único por organización
  UNIQUE(organization_id, name)
);

-- =====================================================
-- 3. TRANSACTIONS (Transacciones)
-- =====================================================
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'transfer');

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
  
  -- Datos de la transacción
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  type transaction_type NOT NULL,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  
  -- Cuenta origen/destino
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
  
  -- Categoría y notas
  category TEXT,
  note TEXT,
  
  -- Referencia a otra entidad (ej: order_id, project_id)
  ref_type TEXT,
  ref_id UUID,
  
  -- Metadata adicional (ej: recibo, captura)
  metadata JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- =====================================================
-- 4. TRANSACTION_SPLITS (Asignación a Fondos)
-- =====================================================
CREATE TABLE transaction_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  fund_id UUID NOT NULL REFERENCES funds(id) ON DELETE RESTRICT,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 5. ALLOCATION_RULES (Reglas de Asignación Automática)
-- =====================================================
CREATE TABLE allocation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Filtros opcionales
  brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,  -- Si es NULL, aplica a todas las marcas
  category TEXT,  -- Si es NULL, aplica a todas las categorías
  tx_type transaction_type NOT NULL,
  
  -- Splits en formato JSON
  -- Ejemplo: [{"fund_id": "uuid", "percentage": 40}, {"fund_id": "uuid", "percentage": 60}]
  split_config JSONB NOT NULL,
  
  -- Activar/desactivar regla
  active BOOLEAN NOT NULL DEFAULT true,
  
  -- Descripción de la regla
  description TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- ÍNDICES para performance
-- =====================================================
CREATE INDEX idx_accounts_organization_id ON accounts(organization_id);
CREATE INDEX idx_accounts_brand_id ON accounts(brand_id);
CREATE INDEX idx_funds_organization_id ON funds(organization_id);
CREATE INDEX idx_transactions_organization_id ON transactions(organization_id);
CREATE INDEX idx_transactions_brand_id ON transactions(brand_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_date ON transactions(date DESC);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transaction_splits_transaction_id ON transaction_splits(transaction_id);
CREATE INDEX idx_transaction_splits_fund_id ON transaction_splits(fund_id);
CREATE INDEX idx_allocation_rules_organization_id ON allocation_rules(organization_id);
CREATE INDEX idx_allocation_rules_brand_id ON allocation_rules(brand_id);
CREATE INDEX idx_allocation_rules_active ON allocation_rules(active);

-- =====================================================
-- TRIGGERS para updated_at automático
-- =====================================================
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_funds_updated_at BEFORE UPDATE ON funds
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_allocation_rules_updated_at BEFORE UPDATE ON allocation_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIÓN: Calcular saldo virtual de un fondo
-- =====================================================
CREATE OR REPLACE FUNCTION get_fund_balance(p_fund_id UUID)
RETURNS NUMERIC AS $$
  SELECT COALESCE(SUM(
    CASE 
      WHEN t.type = 'income' THEN ts.amount
      WHEN t.type = 'expense' THEN -ts.amount
      ELSE 0
    END
  ), 0)
  FROM transaction_splits ts
  JOIN transactions t ON t.id = ts.transaction_id
  WHERE ts.fund_id = p_fund_id;
$$ LANGUAGE SQL STABLE;

-- =====================================================
-- FUNCIÓN: Crear transacción con splits automáticos
-- =====================================================
CREATE OR REPLACE FUNCTION create_transaction(
  p_organization_id UUID,
  p_brand_id UUID,
  p_date DATE,
  p_type transaction_type,
  p_amount NUMERIC,
  p_account_id UUID,
  p_category TEXT,
  p_note TEXT,
  p_ref_type TEXT DEFAULT NULL,
  p_ref_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_transaction_id UUID;
  v_rule RECORD;
  v_split JSONB;
  v_fund_id UUID;
  v_percentage NUMERIC;
  v_split_amount NUMERIC;
  v_total_allocated NUMERIC := 0;
  v_user_id UUID;
BEGIN
  -- Obtener el usuario actual
  v_user_id := auth.uid();
  
  -- 1. Crear la transacción
  INSERT INTO transactions (
    organization_id, brand_id, date, type, amount, 
    account_id, category, note, ref_type, ref_id, 
    metadata, created_by
  )
  VALUES (
    p_organization_id, p_brand_id, p_date, p_type, p_amount,
    p_account_id, p_category, p_note, p_ref_type, p_ref_id,
    p_metadata, v_user_id
  )
  RETURNING id INTO v_transaction_id;
  
  -- 2. Actualizar balance de la cuenta
  IF p_type = 'income' THEN
    UPDATE accounts SET balance = balance + p_amount WHERE id = p_account_id;
  ELSIF p_type = 'expense' THEN
    UPDATE accounts SET balance = balance - p_amount WHERE id = p_account_id;
  END IF;
  
  -- 3. Buscar regla de asignación aplicable (solo para income/expense)
  IF p_type IN ('income', 'expense') THEN
    SELECT * INTO v_rule
    FROM allocation_rules
    WHERE organization_id = p_organization_id
      AND tx_type = p_type
      AND active = true
      AND (brand_id IS NULL OR brand_id = p_brand_id)
      AND (category IS NULL OR category = p_category)
    ORDER BY 
      CASE WHEN brand_id IS NOT NULL THEN 1 ELSE 2 END,
      CASE WHEN category IS NOT NULL THEN 1 ELSE 2 END
    LIMIT 1;
    
    -- 4. Si hay regla, crear splits automáticamente
    IF FOUND THEN
      FOR v_split IN SELECT * FROM jsonb_array_elements(v_rule.split_config)
      LOOP
        v_fund_id := (v_split->>'fund_id')::UUID;
        v_percentage := (v_split->>'percentage')::NUMERIC;
        v_split_amount := ROUND(p_amount * v_percentage / 100, 2);
        
        INSERT INTO transaction_splits (transaction_id, fund_id, amount)
        VALUES (v_transaction_id, v_fund_id, v_split_amount);
        
        v_total_allocated := v_total_allocated + v_split_amount;
      END LOOP;
      
      -- Ajustar redondeo (asignar diferencia al primer split)
      IF v_total_allocated != p_amount THEN
        UPDATE transaction_splits
        SET amount = amount + (p_amount - v_total_allocated)
        WHERE transaction_id = v_transaction_id
        ORDER BY created_at
        LIMIT 1;
      END IF;
    END IF;
  END IF;
  
  -- 5. Crear audit log
  INSERT INTO audit_log (
    organization_id, user_id, table_name, record_id, 
    action, after, metadata
  )
  VALUES (
    p_organization_id, v_user_id, 'transactions', v_transaction_id,
    'create', to_jsonb(NEW), jsonb_build_object('type', p_type, 'amount', p_amount)
  );
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE accounts IS 'Cuentas reales de la organización (bancos, efectivo)';
COMMENT ON TABLE funds IS 'Fondos virtuales para asignación de dinero (Universidad, Deuda, etc.)';
COMMENT ON TABLE transactions IS 'Transacciones financieras (ingresos, gastos, transferencias)';
COMMENT ON TABLE transaction_splits IS 'Asignación de transacciones a fondos específicos';
COMMENT ON TABLE allocation_rules IS 'Reglas automáticas de distribución de dinero a fondos';
COMMENT ON FUNCTION get_fund_balance IS 'Calcula el saldo virtual de un fondo basado en splits';
COMMENT ON FUNCTION create_transaction IS 'Crea una transacción con splits automáticos según reglas';
