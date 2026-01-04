import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

// Mock data - will be replaced with real Supabase data
const financialSummary = {
    total_balance: 3450.00,
    weekly_net: 210.00,
    weekly_target: 250.00,
    accounts: [
        { name: 'Banco Principal', balance: 2500.00 },
        { name: 'Efectivo', balance: 450.00 },
        { name: 'Banco Camvys', balance: 500.00 },
    ],
}

type AlertType = 'info' | 'success' | 'warning' | 'error'

type Alert = {
    id: string
    type: AlertType
    title: string
    message: string
    action: { label: string; href: string } | null
}

const alerts: Alert[] = [
    {
        id: '1',
        type: 'warning',
        title: '⚠️ Neto Semanal Bajo Meta',
        message: '$210/semana vs meta de $250/semana. Necesitas $40 más esta semana.',
        action: { label: 'Ver Transacciones', href: '/finance/transactions' },
    },
    {
        id: '2',
        type: 'info',
        title: '🎓 Universidad: Ritmo Semanal',
        message: 'Necesitas $200/semana para alcanzar $3000 en Marzo 2026 (8 semanas restantes).',
        action: { label: 'Ver Fondos', href: '/finance/funds' },
    },
    {
        id: '3',
        type: 'success',
        title: '✅ Reposición Camvys OK',
        message: 'Tienes $450 asignados. Tope mensual: $115. Estás dentro del límite.',
        action: null,
    },
]

export default function OverviewPage() {
    const netPercentage = (financialSummary.weekly_net / financialSummary.weekly_target) * 100

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

                {/* Alerts */}
                {alerts.length > 0 && (
                    <div className="space-y-3">
                        <h3 className="font-semibold">🔔 Alertas</h3>
                        {alerts.map((alert) => (
                            <Card
                                key={alert.id}
                                className={
                                    alert.type === 'warning' ? 'border-yellow-500 bg-yellow-50 dark:bg-yellow-950' :
                                        alert.type === 'error' ? 'border-red-500 bg-red-50 dark:bg-red-950' :
                                            alert.type === 'success' ? 'border-green-500 bg-green-50 dark:bg-green-950' :
                                                'border-blue-500 bg-blue-50 dark:bg-blue-950'
                                }
                            >
                                <CardContent className="pt-4">
                                    <div className="flex items-start justify-between gap-4">
                                        <div className="flex-1">
                                            <p className="font-medium">{alert.title}</p>
                                            <p className="mt-1 text-sm opacity-80">{alert.message}</p>
                                        </div>
                                        {alert.action && (
                                            <Button size="sm" variant="outline" asChild>
                                                <a href={alert.action.href}>{alert.action.label}</a>
                                            </Button>
                                        )}
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                )}

                {/* Financial Summary */}
                <div className="grid gap-4 md:grid-cols-3">
                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Saldo Total</CardDescription>
                            <CardTitle className="text-3xl">${financialSummary.total_balance.toFixed(2)}</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-1 text-sm">
                                {financialSummary.accounts.map((account, i) => (
                                    <div key={i} className="flex justify-between text-muted-foreground">
                                        <span>{account.name}</span>
                                        <span>${account.balance.toFixed(2)}</span>
                                    </div>
                                ))}
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Neto Semanal</CardDescription>
                            <CardTitle className="text-3xl">
                                <span className={netPercentage >= 100 ? 'text-green-600' : 'text-yellow-600'}>
                                    ${financialSummary.weekly_net.toFixed(2)}
                                </span>
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-2">
                                <div className="flex items-center justify-between text-sm">
                                    <span className="text-muted-foreground">Meta: ${financialSummary.weekly_target.toFixed(2)}</span>
                                    <Badge variant={netPercentage >= 100 ? 'default' : 'secondary'}>
                                        {netPercentage.toFixed(0)}%
                                    </Badge>
                                </div>
                                <div className="relative h-2 w-full overflow-hidden rounded-full bg-secondary">
                                    <div
                                        className={`h-full rounded-full ${netPercentage >= 100 ? 'bg-green-500' : 'bg-yellow-500'}`}
                                        style={{ width: `${Math.min(netPercentage, 100)}%` }}
                                    />
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Acciones Rápidas</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <Button className="w-full justify-start" variant="outline" size="sm" asChild>
                                <a href="/finance/new">+ Registrar Transacción</a>
                            </Button>
                            <Button className="w-full justify-start" variant="outline" size="sm" asChild>
                                <a href="/finance/funds">📊 Ver Fondos</a>
                            </Button>
                            <Button className="w-full justify-start" variant="outline" size="sm" asChild>
                                <a href="/finance/transactions">📝 Ver Historial</a>
                            </Button>
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
                        <div className="mt-4 space-y-1">
                            <div className="flex items-center gap-2 text-sm">
                                <span className="h-2 w-2 rounded-full bg-green-500"></span>
                                <span>Camvys</span>
                            </div>
                            <div className="flex items-center gap-2 text-sm">
                                <span className="h-2 w-2 rounded-full bg-green-500"></span>
                                <span>CodelyLabs</span>
                            </div>
                            <div className="flex items-center gap-2 text-sm">
                                <span className="h-2 w-2 rounded-full bg-green-500"></span>
                                <span>Zypher</span>
                            </div>
                        </div>
                    </div>

                    <div className="rounded-lg border bg-card p-6">
                        <div className="flex items-center gap-2">
                            <div className="text-2xl">🔧</div>
                            <div>
                                <p className="text-sm font-medium text-muted-foreground">Estado del Sistema</p>
                                <p className="text-2xl font-bold text-green-600">Operacional</p>
                            </div>
                        </div>
                        <div className="mt-4">
                            <p className="text-sm text-muted-foreground">
                                Módulo de Finanzas activo y funcional
                            </p>
                        </div>
                    </div>

                    <div className="rounded-lg border bg-card p-6">
                        <div className="flex items-center gap-2">
                            <div className="text-2xl">📋</div>
                            <div>
                                <p className="text-sm font-medium text-muted-foreground">Próximos Pasos</p>
                                <p className="text-2xl font-bold">Configurar Supabase</p>
                            </div>
                        </div>
                        <div className="mt-4">
                            <p className="text-sm text-muted-foreground">
                                Conectar base de datos para datos reales
                            </p>
                        </div>
                    </div>
                </div>

                {/* Roadmap */}
                <div className="rounded-lg border bg-card p-6">
                    <h3 className="mb-4 text-lg font-semibold">🚀 Roadmap de Implementación</h3>
                    <div className="space-y-3">
                        <div className="flex items-start gap-3">
                            <div className="flex h-6 w-6 items-center justify-center rounded-full bg-green-500 text-xs font-bold text-white">
                                ✓
                            </div>
                            <div>
                                <p className="font-medium">Semana 1: Base de datos + RLS + Core + Finanzas</p>
                                <p className="text-sm text-muted-foreground">
                                    Schema creado ✓ | Finanzas MVP ✓ | Pendiente: Conectar Supabase
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start gap-3">
                            <div className="flex h-6 w-6 items-center justify-center rounded-full bg-muted text-xs font-bold">
                                2
                            </div>
                            <div>
                                <p className="font-medium">Semana 3: CRM + Pipeline + Tareas</p>
                                <p className="text-sm text-muted-foreground">
                                    Contacts, Leads, Stages (kanban), Tasks, Plantillas
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start gap-3">
                            <div className="flex h-6 w-6 items-center justify-center rounded-full bg-muted text-xs font-bold">
                                3
                            </div>
                            <div>
                                <p className="font-medium">Semana 4: Proyectos + Mantenimiento</p>
                                <p className="text-sm text-muted-foreground">
                                    Projects, Checklist publicación, Contratos de mantenimiento
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
