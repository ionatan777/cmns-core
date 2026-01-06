-- =====================================================
-- CMNS CORE - MIGRACIÓN COMPLETA PARA NEON
-- Ejecutar en: https://console.neon.tech (SQL Editor)
-- Fecha: Enero 2026 - Inicio limpio
-- =====================================================

-- =========================================
-- 1. TABLA DE USUARIOS DE LA APLICACIÓN
-- =========================================
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT DEFAULT '',
    role TEXT DEFAULT 'user' CHECK (role IN ('owner', 'admin', 'user')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    avatar_url TEXT,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);

-- Usuario administrador inicial
INSERT INTO app_users (email, password_hash, name, role, status)
VALUES (
    'codelylabs.tech@yahoo.com',
    'bWF5YTIwMjYu',
    'Admin CMNS',
    'owner',
    'active'
) ON CONFLICT (email) DO NOTHING;

-- =========================================
-- 2. TABLA DE TRANSACCIONES FINANCIERAS
-- =========================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
    amount DECIMAL(12,2) NOT NULL,
    description TEXT,
    category TEXT,
    brand TEXT, -- camvys, zypher, codelylabs, personal
    fund TEXT, -- efectivo, banco, paypal, etc
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by UUID REFERENCES app_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_brand ON transactions(brand);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- =========================================
-- 3. TABLA DE FONDOS (CUENTAS)
-- =========================================
CREATE TABLE IF NOT EXISTS funds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT DEFAULT 'bank' CHECK (type IN ('cash', 'bank', 'digital', 'other')),
    balance DECIMAL(12,2) DEFAULT 0,
    currency TEXT DEFAULT 'USD',
    brand TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fondos iniciales (vacíos, balance 0)
INSERT INTO funds (name, type, balance, brand) VALUES
    ('Efectivo Personal', 'cash', 0, 'personal'),
    ('Banco Principal', 'bank', 0, 'personal'),
    ('Caja Camvys', 'cash', 0, 'camvys'),
    ('Caja Zypher', 'cash', 0, 'zypher'),
    ('PayPal CodelyLabs', 'digital', 0, 'codelylabs')
ON CONFLICT DO NOTHING;

-- =========================================
-- 4. TABLA DE TAREAS CRM
-- =========================================
CREATE TABLE IF NOT EXISTS crm_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date DATE,
    brand TEXT,
    assigned_to UUID REFERENCES app_users(id),
    created_by UUID REFERENCES app_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crm_tasks_status ON crm_tasks(status);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_due_date ON crm_tasks(due_date);

-- =========================================
-- 5. TABLA DE INVENTARIO
-- =========================================
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    brand TEXT NOT NULL, -- camvys, zypher
    category TEXT,
    price DECIMAL(10,2) DEFAULT 0,
    cost DECIMAL(10,2) DEFAULT 0,
    stock INT DEFAULT 0,
    min_stock INT DEFAULT 5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_brand ON inventory(brand);
CREATE INDEX IF NOT EXISTS idx_inventory_sku ON inventory(sku);

-- =========================================
-- 6. TABLA DE ÓRDENES
-- =========================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE,
    brand TEXT NOT NULL,
    customer_name TEXT,
    customer_email TEXT,
    customer_phone TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    subtotal DECIMAL(10,2) DEFAULT 0,
    shipping DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_brand ON orders(brand);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- =========================================
-- 7. TABLA DE ITEMS DE ÓRDENES
-- =========================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES inventory(id),
    product_name TEXT,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2),
    subtotal DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================
-- 8. TABLA DE METAS
-- =========================================
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    target_amount DECIMAL(12,2),
    current_amount DECIMAL(12,2) DEFAULT 0,
    type TEXT DEFAULT 'income' CHECK (type IN ('income', 'savings', 'sales', 'other')),
    brand TEXT,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================
-- VERIFICACIÓN
-- =========================================
DO $$
BEGIN
    RAISE NOTICE '✅ Migración completada exitosamente';
    RAISE NOTICE '✅ Tablas creadas: app_users, transactions, funds, crm_tasks, inventory, orders, order_items, goals';
    RAISE NOTICE '✅ Usuario admin: codelylabs.tech@yahoo.com';
    RAISE NOTICE '✅ Todo inicia en 0 - listo para empezar!';
END $$;
