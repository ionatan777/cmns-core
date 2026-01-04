-- =====================================================
-- CMNS CORE - 001: Tablas Core
-- Fase 1 (Semana 1): Base de datos + Core
-- =====================================================

-- =====================================================
-- 1. ORGANIZATIONS (Organizaciones)
-- =====================================================
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  primary_color TEXT DEFAULT '#000000',
  secondary_color TEXT DEFAULT '#FFFFFF',
  timezone TEXT DEFAULT 'America/New_York',
  base_currency TEXT DEFAULT 'USD',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 2. MEMBERSHIPS (Usuario-Organización-Rol)
-- =====================================================
CREATE TYPE membership_role AS ENUM ('owner', 'admin', 'sales', 'ops');

CREATE TABLE memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role membership_role NOT NULL DEFAULT 'ops',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Un usuario solo puede tener una membresía por organización
  UNIQUE(organization_id, user_id)
);

-- =====================================================
-- 3. BRANDS (Marcas)
-- =====================================================
CREATE TYPE brand_name AS ENUM ('camvys', 'codelylabs', 'zypher');
CREATE TYPE brand_status AS ENUM ('active', 'inactive', 'archived');

CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name brand_name NOT NULL,
  status brand_status NOT NULL DEFAULT 'active',
  logo_url TEXT,
  description TEXT,
  
  -- Canales permitidos por marca
  channels_enabled JSONB DEFAULT '{"web": true, "email": true, "phone": true}'::jsonb,
  
  -- Reglas default por marca (ej: términos de pago, políticas)
  default_rules JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Una marca solo puede existir una vez por organización
  UNIQUE(organization_id, name)
);

-- =====================================================
-- 4. AUDIT_LOG (Registro de Auditoría)
-- =====================================================
CREATE TYPE audit_action AS ENUM ('create', 'update', 'delete', 'reverse');

CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Qué tabla/entidad se modificó
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  
  -- Tipo de acción
  action audit_action NOT NULL,
  
  -- Estado antes y después (JSON)
  before JSONB,
  after JSONB,
  
  -- Metadata adicional (IP, user agent, razón del cambio, etc.)
  metadata JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- ÍNDICES para performance
-- =====================================================
CREATE INDEX idx_memberships_organization_id ON memberships(organization_id);
CREATE INDEX idx_memberships_user_id ON memberships(user_id);
CREATE INDEX idx_brands_organization_id ON brands(organization_id);
CREATE INDEX idx_brands_status ON brands(status);
CREATE INDEX idx_audit_log_organization_id ON audit_log(organization_id);
CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);

-- =====================================================
-- TRIGGERS para updated_at automático
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_memberships_updated_at BEFORE UPDATE ON memberships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE organizations IS 'Organizaciones o holdings que agrupan múltiples marcas';
COMMENT ON TABLE memberships IS 'Relación entre usuarios y organizaciones con roles específicos';
COMMENT ON TABLE brands IS 'Marcas individuales dentro de una organización (camvys/codelylabs/zypher)';
COMMENT ON TABLE audit_log IS 'Registro de auditoría para trazabilidad completa (crítico para finanzas)';
