-- =====================================================
-- CMNS CORE - 016: Reset Finance Data & Seed User Request
-- Limpieza de datos y configuración inicial solicitada por el usuario
-- =====================================================

DO $$
DECLARE
    v_org_id UUID;
    v_cash_account_id UUID;
    v_investment_fund_id UUID;
    v_debt_fund_id UUID;
BEGIN
    -- 1. Obtener IDs necesarios
    SELECT id INTO v_org_id FROM organizations LIMIT 1;
    SELECT id INTO v_cash_account_id FROM accounts WHERE type = 'cash' LIMIT 1;
    SELECT id INTO v_investment_fund_id FROM funds WHERE name = 'Capital de Inversión' LIMIT 1;
    SELECT id INTO v_debt_fund_id FROM funds WHERE name = 'Deuda' LIMIT 1;

    -- Validar que existan (si no, intentar fallback)
    IF v_cash_account_id IS NULL THEN
        -- Crear cuenta efectivo si no existe
        INSERT INTO accounts (organization_id, name, type, currency, balance)
        VALUES (v_org_id, 'Efectivo', 'cash', 'USD', 0)
        RETURNING id INTO v_cash_account_id;
    END IF;

    -- 2. LIMPIEZA DE DATOS (Reset a 0)
    -- Eliminar todas las transacciones (esto limpiará splits por cascade)
    DELETE FROM transactions WHERE organization_id = v_org_id;
    
    -- Resetear balances de cuentas a 0
    UPDATE accounts SET balance = 0 WHERE organization_id = v_org_id;
    
    -- Resetear balances de fondos (recalculados vía función, pero por si acaso)
    -- En este modelo, los fondos son virtuales, dependen de transacciones.

    -- 3. ACTUALIZAR META DE DEUDA ($4,000)
    IF v_debt_fund_id IS NOT NULL THEN
        UPDATE funds 
        SET goal_amount = 4000 
        WHERE id = v_debt_fund_id;
    END IF;

    -- 4. INSERTAR DATOS INICIALES (Neto semanal $110 / Inversión $110)
    -- Insertamos una transacción de INGRESO de $110 hoy.
    -- La asignamos manualmente al fondo de Inversión para que cuadre todo.

    IF v_investment_fund_id IS NOT NULL AND v_cash_account_id IS NOT NULL THEN
        -- Usamos la función create_transaction para que maneje el balance de cuenta y la lógica
        -- Pero como queremos forzar la asignación al fondo de inversión, quizás sea mejor insertar directo
        -- para evitar que las reglas por defecto (si las hay) lo distribuyan mal.
        
        -- Insert Transaction
        WITH new_tx AS (
            INSERT INTO transactions (organization_id, account_id, type, amount, category, note, date)
            VALUES (
                v_org_id, 
                v_cash_account_id, 
                'income', 
                110.00, 
                'Capital Inicial', 
                'Semilla inicial para inversión (Neto Semanal)', 
                CURRENT_DATE
            )
            RETURNING id
        )
        -- Insert Split (100% al fondo de inversión)
        INSERT INTO transaction_splits (transaction_id, fund_id, amount)
        SELECT id, v_investment_fund_id, 110.00 FROM new_tx;

        -- Actualizar cuenta manualmente (si no usamos el trigger/función)
        -- En el schema 004, hay triggers? create_transaction actualiza balance.
        -- Si insertamos directo en transactions, NO se actualiza balance account automaticamente 
        -- a menos que haya un trigger de DB.
        -- Revisando 004_finance.sql: NO HAY TRIGGER DE BALANCES, es manejado por create_transaction.
        -- Así que debemos actualizar el balance de la cuenta también.
        
        UPDATE accounts 
        SET balance = balance + 110.00 
        WHERE id = v_cash_account_id;

    END IF;

END $$;
