// =====================================================
// Projects & Inventory & Orders Types
// =====================================================

// ========== PROJECTS ==========

export interface Project {
    id: string
    organization_id: string
    brand_id: string
    lead_id: string | null
    client_name: string
    domain: string | null
    status: 'draft' | 'in_progress' | 'completed' | 'suspended'
    published_url: string | null
    preview_screenshot_url: string | null
    created_at: string
    updated_at: string
    completed_at: string | null
    created_by: string | null
}

export interface ProjectChecklistItem {
    id: string
    project_id: string
    item: string
    done: boolean
    order_num: number
    completed_at: string | null
    completed_by: string | null
    created_at: string
}

export interface MaintenanceContract {
    id: string
    organization_id: string
    project_id: string
    monthly_fee: number
    hosting_included: boolean
    status: 'active' | 'suspended' | 'cancelled'
    next_billing_date: string
    last_payment_date: string | null
    created_at: string
    updated_at: string
}

// ========== INVENTORY ==========

export interface Product {
    id: string
    organization_id: string
    brand_id: string
    name: string
    sku: string
    description: string | null
    cost: number
    price: number
    active: boolean
    category: string | null
    image_url: string | null
    created_at: string
    updated_at: string
}

export interface InventoryMovement {
    id: string
    product_id: string
    type: 'in' | 'out' | 'adjust'
    qty: number
    cost: number | null
    note: string | null
    ref_order_id: string | null
    created_at: string
    created_by: string | null
}

export interface ReorderPolicy {
    id: string
    product_id: string
    stock_min: number
    reorder_point: number
    lead_time_days: number
    created_at: string
    updated_at: string
}

// ========== ORDERS ==========

export interface Order {
    id: string
    organization_id: string
    brand_id: string
    contact_id: string
    order_number: string
    status: 'pending' | 'confirmed' | 'preparing' | 'shipped' | 'delivered' | 'cancelled'
    total: number
    paid: boolean
    delivery_method: 'pickup' | 'delivery' | 'shipping'
    delivery_address: string | null
    notes: string | null
    is_drop: boolean
    created_at: string
    updated_at: string
    created_by: string | null

    // Relations
    contact?: {
        name: string
        business_name: string | null
        phone: string
    }
    brand?: {
        name: string
    }
}

export interface OrderItem {
    id: string
    order_id: string
    product_id: string
    qty: number
    unit_price: number
    subtotal: number
    created_at: string

    // Relations
    product?: Product
}

export interface Payment {
    id: string
    organization_id: string
    order_id: string
    transaction_id: string | null
    amount: number
    payment_method: string
    payment_date: string
    notes: string | null
    created_at: string
}
