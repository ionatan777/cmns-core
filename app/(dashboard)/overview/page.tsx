"use client"

import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

export default function OverviewPage() {
    const [summary, setSummary] = useState({
        total_balance: 0,
        weekly_net: 0,
        weekly_target: 250, // Meta ejemplo
        accounts: [] as any[],
        loading: true
    })

    const [funds, setFunds] = useState<any[]>([])

    useEffect(() => {
        const loadData = async () => {
            const supabase = createClient()

            // 1. Get Accounts & Total Balance
            const { data: accounts } = await supabase
                .from('accounts')
                .select('id, name, balance, type')
                .order('name')

            const totalBalance = accounts?.reduce((sum, acc) => sum + Number(acc.balance), 0) || 0

            // 2. Get Weekly Net (Income this week)
            const startOfWeek = new Date();
            startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay()); // Sunday

            const { data: transactions } = await supabase
                .from('transactions')
                .select('amount, type')
                .gte('date', startOfWeek.toISOString())

            const weeklyIncome = transactions
                ?.filter(t => t.type === 'income')
                .reduce((sum, t) => sum + Number(t.amount), 0) || 0

            const weeklyExpense = transactions
                ?.filter(t => t.type === 'expense')
                .reduce((sum, t) => sum + Number(t.amount), 0) || 0

            const weeklyNet = weeklyIncome - weeklyExpense

            // 3. Get Funds for Alerts
            const { data: fundsData } = await supabase.from('funds').select('*')

            // Calculate fund balances (simplified for UI, ideally use RPC)
            // For now just storing funds to check "Deuda" goal
            if (fundsData) setFunds(fundsData)

            setSummary({
                total_balance: totalBalance,
                weekly_net: weeklyNet,
                weekly_target: 250,
                accounts: accounts || [],
                loading: false
            })
        }

        loadData()
    }, [])

    const netPercentage = (summary.weekly_net / summary.weekly_target) * 100

    // Find Debt Fund status
    const debtFund = funds.find(f => f.name === 'Deuda')

    const handleResetData = async () => {
        if (!confirm('¿Estás SEGURO? Esto borrará TODAS las transacciones y reseteará el sistema a: $0 Saldo, $4k Deuda, $110 Inversión.')) return

        try {
            const supabase = createClient()

            // 1. Delete all transactions (cascade should handle splits if configured, otherwise delete splits first)
            // Note: RLS must allow this.
            const { error: txError } = await supabase.from('transactions').delete().neq('id', '00000000-0000-0000-0000-000000000000')
            if (txError) throw txError

            // 2. Reset Accounts
            const { error: accError } = await supabase.from('accounts').update({ balance: 0 }).neq('id', '00000000-0000-0000-0000-000000000000')
            if (accError) throw accError

            // 3. Update Debt Goal
            await supabase.from('funds').update({ goal_amount: 4000 }).eq('name', 'Deuda')

            // 4. Create Initial Seed Transaction ($110 Income)
            // First get account & fund IDs
            const { data: accounts } = await supabase.from('accounts').select('id').eq('type', 'cash').limit(1)
            const { data: funds } = await supabase.from('funds').select('id').eq('name', 'Capital de Inversión').limit(1)

            if (accounts?.[0] && funds?.[0]) {
                // Create Transaction
                const { data: tx, error: seedError } = await supabase.from('transactions').insert({
                    amount: 110,
                    type: 'income',
                    category: 'Capital Inicial',
                    note: 'Semilla inicial (Neto Semanal)',
                    date: new Date().toISOString(),
                    account_id: accounts[0].id
                }).select().single()

                if (seedError) throw seedError

                // Update Account Balance
                await supabase.from('accounts').update({ balance: 110 }).eq('id', accounts[0].id)

                // Create Split
                await supabase.from('transaction_splits').insert({
                    transaction_id: tx.id,
                    fund_id: funds[0].id,
                    amount: 110
                })
            }

            alert('Sistema reseteado correctamente. Recargando...')
            window.location.reload()

        } catch (e: any) {
            console.error(e)
            alert('Error al resetear: ' + e.message)
        }
    }

    return (
        <div className="flex min-h-screen flex-col">
            {/* Header */}
            <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
                <div className="flex h-16 items-center gap-4 px-6">
                    <h1 className="text-xl font-semibold">Dashboard</h1>
                    <div className="ml-auto flex items-center gap-4">
                        <span className="text-sm text-muted-foreground">
                            {new Date().toLocaleDateString('es-ES', {
                                weekday: 'long',
                                year: 'numeric',
                                month: 'long',
                                day: 'numeric'
                            })}
                        </span>
                        <Button size="sm" asChild>
                            <a href="/finance/new">+ Transacción</a>
                        </Button>
                    </div>
                </div>
            </header>

            {/* Content */}
            <div className="flex-1 space-y-6 p-6">
                {/* Welcome Section */}
                <div className="rounded-lg border bg-card p-8">
                    <div className="flex items-center gap-3">
                        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-2xl text-primary-foreground">
                            CM
                        </div>
                        <div>
                            <h2 className="text-2xl font-bold">¡Bienvenido a GRUPO CMNS!</h2>
                            <p className="text-muted-foreground">
                                Sistema de gestión multi-marca para Camvys, CodelyLabs y Zypher
                            </p>
                        </div>
                    </div>
                </div>

                {/* Financial Summary */}
                <div className="grid gap-4 md:grid-cols-3">
                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Saldo Total (Activos)</CardDescription>
                            <CardTitle className="text-3xl">
                                {summary.loading ? '...' : `$${summary.total_balance.toFixed(2)}`}
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-1 text-sm">
                                {summary.loading ? (
                                    <p className="text-muted-foreground">Cargando cuentas...</p>
                                ) : (
                                    summary.accounts.map((account, i) => (
                                        <div key={i} className="flex justify-between text-muted-foreground">
                                            <span>{account.name}</span>
                                            <span>${Number(account.balance).toFixed(2)}</span>
                                        </div>
                                    ))
                                )}
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Neto Semanal</CardDescription>
                            <CardTitle className="text-3xl">
                                <span className={netPercentage >= 0 ? 'text-green-600' : 'text-red-600'}>
                                    {summary.loading ? '...' : `$${summary.weekly_net.toFixed(2)}`}
                                </span>
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-2">
                                <div className="flex items-center justify-between text-sm">
                                    <span className="text-muted-foreground">Meta: ${summary.weekly_target.toFixed(2)}</span>
                                    <Badge variant={netPercentage >= 100 ? 'default' : 'secondary'}>
                                        {netPercentage.toFixed(0)}%
                                    </Badge>
                                </div>
                                <div className="relative h-2 w-full overflow-hidden rounded-full bg-secondary">
                                    <div
                                        className={`h-full rounded-full ${netPercentage >= 100 ? 'bg-green-500' : 'bg-yellow-500'}`}
                                        style={{ width: `${Math.min(Math.max(netPercentage, 0), 100)}%` }}
                                    />
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Estado de Deuda</CardDescription>
                            <CardTitle className="text-3xl text-red-500">
                                {debtFund ? `$${Number(debtFund.goal_amount).toFixed(2)}` : '$0.00'}
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <p className="text-sm text-muted-foreground">
                                Meta de liquidación pendiente.
                            </p>
                            <div className="flex gap-2">
                                <Button className="w-full justify-start" variant="outline" size="sm" asChild>
                                    <a href="/finance/new">+ Abonar</a>
                                </Button>
                                <Button className="w-full justify-start" variant="outline" size="sm" asChild>
                                    <a href="/finance/funds">📊 Ver Detalles</a>
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* System Status Cards */}
                <div className="grid gap-4 md:grid-cols-3">
                    <div className="rounded-lg border bg-card p-6">
                        <div className="flex items-center gap-2">
                            <div className="text-2xl">🏢</div>
                            <div>
                                <p className="text-sm font-medium text-muted-foreground">Marcas Activas</p>
                                <p className="text-2xl font-bold">3</p>
                            </div>
                        </div>
                    </div>

                    <div className="rounded-lg border bg-card p-6">
                        <div className="flex items-center gap-2">
                            <div className="text-2xl">🔧</div>
                            <div>
                                <p className="text-sm font-medium text-muted-foreground">Estado del Sistema</p>
                                <p className="text-2xl font-bold text-green-600">En Línea</p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Danger Zone */}
                <div className="mt-8 border-t pt-8">
                    <Button variant="destructive" size="sm" onClick={handleResetData}>
                        ⚠️ Resetear Datos del Sistema
                    </Button>
                </div>
            </div>
        </div>
    )
}
