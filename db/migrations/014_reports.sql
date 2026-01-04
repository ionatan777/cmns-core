-- =====================================================
-- CMNS CORE - 014: Vistas de Reportes
-- Fase 7 (Mes 2-3): CMNS Intelligence
-- =====================================================

-- =====================================================
-- VISTA: Neto Semanal Consolidado
-- =====================================================
CREATE MATERIALIZED VIEW weekly_net_report AS
SELECT 
  organization_id,
  brand_id,
  DATE_TRUNC('week', date)::DATE as week_start,
  SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
  SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expenses,
  SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as net
FROM transactions
GROUP BY organization_id, brand_id, DATE_TRUNC('week', date);

CREATE INDEX idx_weekly_net_org_week ON weekly_net_report(organization_id, week_start DESC);
CREATE INDEX idx_weekly_net_brand ON weekly_net_report(brand_id);

-- =====================================================
-- VISTA: Funnel CodelyLabs
-- =====================================================
CREATE MATERIALIZED VIEW codelylabs_funnel AS
SELECT 
  l.organization_id,
  DATE_TRUNC('month', l.created_at)::DATE as month_start,
  COUNT(*) as total_leads,
  COUNT(*) FILTER (WHERE ps.name = 'Prospectado') as prospected,
  COUNT(*) FILTER (WHERE ps.name = 'Propuesta Enviada') as proposal_sent,
  COUNT(*) FILTER (WHERE ps.name = 'Ganado') as won,
  COUNT(p.id) FILTER (WHERE p.status = 'completed') as delivered,
  AVG(EXTRACT(EPOCH FROM (p.completed_at - l.created_at))/86400) FILTER (WHERE p.completed_at IS NOT NULL) as avg_delivery_days
FROM leads l
JOIN pipeline_stages ps ON ps.id = l.stage_id
JOIN pipelines pip ON pip.id = ps.pipeline_id
LEFT JOIN projects p ON p.lead_id = l.id
JOIN brands b ON b.id = l.brand_id
WHERE b.name = 'CodelyLabs'
GROUP BY l.organization_id, DATE_TRUNC('month', l.created_at);

CREATE INDEX idx_funnel_org_month ON codelylabs_funnel(organization_id, month_start DESC);

-- =====================================================
-- VISTA: Top Productos (Camvys/Zypher)
-- =====================================================
CREATE MATERIALIZED VIEW top_products_report AS
SELECT 
  p.id as product_id,
  p.organization_id,
  p.brand_id,
  p.name,
  p.sku,
  p.cost,
  p.price,
  COUNT(DISTINCT oi.order_id) as total_orders,
  SUM(oi.qty) as units_sold,
  SUM(oi.subtotal) as total_revenue,
  SUM(oi.qty * p.cost) as total_cost,
  SUM(oi.subtotal - (oi.qty * p.cost)) as total_profit,
  CASE 
    WHEN SUM(oi.qty * p.cost) > 0 
    THEN ((SUM(oi.subtotal - (oi.qty * p.cost)) / SUM(oi.qty * p.cost)) * 100)
    ELSE 0 
  END as margin_pct
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o ON o.id = oi.order_id AND o.status != 'cancelled'
GROUP BY p.id, p.organization_id, p.brand_id, p.name, p.sku, p.cost, p.price;

CREATE INDEX idx_top_products_org_brand ON top_products_report(organization_id, brand_id);
CREATE INDEX idx_top_products_profit ON top_products_report(total_profit DESC NULLS LAST);

-- =====================================================
-- VISTA: Análisis de Drops (Zypher)
-- =====================================================
CREATE MATERIALIZED VIEW zypher_drops_report AS
SELECT 
  o.organization_id,
  DATE_TRUNC('month', o.created_at)::DATE as month_start,
  COUNT(DISTINCT o.id) as total_drops,
  SUM(o.total) as total_revenue,
  SUM(CASE WHEN o.paid THEN o.total ELSE 0 END) as paid_revenue,
  COUNT(DISTINCT oi.product_id) as unique_products,
  SUM(oi.qty) as total_units
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN brands b ON b.id = o.brand_id
WHERE o.is_drop = true
  AND b.name = 'Zypher'
  AND o.status != 'cancelled'
GROUP BY o.organization_id, DATE_TRUNC('month', o.created_at);

CREATE INDEX idx_drops_org_month ON zypher_drops_report(organization_id, month_start DESC);

-- =====================================================
-- FUNCIÓN: Refrescar todas las vistas
-- =====================================================
CREATE OR REPLACE FUNCTION refresh_all_reports()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY weekly_net_report;
  REFRESH MATERIALIZED VIEW CONCURRENTLY codelylabs_funnel;
  REFRESH MATERIALIZED VIEW CONCURRENTLY top_products_report;
  REFRESH MATERIALIZED VIEW CONCURRENTLY zypher_drops_report;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCIÓN: Productos con stock bajo (Camvys)
-- =====================================================
CREATE OR REPLACE FUNCTION get_low_stock_products(p_organization_id UUID, p_brand_id UUID DEFAULT NULL)
RETURNS TABLE(
  product_id UUID,
  product_name TEXT,
  sku TEXT,
  current_stock INTEGER,
  stock_min INTEGER,
  reorder_point INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.sku,
    get_product_stock(p.id),
    rp.stock_min,
    rp.reorder_point
  FROM products p
  JOIN reorder_policies rp ON rp.product_id = p.id
  WHERE p.organization_id = p_organization_id
    AND p.active = true
    AND (p_brand_id IS NULL OR p.brand_id = p_brand_id)
    AND get_product_stock(p.id) < rp.stock_min
  ORDER BY get_product_stock(p.id) ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- FUNCIÓN: Órdenes pendientes de entrega (Camvys)
-- =====================================================
CREATE OR REPLACE FUNCTION get_pending_deliveries(p_organization_id UUID)
RETURNS TABLE(
  order_id UUID,
  order_number TEXT,
  contact_name TEXT,
  total NUMERIC,
  status order_status,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.order_number,
    COALESCE(c.business_name, c.name),
    o.total,
    o.status,
    o.created_at
  FROM orders o
  JOIN contacts c ON c.id = o.contact_id
  WHERE o.organization_id = p_organization_id
    AND o.status IN ('confirmed', 'preparing', 'shipped')
  ORDER BY o.created_at ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON MATERIALIZED VIEW weekly_net_report IS 'Neto semanal consolidado y por marca';
COMMENT ON MATERIALIZED VIEW codelylabs_funnel IS 'Funnel de conversión mensual de CodelyLabs';
COMMENT ON MATERIALIZED VIEW top_products_report IS 'Top productos por ganancia y margen';
COMMENT ON MATERIALIZED VIEW zypher_drops_report IS 'Análisis de drops de Zypher por mes';
COMMENT ON FUNCTION refresh_all_reports IS 'Refresca todas las vistas materializadas de reportes';
COMMENT ON FUNCTION get_low_stock_products IS 'Retorna productos con stock por debajo del mínimo';
COMMENT ON FUNCTION get_pending_deliveries IS 'Retorna órdenes pendientes de entrega';
