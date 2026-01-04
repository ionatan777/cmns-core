// =====================================================
// CMNS Core - Finance Module Types
// =====================================================

export type AccountType = 'bank' | 'cash'
export type TransactionType = 'income' | 'expense' | 'transfer'
export type MembershipRole = 'owner' | 'admin' | 'sales' | 'ops'
export type BrandName = 'camvys' | 'codelylabs' | 'zypher'

export interface Organization {
    id: string
    name: string
    slug: string
    logo_url?: string
    primary_color: string
    secondary_color: string
    timezone: string
    base_currency: string
    created_at: string
    updated_at: string
}

export interface Brand {
    id: string
    organization_id: string
    name: BrandName
    status: 'active' | 'inactive' | 'archived'
    logo_url?: string
    description?: string
    channels_enabled: Record<string, boolean>
    default_rules: Record<string, any>
    created_at: string
    updated_at: string
}

export interface Account {
    id: string
    organization_id: string
    brand_id?: string
    name: string
    type: AccountType
    currency: string
    balance: number
    account_number?: string
    bank_name?: string
    metadata: Record<string, any>
    created_at: string
    updated_at: string
}

export interface Fund {
    id: string
    organization_id: string
    name: string
    description?: string
    goal_amount?: number
    goal_date?: string
    locked: boolean
    color: string
    created_at: string
    updated_at: string
    // Computed field
    current_balance?: number
}

export interface Transaction {
    id: string
    organization_id: string
    brand_id?: string
    brand?: Brand
    date: string
    type: TransactionType
    amount: number
    account_id: string
    account?: Account
    category?: string
    note?: string
    ref_type?: string
    ref_id?: string
    metadata: Record<string, any>
    created_at: string
    updated_at: string
    created_by?: string
    // Related data
    splits?: TransactionSplit[]
}

export interface TransactionSplit {
    id: string
    transaction_id: string
    fund_id: string
    fund?: Fund
    amount: number
    created_at: string
}

export interface AllocationRule {
    id: string
    organization_id: string
    brand_id?: string
    category?: string
    tx_type: TransactionType
    split_config: {
        fund_id: string
        percentage: number
    }[]
    active: boolean
    description?: string
    created_at: string
    updated_at: string
}

// Form types
export interface CreateTransactionInput {
    brand_id?: string
    date: string
    type: TransactionType
    amount: number
    account_id: string
    category?: string
    note?: string
    ref_type?: string
    ref_id?: string
    metadata?: Record<string, any>
}

export interface CreateAccountInput {
    brand_id?: string
    name: string
    type: AccountType
    currency?: string
    balance?: number
    account_number?: string
    bank_name?: string
}

export interface CreateFundInput {
    name: string
    description?: string
    goal_amount?: number
    goal_date?: string
    color?: string
    locked?: boolean
}

// Dashboard types
export interface FinancialSummary {
    total_balance: number
    weekly_net: number
    weekly_target: number
    accounts: Account[]
    funds: (Fund & { current_balance: number; progress_percentage: number })[]
}

export interface Alert {
    id: string
    type: 'warning' | 'error' | 'info' | 'success'
    title: string
    message: string
    action?: {
        label: string
        href: string
    }
}
