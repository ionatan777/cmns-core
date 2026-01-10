"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { createClient } from "@/lib/supabase/client"

export default function NewTransactionPage() {
    const [type, setType] = useState<'income' | 'expense'>('income')
    const [amount, setAmount] = useState('')
    const [category, setCategory] = useState('')
    const [note, setNote] = useState('')
    const [loading, setLoading] = useState(false)

    // Data states
    const [brands, setBrands] = useState<any[]>([])
    const [accounts, setAccounts] = useState<any[]>([])
    const [selectedBrandId, setSelectedBrandId] = useState('')
    const [selectedAccountId, setSelectedAccountId] = useState('')
    const [organizationId, setOrganizationId] = useState<string | null>(null)

    // Load initial data
    useState(() => {
        const loadData = async () => {
            const supabase = createClient()

            // 1. Get Organization (simplest approach: take the first one)
            const { data: orgs } = await supabase.from('organizations').select('id').limit(1)
            if (orgs && orgs.length > 0) setOrganizationId(orgs[0].id)

            // 2. Get Brands
            const { data: brandsData } = await supabase.from('brands').select('id, name').order('name')
            if (brandsData) setBrands(brandsData)

            // 3. Get Accounts
            const { data: accountsData } = await supabase.from('accounts').select('id, name, type').order('name')
            if (accountsData) setAccounts(accountsData)
        }
        loadData()
    })

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!amount || !selectedAccountId || !organizationId) {
            alert('Por favor completa los campos requeridos')
            return
        }

        setLoading(true)
        try {
            const supabase = createClient()

            const { data, error } = await supabase.rpc('create_transaction', {
                p_organization_id: organizationId,
                p_brand_id: selectedBrandId || null,
                p_date: new Date().toISOString().split('T')[0],
                p_type: type,
                p_amount: parseFloat(amount),
                p_account_id: selectedAccountId,
                p_category: category,
                p_note: note
            })

            if (error) throw error

            alert('✅ Transacción registrada exitosamente')
            // Reset form or redirect
            setAmount('')
            setNote('')
        } catch (error: any) {
            console.error('Error:', error)
            alert('Error creando transacción: ' + error.message)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="flex min-h-screen flex-col">
            {/* Header */}
            <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
                <div className="flex h-16 items-center gap-4 px-6">
                    <h1 className="text-xl font-semibold">Nueva Transacción</h1>
                    <div className="ml-auto">
                        <Button variant="ghost" asChild>
                            <a href="/finance/transactions">Cancelar</a>
                        </Button>
                    </div>
                </div>
            </header>

            {/* Content */}
            <div className="flex-1 p-6">
                <div className="mx-auto max-w-2xl">
                    <Card>
                        <CardHeader>
                            <CardTitle>Registrar Movimiento</CardTitle>
                            <CardDescription>
                                Registra un ingreso o gasto. El sistema aplicará las reglas de asignación automáticamente.
                            </CardDescription>
                        </CardHeader>
                        <CardContent>
                            <form onSubmit={handleSubmit} className="space-y-6">
                                {/* Tipo de Transacción */}
                                <div className="space-y-2">
                                    <Label>Tipo de Transacción</Label>
                                    <div className="grid grid-cols-2 gap-4">
                                        <Button
                                            type="button"
                                            variant={type === 'income' ? 'default' : 'outline'}
                                            className="h-20"
                                            onClick={() => setType('income')}
                                        >
                                            <div className="text-center">
                                                <div className="text-2xl">💰</div>
                                                <div className="mt-1 font-semibold">Ingreso</div>
                                            </div>
                                        </Button>
                                        <Button
                                            type="button"
                                            variant={type === 'expense' ? 'default' : 'outline'}
                                            className="h-20"
                                            onClick={() => setType('expense')}
                                        >
                                            <div className="text-center">
                                                <div className="text-2xl">💸</div>
                                                <div className="mt-1 font-semibold">Gasto</div>
                                            </div>
                                        </Button>
                                    </div>
                                </div>

                                {/* Monto */}
                                <div className="space-y-2">
                                    <Label htmlFor="amount">Monto (USD)</Label>
                                    <Input
                                        id="amount"
                                        type="number"
                                        step="0.01"
                                        placeholder="0.00"
                                        value={amount}
                                        onChange={(e) => setAmount(e.target.value)}
                                        required
                                        className="text-2xl"
                                    />
                                </div>

                                {/* Marca */}
                                <div className="space-y-2">
                                    <Label htmlFor="brand">Marca</Label>
                                    <Select value={selectedBrandId} onValueChange={setSelectedBrandId}>
                                        <SelectTrigger id="brand">
                                            <SelectValue placeholder="Selecciona una marca (Opcional)" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {brands.map(brand => (
                                                <SelectItem key={brand.id} value={brand.id}>
                                                    {brand.name}
                                                </SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>

                                {/* Cuenta */}
                                <div className="space-y-2">
                                    <Label htmlFor="account">Cuenta</Label>
                                    <Select value={selectedAccountId} onValueChange={setSelectedAccountId}>
                                        <SelectTrigger id="account">
                                            <SelectValue placeholder="Selecciona una cuenta" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {accounts.map(acc => (
                                                <SelectItem key={acc.id} value={acc.id}>
                                                    {acc.name} ({acc.type})
                                                </SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>

                                {/* Categoría */}
                                <div className="space-y-2">
                                    <Label htmlFor="category">Categoría</Label>
                                    <Input
                                        id="category"
                                        placeholder="Ej: Venta Landing, Marketing, Reposición"
                                        value={category}
                                        onChange={(e) => setCategory(e.target.value)}
                                    />
                                    <p className="text-sm text-muted-foreground">
                                        {type === 'income' && '💡 Tip: "Venta Landing" activará la regla de CodelyLabs'}
                                        {type === 'expense' && '💡 Tip: "Marketing" asignará al fondo de Marketing'}
                                    </p>
                                </div>

                                {/* Nota */}
                                <div className="space-y-2">
                                    <Label htmlFor="note">Nota (Opcional)</Label>
                                    <Textarea
                                        id="note"
                                        placeholder="Descripción adicional..."
                                        value={note}
                                        onChange={(e) => setNote(e.target.value)}
                                        rows={3}
                                    />
                                </div>

                                {/* Fecha */}
                                <div className="space-y-2">
                                    <Label htmlFor="date">Fecha</Label>
                                    <Input
                                        id="date"
                                        type="date"
                                        defaultValue={new Date().toISOString().split('T')[0]}
                                        required
                                    />
                                </div>

                                {/* Submit */}
                                <div className="flex gap-4 pt-4">
                                    <Button type="submit" className="flex-1" size="lg" disabled={loading}>
                                        {loading ? 'Guardando...' : 'Registrar Transacción'}
                                    </Button>
                                    <Button type="button" variant="outline" asChild>
                                        <a href="/finance/transactions">Cancelar</a>
                                    </Button>
                                </div>
                            </form>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
