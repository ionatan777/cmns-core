-- =====================================================
-- CMNS CORE - Migraciones CRM (007, 008, 009)
-- Ejecuta esto en Supabase SQL Editor
-- =====================================================

-- ========== PARTE 1: Tablas CRM (007) ==========

CREATE TYPE contact_source AS ENUM ('maps', 'tiktok', 'referral', 'other');

CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  business_name TEXT,
  city TEXT,
  tags JSONB DEFAULT '[]'::jsonb,
  source contact_source NOT NULL DEFAULT 'other',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(organization_id, phone)
);

CREATE TABLE pipelines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(organization_id, brand_id, name)
);

CREATE TABLE pipeline_stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  order_num INTEGER NOT NULL,
  color TEXT DEFAULT '#3b82f6',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(pipeline_id, name),
  UNIQUE(pipeline_id, order_num)
);

CREATE TYPE lead_status AS ENUM ('active', 'won', 'lost', 'archived');

CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
  contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE RESTRICT,
  product TEXT NOT NULL,
  value_estimated NUMERIC(12, 2),
  stage_id UUID NOT NULL REFERENCES pipeline_stages(id) ON DELETE RESTRICT,
  status lead_status NOT NULL DEFAULT 'active',
  last_contact_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE TYPE interaction_channel AS ENUM ('whatsapp', 'dm', 'call', 'email', 'meeting');

CREATE TABLE interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  channel interaction_channel NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE TYPE task_type AS ENUM ('call', 'message', 'meeting', 'proposal', 'other');
CREATE TYPE task_status AS ENUM ('pending', 'completed', 'cancelled');

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  type task_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  due_at TIMESTAMPTZ NOT NULL,
  status task_status NOT NULL DEFAULT 'pending',
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX idx_contacts_organization_id ON contacts(organization_id);
CREATE INDEX idx_pipelines_organization_id ON pipelines(organization_id);
CREATE INDEX idx_leads_organization_id ON leads(organization_id);
CREATE INDEX idx_leads_stage_id ON leads(stage_id);
CREATE INDEX idx_interactions_lead_id ON interactions(lead_id);
CREATE INDEX idx_tasks_organization_id ON tasks(organization_id);
CREATE INDEX idx_tasks_due_at ON tasks(due_at);
CREATE INDEX idx_tasks_status ON tasks(status);

-- Triggers updated_at
CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pipelines_updated_at BEFORE UPDATE ON pipelines
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pipeline_stages_updated_at BEFORE UPDATE ON pipeline_stages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger auto-followups
CREATE OR REPLACE FUNCTION auto_create_followups()
RETURNS TRIGGER AS $$
DECLARE
  v_prospectado_stage_id UUID;
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.stage_id = NEW.stage_id THEN
    RETURN NEW;
  END IF;

  SELECT ps.id INTO v_prospectado_stage_id
  FROM pipeline_stages ps
  JOIN pipelines p ON p.id = ps.pipeline_id
  WHERE ps.name = 'Prospectado'
    AND p.organization_id = NEW.organization_id
    AND (NEW.brand_id IS NULL OR p.brand_id = NEW.brand_id OR p.brand_id IS NULL)
  ORDER BY CASE WHEN p.brand_id = NEW.brand_id THEN 1 ELSE 2 END
  LIMIT 1;

  IF NEW.stage_id = v_prospectado_stage_id THEN
    INSERT INTO tasks (organization_id, lead_id, type, title, description, due_at, status, owner_user_id)
    VALUES (
      NEW.organization_id, NEW.id, 'message', 'Follow-up WhatsApp (+24h)',
      'Enviar mensaje de seguimiento por WhatsApp',
      now() + interval '24 hours', 'pending',
      COALESCE(NEW.created_by, auth.uid())
    );
    INSERT INTO tasks (organization_id, lead_id, type, title, description, due_at, status, owner_user_id)
    VALUES (
      NEW.organization_id, NEW.id, 'call', 'Llamada de seguimiento (+72h)',
      'Llamar para cerrar propuesta',
      now() + interval '72 hours', 'pending',
      COALESCE(NEW.created_by, auth.uid())
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_followups
  AFTER INSERT OR UPDATE OF stage_id ON leads
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_followups();

-- ========== PARTE 2: RLS (008) ==========

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Contacts
CREATE POLICY "Users can view contacts in their organization"
  ON contacts FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create contacts in their organization"
  ON contacts FOR INSERT
  WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update contacts in their organization"
  ON contacts FOR UPDATE
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- Leads
CREATE POLICY "Users can view leads in their organization"
  ON leads FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create leads in their organization"
  ON leads FOR INSERT
  WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update leads in their organization"
  ON leads FOR UPDATE
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- Tasks
CREATE POLICY "Users can view tasks in their organization"
  ON tasks FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can create tasks in their organization"
  ON tasks FOR INSERT
  WITH CHECK (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update tasks"
  ON tasks FOR UPDATE
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

-- Interactions
CREATE POLICY "Users can view interactions"
  ON interactions FOR SELECT
  USING (EXISTS (SELECT 1 FROM leads WHERE leads.id = interactions.lead_id AND leads.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));
CREATE POLICY "Users can create interactions"
  ON interactions FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM leads WHERE leads.id = interactions.lead_id AND leads.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));

-- Pipelines & Stages (simplificado)
CREATE POLICY "Users can view pipelines"
  ON pipelines FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));
CREATE POLICY "Users can view stages"
  ON pipeline_stages FOR SELECT
  USING (EXISTS (SELECT 1 FROM pipelines WHERE pipelines.id = pipeline_stages.pipeline_id AND pipelines.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)));

-- ========== PARTE 3: Seed Data (009) ==========

-- Pipeline CodelyLabs
INSERT INTO pipelines VALUES (
  '00000000-0000-0000-0000-000000000401',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000012',
  'Ventas de Landings', now(), now()
);

INSERT INTO pipeline_stages (id, pipeline_id, name, order_num, color) VALUES
  ('00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000401', 'Lead Nuevo', 1, '#94a3b8'),
  ('00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000401', 'Prospectado', 2, '#3b82f6'),
  ('00000000-0000-0000-0000-000000000413', '00000000-0000-0000-0000-000000000401', 'Propuesta Enviada', 3, '#f59e0b'),
  ('00000000-0000-0000-0000-000000000414', '00000000-0000-0000-0000-000000000401', 'Negociación', 4, '#8b5cf6'),
  ('00000000-0000-0000-0000-000000000415', '00000000-0000-0000-0000-000000000401', 'Ganado', 5, '#10b981'),
  ('00000000-0000-0000-0000-000000000416', '00000000-0000-0000-0000-000000000401', 'Perdido', 6, '#ef4444');

-- Pipeline Camvys
INSERT INTO pipelines VALUES (
  '00000000-0000-0000-0000-000000000402',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000011',
  'Ventas de Productos', now(), now()
);

INSERT INTO pipeline_stages (id, pipeline_id, name, order_num, color) VALUES
  ('00000000-0000-0000-0000-000000000421', '00000000-0000-0000-0000-000000000402', 'Contacto Inicial', 1, '#94a3b8'),
  ('00000000-0000-0000-0000-000000000422', '00000000-0000-0000-0000-000000000402', 'Cotización', 2, '#3b82f6'),
  ('00000000-0000-0000-0000-000000000423', '00000000-0000-0000-0000-000000000402', 'Pedido', 3, '#f59e0b'),
  ('00000000-0000-0000-0000-000000000424', '00000000-0000-0000-0000-000000000402', 'Pagado', 4, '#10b981'),
  ('00000000-0000-0000-0000-000000000425', '00000000-0000-0000-0000-000000000402', 'Cancelado', 5, '#ef4444');

-- ✅ COMPLETADO! CRM configurado.
