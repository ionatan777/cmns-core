-- =====================================================
-- CMNS CORE - 013: Módulo de Metas
-- Fase 6 (Mes 2): Motor de Decisiones
-- =====================================================

-- =====================================================
-- 1. GOALS (Metas Financieras)
-- =====================================================
CREATE TYPE goal_status AS ENUM ('active', 'completed', 'cancelled');

CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  target_amount NUMERIC(12, 2) NOT NULL,
  target_date DATE NOT NULL,
  fund_id UUID REFERENCES funds(id) ON DELETE SET NULL,
  
  priority INTEGER NOT NULL DEFAULT 2 CHECK (priority IN (1, 2, 3)),  -- 1=alta, 2=media, 3=baja
  status goal_status NOT NULL DEFAULT 'active',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 2. GOAL_RULES (Reglas de Decisión Automática)
-- =====================================================
CREATE TYPE rule_type AS ENUM ('weekly_net_threshold', 'fund_pace', 'sales_target', 'custom');

CREATE TABLE goal_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  
  rule_type rule_type NOT NULL,
  params JSONB NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- ÍNDICES
-- =====================================================
CREATE INDEX idx_goals_organization_id ON goals(organization_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_goals_target_date ON goals(target_date);
CREATE INDEX idx_goal_rules_goal_id ON goal_rules(goal_id);
CREATE INDEX idx_goal_rules_active ON goal_rules(active);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goal_rules_updated_at BEFORE UPDATE ON goal_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIÓN: Calcular neto semanal
-- =====================================================
CREATE OR REPLACE FUNCTION get_weekly_net(
  p_organization_id UUID,
  p_week_start DATE DEFAULT CURRENT_DATE - 7
)
RETURNS NUMERIC AS $$
DECLARE
  v_income NUMERIC;
  v_expenses NUMERIC;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO v_income
  FROM transactions
  WHERE organization_id = p_organization_id
    AND type = 'income'
    AND date >= p_week_start
    AND date < p_week_start + 7;
  
  SELECT COALESCE(SUM(amount), 0) INTO v_expenses
  FROM transactions
  WHERE organization_id = p_organization_id
    AND type = 'expense'
    AND date >= p_week_start
    AND date < p_week_start + 7;
  
  RETURN v_income - v_expenses;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- FUNCIÓN: Calcular ritmo semanal requerido para meta
-- =====================================================
CREATE OR REPLACE FUNCTION get_goal_weekly_pace(p_goal_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  v_goal RECORD;
  v_current_amount NUMERIC;
  v_remaining NUMERIC;
  v_weeks_left NUMERIC;
BEGIN
  SELECT * INTO v_goal FROM goals WHERE id = p_goal_id;
  
  -- Si la meta tiene fondo asociado, obtener balance actual
  IF v_goal.fund_id IS NOT NULL THEN
    SELECT get_fund_balance(v_goal.fund_id) INTO v_current_amount;
  ELSE
    v_current_amount := 0;
  END IF;
  
  v_remaining := v_goal.target_amount - v_current_amount;
  
  -- Si ya pasó la fecha, retornar el monto restante completo
  IF v_goal.target_date <= CURRENT_DATE THEN
    RETURN v_remaining;
  END IF;
  
  -- Calcular semanas restantes
  v_weeks_left := CEIL((v_goal.target_date - CURRENT_DATE) / 7.0);
  
  IF v_weeks_left <= 0 THEN
    RETURN v_remaining;
  END IF;
  
  RETURN v_remaining / v_weeks_left;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- FUNCIÓN: Verificar si meta está "on track"
-- =====================================================
CREATE OR REPLACE FUNCTION is_goal_on_track(p_goal_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_goal RECORD;
  v_current_amount NUMERIC;
  v_days_total INTEGER;
  v_days_elapsed INTEGER;
  v_expected_progress NUMERIC;
  v_actual_progress NUMERIC;
BEGIN
  SELECT * INTO v_goal FROM goals WHERE id = p_goal_id;
  
  IF v_goal.fund_id IS NOT NULL THEN
    SELECT get_fund_balance(v_goal.fund_id) INTO v_current_amount;
  ELSE
    v_current_amount := 0;
  END IF;
  
  -- Calcular días totales y transcurridos
  SELECT 
    v_goal.target_date - v_goal.created_at::DATE,
    CURRENT_DATE - v_goal.created_at::DATE
  INTO v_days_total, v_days_elapsed;
  
  -- Progreso esperado vs actual
  v_expected_progress := (v_days_elapsed::NUMERIC / v_days_total) * v_goal.target_amount;
  v_actual_progress := v_current_amount;
  
  -- On track si el progreso actual >= 90% del esperado
  RETURN v_actual_progress >= (v_expected_progress * 0.9);
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE goals IS 'Metas financieras con fechas límite';
COMMENT ON TABLE goal_rules IS 'Reglas de decisión automática basadas en métricas';
COMMENT ON FUNCTION get_weekly_net IS 'Calcula el neto (ingresos - gastos) de una semana específica';
COMMENT ON FUNCTION get_goal_weekly_pace IS 'Calcula cuánto hay que aportar semanalmente para alcanzar la meta';
COMMENT ON FUNCTION is_goal_on_track IS 'Determina si una meta va en buen ritmo o está atrasada';
