-- =====================================================
-- CMNS CORE - 002: Row Level Security (RLS)
-- Fase 1 (Semana 1): Seguridad Multi-Tenant
-- =====================================================

-- =====================================================
-- FUNCIÓN AUXILIAR: Obtener organization_id del usuario actual
-- =====================================================
CREATE OR REPLACE FUNCTION auth.user_organization_id()
RETURNS UUID AS $$
  SELECT organization_id 
  FROM memberships 
  WHERE user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- =====================================================
-- ACTIVAR RLS EN TODAS LAS TABLAS
-- =====================================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS: ORGANIZATIONS
-- =====================================================

-- Los usuarios pueden ver su propia organización
CREATE POLICY "Users can view their own organization"
  ON organizations FOR SELECT
  USING (id = auth.user_organization_id());

-- Solo owners y admins pueden actualizar la organización
CREATE POLICY "Owners and admins can update organization"
  ON organizations FOR UPDATE
  USING (
    id = auth.user_organization_id() 
    AND EXISTS (
      SELECT 1 FROM memberships 
      WHERE user_id = auth.uid() 
      AND organization_id = organizations.id 
      AND role IN ('owner', 'admin')
    )
  );

-- =====================================================
-- POLÍTICAS: MEMBERSHIPS
-- =====================================================

-- Los usuarios pueden ver memberships de su organización
CREATE POLICY "Users can view memberships in their organization"
  ON memberships FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Solo owners y admins pueden insertar memberships
CREATE POLICY "Owners and admins can insert memberships"
  ON memberships FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.user_id = auth.uid()
      AND m.organization_id = memberships.organization_id
      AND m.role IN ('owner', 'admin')
    )
  );

-- Solo owners y admins pueden actualizar memberships
CREATE POLICY "Owners and admins can update memberships"
  ON memberships FOR UPDATE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.user_id = auth.uid()
      AND m.organization_id = memberships.organization_id
      AND m.role IN ('owner', 'admin')
    )
  );

-- Solo owners pueden eliminar memberships
CREATE POLICY "Owners can delete memberships"
  ON memberships FOR DELETE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships m
      WHERE m.user_id = auth.uid()
      AND m.organization_id = memberships.organization_id
      AND m.role = 'owner'
    )
  );

-- =====================================================
-- POLÍTICAS: BRANDS
-- =====================================================

-- Los usuarios pueden ver brands de su organización
CREATE POLICY "Users can view brands in their organization"
  ON brands FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Owners, admins y ops pueden insertar brands
CREATE POLICY "Owners, admins and ops can insert brands"
  ON brands FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = brands.organization_id
      AND role IN ('owner', 'admin', 'ops')
    )
  );

-- Owners, admins y ops pueden actualizar brands
CREATE POLICY "Owners, admins and ops can update brands"
  ON brands FOR UPDATE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = brands.organization_id
      AND role IN ('owner', 'admin', 'ops')
    )
  );

-- Solo owners y admins pueden eliminar brands
CREATE POLICY "Owners and admins can delete brands"
  ON brands FOR DELETE
  USING (
    organization_id = auth.user_organization_id()
    AND EXISTS (
      SELECT 1 FROM memberships
      WHERE user_id = auth.uid()
      AND organization_id = brands.organization_id
      AND role IN ('owner', 'admin')
    )
  );

-- =====================================================
-- POLÍTICAS: AUDIT_LOG
-- =====================================================

-- Los usuarios pueden ver audit logs de su organización
CREATE POLICY "Users can view audit logs in their organization"
  ON audit_log FOR SELECT
  USING (organization_id = auth.user_organization_id());

-- Todos los usuarios autenticados pueden insertar audit logs
-- (esto se hará desde triggers o funciones del servidor)
CREATE POLICY "Authenticated users can insert audit logs"
  ON audit_log FOR INSERT
  WITH CHECK (
    organization_id = auth.user_organization_id()
    AND user_id = auth.uid()
  );

-- NADIE puede actualizar o eliminar audit logs (inmutables)
-- No se crean políticas UPDATE/DELETE, por lo que están bloqueados por defecto

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON FUNCTION auth.user_organization_id IS 'Obtiene el organization_id del usuario actual basado en su membership';
COMMENT ON POLICY "Users can view their own organization" ON organizations IS 'Los usuarios solo pueden ver su propia organización';
COMMENT ON POLICY "Users can view memberships in their organization" ON memberships IS 'Los usuarios pueden ver todas las memberships de su organización';
COMMENT ON POLICY "Users can view brands in their organization" ON brands IS 'Los usuarios pueden ver todas las marcas de su organización';
COMMENT ON POLICY "Users can view audit logs in their organization" ON audit_log IS 'Los usuarios pueden ver todos los logs de auditoría de su organización';
