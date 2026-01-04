-- =====================================================
-- CMNS CORE - 007: Módulo CRM
-- Fase 3 (Semana 2): CRM MVP
-- =====================================================

-- =====================================================
-- 1. CONTACTS (Contactos/Negocios)
-- =====================================================
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
  
  -- Un contacto por teléfono por organización
  UNIQUE(organization_id, phone)
);

-- =====================================================
-- 2. PIPELINES (Embudos de Venta)
-- =====================================================
CREATE TABLE pipelines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(organization_id, brand_id, name)
);

-- =====================================================
-- 3. PIPELINE_STAGES (Etapas del Embudo)
-- =====================================================
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

-- =====================================================
-- 4. LEADS (Oportunidades)
-- =====================================================
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

-- =====================================================
-- 5. INTERACTIONS (Historial de Comunicación)
-- =====================================================
CREATE TYPE interaction_channel AS ENUM ('whatsapp', 'dm', 'call', 'email', 'meeting');

CREATE TABLE interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  channel interaction_channel NOT NULL,
  message TEXT NOT NULL,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- =====================================================
-- 6. TASKS (Tareas de Seguimiento)
-- =====================================================
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

-- =====================================================
-- ÍNDICES para performance
-- =====================================================
CREATE INDEX idx_contacts_organization_id ON contacts(organization_id);
CREATE INDEX idx_contacts_phone ON contacts(phone);
CREATE INDEX idx_pipelines_organization_id ON pipelines(organization_id);
CREATE INDEX idx_pipelines_brand_id ON pipelines(brand_id);
CREATE INDEX idx_pipeline_stages_pipeline_id ON pipeline_stages(pipeline_id);
CREATE INDEX idx_leads_organization_id ON leads(organization_id);
CREATE INDEX idx_leads_brand_id ON leads(brand_id);
CREATE INDEX idx_leads_contact_id ON leads(contact_id);
CREATE INDEX idx_leads_stage_id ON leads(stage_id);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_interactions_lead_id ON interactions(lead_id);
CREATE INDEX idx_interactions_created_at ON interactions(created_at DESC);
CREATE INDEX idx_tasks_organization_id ON tasks(organization_id);
CREATE INDEX idx_tasks_lead_id ON tasks(lead_id);
CREATE INDEX idx_tasks_owner_user_id ON tasks(owner_user_id);
CREATE INDEX idx_tasks_due_at ON tasks(due_at);
CREATE INDEX idx_tasks_status ON tasks(status);

-- =====================================================
-- TRIGGERS para updated_at automático
-- =====================================================
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

-- =====================================================
-- TRIGGER: Auto-crear follow-ups cuando lead → "Prospectado"
-- =====================================================
CREATE OR REPLACE FUNCTION auto_create_followups()
RETURNS TRIGGER AS $$
DECLARE
  v_prospectado_stage_id UUID;
BEGIN
  -- Solo para INSERT o cuando cambia el stage
  IF TG_OP = 'UPDATE' AND OLD.stage_id = NEW.stage_id THEN
    RETURN NEW;
  END IF;

  -- Obtener ID del stage "Prospectado" del pipeline correspondiente
  SELECT ps.id INTO v_prospectado_stage_id
  FROM pipeline_stages ps
  JOIN pipelines p ON p.id = ps.pipeline_id
  WHERE ps.name = 'Prospectado'
    AND p.organization_id = NEW.organization_id
    AND (NEW.brand_id IS NULL OR p.brand_id = NEW.brand_id OR p.brand_id IS NULL)
  ORDER BY 
    CASE WHEN p.brand_id = NEW.brand_id THEN 1 ELSE 2 END
  LIMIT 1;

  -- Si el lead entró a "Prospectado"
  IF NEW.stage_id = v_prospectado_stage_id THEN
    -- Task +24h: Mensaje WhatsApp
    INSERT INTO tasks (organization_id, lead_id, type, title, description, due_at, status, owner_user_id)
    VALUES (
      NEW.organization_id,
      NEW.id,
      'message',
      'Follow-up WhatsApp (+24h)',
      'Enviar mensaje de seguimiento por WhatsApp',
      now() + interval '24 hours',
      'pending',
      COALESCE(NEW.created_by, auth.uid())
    );

    -- Task +72h: Llamada
    INSERT INTO tasks (organization_id, lead_id, type, title, description, due_at, status, owner_user_id)
    VALUES (
      NEW.organization_id,
      NEW.id,
      'call',
      'Llamada de seguimiento (+72h)',
      'Llamar para cerrar propuesta',
      now() + interval '72 hours',
      'pending',
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

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE contacts IS 'Contactos y negocios prospectados';
COMMENT ON TABLE pipelines IS 'Embudos de venta por marca';
COMMENT ON TABLE pipeline_stages IS 'Etapas de cada embudo (Prospectado, Negociación, etc.)';
COMMENT ON TABLE leads IS 'Oportunidades de venta';
COMMENT ON TABLE interactions IS 'Historial de comunicación con leads';
COMMENT ON TABLE tasks IS 'Tareas de seguimiento (follow-ups)';
COMMENT ON FUNCTION auto_create_followups IS 'Crea automáticamente tareas de seguimiento cuando un lead entra a Prospectado';
