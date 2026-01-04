-- =====================================================
-- CMNS CORE - 010: Módulo de Proyectos
-- Fase 4 (Semana 3): CodelyLabs Landings + Mantenimiento
-- =====================================================

-- =====================================================
-- 1. PROJECTS (Proyectos/Landings)
-- =====================================================
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

-- =====================================================
-- 2. PROJECT_CHECKLIST (Items del Checklist)
-- =====================================================
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

-- =====================================================
-- 3. MAINTENANCE_CONTRACTS (Contratos de Mantenimiento)
-- =====================================================
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

-- =====================================================
-- ÍNDICES
-- =====================================================
CREATE INDEX idx_projects_organization_id ON projects(organization_id);
CREATE INDEX idx_projects_brand_id ON projects(brand_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_project_checklist_project_id ON project_checklist(project_id);
CREATE INDEX idx_maintenance_contracts_organization_id ON maintenance_contracts(organization_id);
CREATE INDEX idx_maintenance_contracts_status ON maintenance_contracts(status);
CREATE INDEX idx_maintenance_contracts_next_billing ON maintenance_contracts(next_billing_date);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_contracts_updated_at BEFORE UPDATE ON maintenance_contracts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TRIGGER: Auto-crear checklist al crear proyecto
-- =====================================================
CREATE OR REPLACE FUNCTION auto_create_project_checklist()
RETURNS TRIGGER AS $$
DECLARE
  v_items TEXT[] := ARRAY[
    'Botón WhatsApp configurado',
    'Mapa integrado',
    'Formulario de contacto',
    'Mobile responsive revisado',
    'Dominio conectado',
    'Publicado en producción',
    'Captura/preview guardado'
  ];
  v_item TEXT;
  v_order INT := 1;
BEGIN
  FOREACH v_item IN ARRAY v_items LOOP
    INSERT INTO project_checklist (project_id, item, order_num)
    VALUES (NEW.id, v_item, v_order);
    v_order := v_order + 1;
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_project_checklist
  AFTER INSERT ON projects
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_project_checklist();

-- =====================================================
-- TRIGGER: Marcar proyecto como completado
-- =====================================================
CREATE OR REPLACE FUNCTION check_project_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_total_items INT;
  v_done_items INT;
BEGIN
  SELECT COUNT(*), COUNT(*) FILTER (WHERE done = true)
  INTO v_total_items, v_done_items
  FROM project_checklist
  WHERE project_id = NEW.project_id;
  
  IF v_done_items = v_total_items THEN
    UPDATE projects
    SET status = 'completed', completed_at = now()
    WHERE id = NEW.project_id AND status != 'completed';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_project_completion
  AFTER UPDATE OF done ON project_checklist
  FOR EACH ROW
  EXECUTE FUNCTION check_project_completion();

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE projects IS 'Proyectos/landings de CodelyLabs';
COMMENT ON TABLE project_checklist IS 'Checklist estandarizado de 7 items para cada proyecto';
COMMENT ON TABLE maintenance_contracts IS 'Contratos de mantenimiento mensual con billing automático';
COMMENT ON FUNCTION auto_create_project_checklist IS 'Crea automáticamente los 7 items del checklist';
COMMENT ON FUNCTION check_project_completion IS 'Marca proyecto como completado cuando todos los items están done';
