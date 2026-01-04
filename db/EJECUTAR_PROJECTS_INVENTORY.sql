-- =====================================================
-- CMNS CORE - Migraciones Projects + Inventory + Orders
-- Ejecuta esto en Supabase SQL Editor
-- =====================================================

-- ========== PARTE 1: PROJECTS (010) ==========

CREATE TYPE project_status AS ENUM ('draft', 'in_progress', 'completed', 'suspended');

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
  lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
  client_name TEXT NOT NULL,
  domain TEXT,
  status project_status NOT NULL DEFAULT 'draft',
  published_url TEXT,
  preview_screenshot_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id)
);

CREATE TABLE project_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  item TEXT NOT NULL,
  done BOOLEAN NOT NULL DEFAULT false,
  order_num INTEGER NOT NULL,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TYPE contract_status AS ENUM ('active', 'suspended', 'cancelled');

CREATE TABLE maintenance_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
  monthly_fee NUMERIC(8, 2) NOT NULL,
  hosting_included BOOLEAN NOT NULL DEFAULT true,
  status contract_status NOT NULL DEFAULT 'active',
  next_billing_date DATE NOT NULL,
  last_payment_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(project_id)
);

CREATE INDEX idx_projects_organization_id ON projects(organization_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_contracts_updated_at BEFORE UPDATE ON maintenance_contracts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION auto_create_project_checklist()
RETURNS TRIGGER AS $$
DECLARE
  v_items TEXT[] := ARRAY['Botón WhatsApp configurado','Mapa integrado','Formulario de contacto','Mobile responsive revisado','Dominio conectado','Publicado en producción','Captura/preview guardado'];
  v_item TEXT;
  v_order INT := 1;
BEGIN
  FOREACH v_item IN ARRAY v_items LOOP
    INSERT INTO project_checklist (project_id, item, order_num) VALUES (NEW.id, v_item, v_order);
    v_order := v_order + 1;
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_project_checklist AFTER INSERT ON projects FOR EACH ROW EXECUTE FUNCTION auto_create_project_checklist();

CREATE OR REPLACE FUNCTION check_project_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_total_items INT;
  v_done_items INT;
BEGIN
  SELECT COUNT(*), COUNT(*) FILTER (WHERE done = true) INTO v_total_items, v_done_items FROM project_checklist WHERE project_id = NEW.project_id;
  IF v_done_items = v_total_items THEN
    UPDATE projects SET status = 'completed', completed_at = now() WHERE id = NEW.project_id AND status != 'completed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_project_completion AFTER UPDATE OF done ON project_checklist FOR EACH ROW EXECUTE FUNCTION check_project_completion();

-- ========== PARTE 2: INVENTORY (011) ==========

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  sku TEXT NOT NULL,
  description TEXT,
  cost NUMERIC(10, 2) NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  category TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(organization_id, sku)
);

CREATE TYPE movement_type AS ENUM ('in', 'out', 'adjust');

CREATE TABLE inventory_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  type movement_type NOT NULL,
  qty INTEGER NOT NULL,
  cost NUMERIC(10, 2),
  note TEXT,
  ref_order_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE TABLE reorder_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  stock_min INTEGER NOT NULL,
  reorder_point INTEGER NOT NULL,
  lead_time_days INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(product_id)
);

CREATE INDEX idx_products_organization_id ON products(organization_id);
CREATE INDEX idx_products_brand_id ON products(brand_id);
CREATE INDEX idx_inventory_movements_product_id ON inventory_movements(product_id);
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION get_product_stock(p_product_id UUID)
RETURNS INTEGER AS $$
  SELECT COALESCE(SUM(CASE WHEN type = 'in' THEN qty WHEN type = 'out' THEN -qty WHEN type = 'adjust' THEN qty END), 0)::INTEGER
  FROM inventory_movements WHERE product_id = p_product_id;
$$ LANGUAGE SQL STABLE;

-- ========== PARTE 3: ORDERS (012) ==========

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
  is_drop BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  UNIQUE(organization_id, order_number)
);

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  qty INTEGER NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(10, 2) NOT NULL,
  subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (qty * unit_price) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE INDEX idx_orders_organization_id ON orders(organization_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION update_stock_on_order_confirmation()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed') THEN
    INSERT INTO inventory_movements (product_id, type, qty, ref_order_id, created_by)
    SELECT oi.product_id, 'out', oi.qty, NEW.id, NEW.created_by FROM order_items oi WHERE oi.order_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_on_order_confirmation AFTER INSERT OR UPDATE OF status ON orders FOR EACH ROW EXECUTE FUNCTION update_stock_on_order_confirmation();

CREATE OR REPLACE FUNCTION check_order_payment_status()
RETURNS TRIGGER AS $$
DECLARE
  v_total_paid NUMERIC;
  v_order_total NUMERIC;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid FROM payments WHERE order_id = NEW.order_id;
  SELECT total INTO v_order_total FROM orders WHERE id = NEW.order_id;
  IF v_total_paid >= v_order_total THEN
    UPDATE orders SET paid = true WHERE id = NEW.order_id AND paid = false;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_order_payment_status AFTER INSERT ON payments FOR EACH ROW EXECUTE FUNCTION check_order_payment_status();

-- ========== PARTE 4: RLS ==========

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reorder_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Projects
CREATE POLICY "Users can view projects" ON projects FOR SELECT USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create projects" ON projects FOR INSERT WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update projects" ON projects FOR UPDATE USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- Products
CREATE POLICY "Users can view products" ON products FOR SELECT USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create products" ON products FOR INSERT WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update products" ON products FOR UPDATE USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- Orders
CREATE POLICY "Users can view orders" ON orders FOR SELECT USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create orders" ON orders FOR INSERT WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update orders" ON orders FOR UPDATE USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- Inventory Movements
CREATE POLICY "Users can view movements" ON inventory_movements FOR SELECT USING (EXISTS (SELECT 1 FROM products WHERE products.id = inventory_movements.product_id AND products.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));
CREATE POLICY "Users can create movements" ON inventory_movements FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM products WHERE products.id = inventory_movements.product_id AND products.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));

-- Order Items
CREATE POLICY "Users can view order items" ON order_items FOR SELECT USING (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));
CREATE POLICY "Users can create order items" ON order_items FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));

-- Project Checklist
CREATE POLICY "Users can view checklist" ON project_checklist FOR SELECT USING (EXISTS (SELECT 1 FROM projects WHERE projects.id = project_checklist.project_id AND projects.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));
CREATE POLICY "Users can update checklist" ON project_checklist FOR UPDATE USING (EXISTS (SELECT 1 FROM projects WHERE projects.id = project_checklist.project_id AND projects.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));

-- Maintenance Contracts, Reorder Policies, Payments (simplified)
CREATE POLICY "Users can view contracts" ON maintenance_contracts FOR SELECT USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can view policies" ON reorder_policies FOR SELECT USING (EXISTS (SELECT 1 FROM products WHERE products.id = reorder_policies.product_id AND products.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));
CREATE POLICY "Users can view payments" ON payments FOR SELECT USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create payments" ON payments FOR INSERT WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- ✅ COMPLETADO! Projects, Inventory y Orders configurados.
