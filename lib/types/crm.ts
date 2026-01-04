// =====================================================
// CRM Module Types
// =====================================================

export interface Contact {
    id: string
    organization_id: string
    name: string
    phone: string
    business_name: string | null
    city: string | null
    tags: string[]
    source: 'maps' | 'tiktok' | 'referral' | 'other'
    created_at: string
    updated_at: string
}

export interface Pipeline {
    id: string
    organization_id: string
    brand_id: string | null
    name: string
    created_at: string
    updated_at: string
    stages?: PipelineStage[]
}

export interface PipelineStage {
    id: string
    pipeline_id: string
    name: string
    order_num: number
    color: string
    created_at: string
    updated_at: string
}

export interface Lead {
    id: string
    organization_id: string
    brand_id: string | null
    contact_id: string
    product: string
    value_estimated: number | null
    stage_id: string
    status: 'active' | 'won' | 'lost' | 'archived'
    last_contact_at: string | null
    created_at: string
    updated_at: string
    created_by: string | null

    // Relations (populated via joins)
    contact?: Contact
    stage?: PipelineStage
    brand?: {
        id: string
        name: string
    }
}

export interface Interaction {
    id: string
    lead_id: string
    channel: 'whatsapp' | 'dm' | 'call' | 'email' | 'meeting'
    message: string
    created_at: string
    created_by: string | null
}

export interface Task {
    id: string
    organization_id: string
    lead_id: string | null
    type: 'call' | 'message' | 'meeting' | 'proposal' | 'other'
    title: string
    description: string | null
    due_at: string
    status: 'pending' | 'completed' | 'cancelled'
    owner_user_id: string
    created_at: string
    updated_at: string

    // Relations
    lead?: Lead
}

// Helper types for forms
export interface CreateContactInput {
    name: string
    phone: string
    business_name?: string
    city?: string
    tags?: string[]
    source: Contact['source']
}

export interface CreateLeadInput {
    brand_id?: string
    contact_id: string
    product: string
    value_estimated?: number
    stage_id: string
}

export interface CreateInteractionInput {
    lead_id: string
    channel: Interaction['channel']
    message: string
}

export interface CreateTaskInput {
    lead_id?: string
    type: Task['type']
    title: string
    description?: string
    due_at: Date
    owner_user_id: string
}
