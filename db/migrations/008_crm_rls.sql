-- =====================================================
-- CMNS CORE - 008: CRM Row Level Security
-- Fase 3 (Semana 2): Seguridad Multi-Tenant CRM
-- =====================================================

-- =====================================================
-- ACTIVAR RLS EN TODAS LAS TABLAS CRM
-- =====================================================
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS: CONTACTS
-- =====================================================

CREATE POLICY "Users can view contacts in their organization"
  ON contacts FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Users can create contacts in their organization"
  ON contacts FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Users can update contacts in their organization"
  ON contacts FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Owners and admins can delete contacts"
  ON contacts FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = contacts.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- =====================================================
-- POLÍTICAS: PIPELINES
-- =====================================================

CREATE POLICY "Users can view pipelines in their organization"
  ON pipelines FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Owners and admins can create pipelines"
  ON pipelines FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = pipelines.organization_id
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners and admins can update pipelines"
  ON pipelines FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = pipelines.organization_id
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners can delete pipelines"
  ON pipelines FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = pipelines.organization_id
      AND role = 'owner'
    )
  );

-- =====================================================
-- POLÍTICAS: PIPELINE_STAGES
-- =====================================================

CREATE POLICY "Users can view pipeline stages in their organization"
  ON pipeline_stages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pipelines
      WHERE pipelines.id = pipeline_stages.pipeline_id
      AND pipelines.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    )
  );

CREATE POLICY "Owners and admins can create pipeline stages"
  ON pipeline_stages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM pipelines p
      JOIN memberships m ON m.organization_id = p.organization_id
      WHERE p.id = pipeline_stages.pipeline_id
      AND m.user_id = auth.uid()
      AND m.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners and admins can update pipeline stages"
  ON pipeline_stages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM pipelines p
      JOIN memberships m ON m.organization_id = p.organization_id
      WHERE p.id = pipeline_stages.pipeline_id
      AND m.user_id = auth.uid()
      AND m.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners can delete pipeline stages"
  ON pipeline_stages FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM pipelines p
      JOIN memberships m ON m.organization_id = p.organization_id
      WHERE p.id = pipeline_stages.pipeline_id
      AND m.user_id = auth.uid()
      AND m.role = 'owner'
    )
  );

-- =====================================================
-- POLÍTICAS: LEADS
-- =====================================================

CREATE POLICY "Users can view leads in their organization"
  ON leads FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Users can create leads in their organization"
  ON leads FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Users can update leads in their organization"
  ON leads FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Owners and admins can delete leads"
  ON leads FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = leads.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- =====================================================
-- POLÍTICAS: INTERACTIONS
-- =====================================================

CREATE POLICY "Users can view interactions for leads in their organization"
  ON interactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = interactions.lead_id
      AND leads.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    )
  );

CREATE POLICY "Users can create interactions for leads in their organization"
  ON interactions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = interactions.lead_id
      AND leads.organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    )
  );

-- =====================================================
-- POLÍTICAS: TASKS
-- =====================================================

CREATE POLICY "Users can view tasks in their organization"
  ON tasks FOR SELECT
  USING (organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "Users can create tasks in their organization"
  ON tasks FOR INSERT
  WITH CHECK (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Task owner and admins can update tasks"
  ON tasks FOR UPDATE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND (
      owner_user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM memberships
        WHERE user_id = auth.uid()
        AND organization_id = tasks.organization_id
        AND role IN ('owner', 'admin')
      )
    )
  );

CREATE POLICY "Owners and admins can delete tasks"
  ON tasks FOR DELETE
  USING (
    organization_id = (SELECT organization_id FROM memberships WHERE user_id = auth.uid() LIMIT 1)
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = tasks.organization_id
      AND role IN ('owner', 'admin')
    )
  );
