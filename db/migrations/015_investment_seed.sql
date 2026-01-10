-- =====================================================
-- CMNS CORE - 015: Seed Investment Fund
-- Agrega el fondo "Capital de Inversión" solicitado por el usuario
-- =====================================================

DO $$
DECLARE
    v_org_id UUID;
BEGIN
    -- 1. Obtener la organización principal
    -- Intentamos obtener la del seed primero, sino cualquiera disponible
    SELECT id INTO v_org_id 
    FROM organizations 
    WHERE id = '00000000-0000-0000-0000-000000000001';

    IF v_org_id IS NULL THEN
        SELECT id INTO v_org_id FROM organizations LIMIT 1;
    END IF;

    -- 2. Insertar el fondo si tenemos organización
    IF v_org_id IS NOT NULL THEN
        INSERT INTO funds (organization_id, name, description, color, locked)
        VALUES (
            v_org_id,
            'Capital de Inversión',
            'Fondo destinado a capital de reinversión y oportunidades',
            '#d946ef', -- Fuchsia / Magenta para diferenciar
            false
        )
        ON CONFLICT (organization_id, name) DO NOTHING;
    END IF;
END $$;
