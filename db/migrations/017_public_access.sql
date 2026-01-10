-- =====================================================
-- CMNS CORE - 017: Public Access & Anonymous Fixes
-- =====================================================

-- 1. Actualizar create_transaction para soportar usuarios anónimos (NULL)
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
  -- Obtener el usuario actual (puede ser NULL si no hay login)
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
  
  -- 3. Buscar regla de asignación aplicable
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
    
    -- 4. Si hay regla, crear splits
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
      
      -- Ajustar redondeo
      IF v_total_allocated != p_amount THEN
        UPDATE transaction_splits
        SET amount = amount + (p_amount - v_total_allocated)
        WHERE transaction_id = v_transaction_id
        ORDER BY created_at
        LIMIT 1;
      END IF;
    END IF;
  END IF;
  
  -- 5. Crear audit log (SOLO SI HAY USUARIO)
  -- Esto evita el error "null value in column user_id violates not-null constraint"
  IF v_user_id IS NOT NULL THEN
      INSERT INTO audit_log (
        organization_id, user_id, table_name, record_id, 
        action, after, metadata
      )
      VALUES (
        p_organization_id, v_user_id, 'transactions', v_transaction_id,
        'create', to_jsonb(NEW), jsonb_build_object('type', p_type, 'amount', p_amount)
      );
  END IF;
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Habilitar Acceso Público (RLS para 'anon')
-- Nos aseguramos que RLS este activo y permitimos acceso total a todos
-- Esto es inseguro para producción real, pero ideal para uso personal en modo dev.

-- Helper para aplicar policys masivas
DO $$
DECLARE
    tables text[] := ARRAY['organizations', 'brands', 'accounts', 'funds', 'transactions', 'transaction_splits', 'allocation_rules'];
    t text;
BEGIN
    FOREACH t IN ARRAY tables
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', t);
        
        -- Borrar políticas previas para evitar conflictos
        EXECUTE format('DROP POLICY IF EXISTS "Public Full Access" ON %I;', t);
        
        -- Crear política permisiva para todos (anon y authenticated)
        EXECUTE format('CREATE POLICY "Public Full Access" ON %I FOR ALL USING (true) WITH CHECK (true);', t);
    END LOOP;
END $$;
