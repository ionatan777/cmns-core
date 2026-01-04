-- =====================================================
-- CMNS CORE - 012: Módulo de Órdenes
-- Fase 5 (Semana 4): Camvys/Zypher Ventas
-- =====================================================

-- =====================================================
-- 1. ORDERS (Órdenes)
-- =====================================================
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE delivery_method AS ENUM ('pickup', 'delivery', 'shipping');

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
  contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE RESTRICT,
  
  order_number TEXT NOT NULL,
  status order_status NOT NULL DEFAULT 'pending',
  total NUMERIC(10, 2) NOT NULL,
  paid BOOLEAN NOT NULL DEFAULT false,
  
  delivery_method delivery_method NOT NULL,
  delivery_address TEXT,
  notes TEXT,
  
  is_drop BOOLEAN NOT NULL DEFAULT false,  -- Para Zypher: preventa
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  
  UNIQUE(organization_id, order_number)
);

-- =====================================================
-- 2. ORDER_ITEMS (Items de Orden)
-- =====================================================
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  
  qty INTEGER NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(10, 2) NOT NULL,
  subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (qty * unit_price) STORED,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 3. PAYMENTS (Pagos)
-- =====================================================
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  
  amount NUMERIC(10, 2) NOT NULL,
  payment_method TEXT NOT NULL,
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- ÍNDICES
-- =====================================================
CREATE INDEX idx_orders_organization_id ON orders(organization_id);
CREATE INDEX idx_orders_brand_id ON orders(brand_id);
CREATE INDEX idx_orders_contact_id ON orders(contact_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_paid ON orders(paid);
CREATE INDEX idx_orders_is_drop ON orders(is_drop);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_organization_id ON payments(organization_id);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIÓN: Generar número de orden único
-- =====================================================
CREATE OR REPLACE FUNCTION generate_order_number(p_organization_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_year TEXT := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
  v_count INT;
  v_number TEXT;
BEGIN
  SELECT COUNT(*) + 1 INTO v_count
  FROM orders
  WHERE organization_id = p_organization_id
    AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE);
  
  v_number := 'ORD-' || v_year || '-' || LPAD(v_count::TEXT, 4, '0');
  RETURN v_number;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER: Actualizar stock al confirmar orden
-- =====================================================
CREATE OR REPLACE FUNCTION update_stock_on_order_confirmation()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo cuando cambia a 'confirmed' desde otro estado
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed') THEN
    -- Crear movimientos de salida para cada item
    INSERT INTO inventory_movements (product_id, type, qty, ref_order_id, created_by)
    SELECT 
      oi.product_id,
      'out',
      oi.qty,
      NEW.id,
      NEW.created_by
    FROM order_items oi
    WHERE oi.order_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_on_order_confirmation
  AFTER INSERT OR UPDATE OF status ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_stock_on_order_confirmation();

-- =====================================================
-- TRIGGER: Marcar orden como pagada si total de pagos >= total
-- =====================================================
CREATE OR REPLACE FUNCTION check_order_payment_status()
RETURNS TRIGGER AS $$
DECLARE
  v_total_paid NUMERIC;
  v_order_total NUMERIC;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
  FROM payments
  WHERE order_id = NEW.order_id;
  
  SELECT total INTO v_order_total
  FROM orders
  WHERE id = NEW.order_id;
  
  IF v_total_paid >= v_order_total THEN
    UPDATE orders
    SET paid = true
    WHERE id = NEW.order_id AND paid = false;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_order_payment_status
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION check_order_payment_status();

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE orders IS 'Órdenes de venta para Camvys y Zypher';
COMMENT ON TABLE order_items IS 'Líneas de items de cada orden';
COMMENT ON TABLE payments IS 'Pagos asociados a órdenes';
COMMENT ON FUNCTION generate_order_number IS 'Genera número de orden único: ORD-2026-0001';
COMMENT ON FUNCTION update_stock_on_order_confirmation IS 'Descuenta stock automáticamente cuando orden pasa a confirmed';
COMMENT ON FUNCTION check_order_payment_status IS 'Marca orden como pagada si suma de pagos >= total';
