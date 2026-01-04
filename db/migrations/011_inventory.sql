-- =====================================================
-- CMNS CORE - 011: Módulo de Inventario
-- Fase 5 (Semana 4): Camvys/Zypher Productos + Stock
-- =====================================================

-- =====================================================
-- 1. PRODUCTS (Productos)
-- =====================================================
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
  
  name TEXT NOT NULL,
  sku TEXT NOT NULL,
  description TEXT,
  
  cost NUMERIC(10, 2) NOT NULL,  -- Costo de compra
  price NUMERIC(10, 2) NOT NULL, -- Precio de venta
  
  active BOOLEAN NOT NULL DEFAULT true,
  category TEXT,
  image_url TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(organization_id, sku)
);

-- =====================================================
-- 2. INVENTORY_MOVEMENTS (Movimientos de Inventario)
-- =====================================================
CREATE TYPE movement_type AS ENUM ('in', 'out', 'adjust');

CREATE TABLE inventory_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  
  type movement_type NOT NULL,
  qty INTEGER NOT NULL,
  cost NUMERIC(10, 2),  -- Para type 'in'
  note TEXT,
  
  ref_order_id UUID,  -- FK a orders (se creará después)
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- =====================================================
-- 3. REORDER_POLICIES (Políticas de Reposición)
-- =====================================================
CREATE TABLE reorder_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  stock_min INTEGER NOT NULL,        -- Alerta cuando stock < esto
  reorder_point INTEGER NOT NULL,    -- Punto óptimo de reposición
  lead_time_days INTEGER NOT NULL,   -- Días que tarda en llegar
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(product_id)
);

-- =====================================================
-- ÍNDICES
-- =====================================================
CREATE INDEX idx_products_organization_id ON products(organization_id);
CREATE INDEX idx_products_brand_id ON products(brand_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_active ON products(active);
CREATE INDEX idx_inventory_movements_product_id ON inventory_movements(product_id);
CREATE INDEX idx_inventory_movements_type ON inventory_movements(type);
CREATE INDEX idx_inventory_movements_created_at ON inventory_movements(created_at DESC);
CREATE INDEX idx_reorder_policies_product_id ON reorder_policies(product_id);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reorder_policies_updated_at BEFORE UPDATE ON reorder_policies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIÓN: Calcular stock actual de un producto
-- =====================================================
CREATE OR REPLACE FUNCTION get_product_stock(p_product_id UUID)
RETURNS INTEGER AS $$
  SELECT COALESCE(SUM(
    CASE 
      WHEN type = 'in' THEN qty
      WHEN type = 'out' THEN -qty
      WHEN type = 'adjust' THEN qty
    END
  ), 0)::INTEGER
  FROM inventory_movements
  WHERE product_id = p_product_id;
$$ LANGUAGE SQL STABLE;

-- =====================================================
-- FUNCIÓN: Productos con stock bajo
-- =====================================================
CREATE OR REPLACE FUNCTION get_low_stock_products(p_organization_id UUID)
RETURNS TABLE(
  product_id UUID,
  product_name TEXT,
  sku TEXT,
  current_stock INTEGER,
  stock_min INTEGER
) AS $$
  SELECT 
    p.id,
    p.name,
    p.sku,
    get_product_stock(p.id),
    rp.stock_min
  FROM products p
  JOIN reorder_policies rp ON rp.product_id = p.id
  WHERE p.organization_id = p_organization_id
    AND p.active = true
    AND get_product_stock(p.id) < rp.stock_min
  ORDER BY get_product_stock(p.id) ASC;
$$ LANGUAGE SQL STABLE;

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE products IS 'Catálogo de productos para Camvys y Zypher';
COMMENT ON TABLE inventory_movements IS 'Historial de movimientos de stock (entradas, salidas, ajustes)';
COMMENT ON TABLE reorder_policies IS 'Políticas de reposición automática para evitar quiebres de stock';
COMMENT ON FUNCTION get_product_stock IS 'Calcula el stock actual de un producto sumando todos sus movimientos';
COMMENT ON FUNCTION get_low_stock_products IS 'Retorna productos con stock por debajo del mínimo';
