-- =====================================================
-- CMNS CORE - Metas + Reportes (Goals + Intelligence)
-- Ejecuta esto en Supabase SQL Editor
-- =====================================================

-- ========== PARTE 1: GOALS (013) ==========

CREATE TYPE goal_status AS ENUM ('active', 'completed', 'cancelled');

CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_amount NUMERIC(12, 2) NOT NULL,
  target_date DATE NOT NULL,
  fund_id UUID REFERENCES funds(id) ON DELETE SET NULL,
  priority INTEGER NOT NULL DEFAULT 2 CHECK (priority IN (1, 2, 3)),
  status goal_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE INDEX idx_goals_organization_id ON goals(organization_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION get_weekly_net(p_organization_id UUID, p_week_start DATE DEFAULT CURRENT_DATE - 7)
RETURNS NUMERIC AS $$
DECLARE v_income NUMERIC; v_expenses NUMERIC;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO v_income FROM transactions WHERE organization_id = p_organization_id AND type = 'income' AND date >= p_week_start AND date < p_week_start + 7;
  SELECT COALESCE(SUM(amount), 0) INTO v_expenses FROM transactions WHERE organization_id = p_organization_id AND type = 'expense' AND date >= p_week_start AND date < p_week_start + 7;
  RETURN v_income - v_expenses;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION get_goal_weekly_pace(p_goal_id UUID)
RETURNS NUMERIC AS $$
DECLARE v_goal RECORD; v_current_amount NUMERIC; v_remaining NUMERIC; v_weeks_left NUMERIC;
BEGIN
  SELECT * INTO v_goal FROM goals WHERE id = p_goal_id;
  IF v_goal.fund_id IS NOT NULL THEN SELECT get_fund_balance(v_goal.fund_id) INTO v_current_amount; ELSE v_current_amount := 0; END IF;
  v_remaining := v_goal.target_amount - v_current_amount;
  IF v_goal.target_date <= CURRENT_DATE THEN RETURN v_remaining; END IF;
  v_weeks_left := CEIL((v_goal.target_date - CURRENT_DATE) / 7.0);
  IF v_weeks_left <= 0 THEN RETURN v_remaining; END IF;
  RETURN v_remaining / v_weeks_left;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION is_goal_on_track(p_goal_id UUID)
RETURNS BOOLEAN AS $$
DECLARE v_goal RECORD; v_current_amount NUMERIC; v_days_total INTEGER; v_days_elapsed INTEGER; v_expected_progress NUMERIC; v_actual_progress NUMERIC;
BEGIN
  SELECT * INTO v_goal FROM goals WHERE id = p_goal_id;
  IF v_goal.fund_id IS NOT NULL THEN SELECT get_fund_balance(v_goal.fund_id) INTO v_current_amount; ELSE v_current_amount := 0; END IF;
  SELECT v_goal.target_date - v_goal.created_at::DATE, CURRENT_DATE - v_goal.created_at::DATE INTO v_days_total, v_days_elapsed;
  v_expected_progress := (v_days_elapsed::NUMERIC / v_days_total) * v_goal.target_amount;
  v_actual_progress := v_current_amount;
  RETURN v_actual_progress >= (v_expected_progress * 0.9);
END;
$$ LANGUAGE plpgsql STABLE;

-- ========== PARTE 2: REPORTS (014) ==========

CREATE MATERIALIZED VIEW weekly_net_report AS
SELECT organization_id, brand_id, DATE_TRUNC('week', date)::DATE as week_start,
  SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
  SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expenses,
  SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as net
FROM transactions GROUP BY organization_id, brand_id, DATE_TRUNC('week', date);

CREATE INDEX idx_weekly_net_org_week ON weekly_net_report(organization_id, week_start DESC);

CREATE MATERIALIZED VIEW top_products_report AS
SELECT p.id as product_id, p.organization_id, p.brand_id, p.name, p.sku, p.cost, p.price,
  COUNT(DISTINCT oi.order_id) as total_orders, SUM(oi.qty) as units_sold,
  SUM(oi.subtotal) as total_revenue, SUM(oi.qty * p.cost) as total_cost,
  SUM(oi.subtotal - (oi.qty * p.cost)) as total_profit,
  CASE WHEN SUM(oi.qty * p.cost) > 0 THEN ((SUM(oi.subtotal - (oi.qty * p.cost)) / SUM(oi.qty * p.cost)) * 100) ELSE 0 END as margin_pct
FROM products p LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o ON o.id = oi.order_id AND o.status != 'cancelled'
GROUP BY p.id, p.organization_id, p.brand_id, p.name, p.sku, p.cost, p.price;

CREATE INDEX idx_top_products_profit ON top_products_report(total_profit DESC NULLS LAST);

CREATE OR REPLACE FUNCTION refresh_all_reports()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY weekly_net_report;
  REFRESH MATERIALIZED VIEW CONCURRENTLY top_products_report;
END;
$$ LANGUAGE plpgsql;

-- ========== PARTE 3: RLS ==========

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view goals" ON goals FOR SELECT USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create goals" ON goals FOR INSERT WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update goals" ON goals FOR UPDATE USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Users can view rules" ON goal_rules FOR SELECT USING (EXISTS (SELECT 1 FROM goals WHERE goals.id = goal_rules.goal_id AND goals.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));

-- ✅ COMPLETADO! Sistema con motor de decisiones e inteligencia.
