import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default async function ReportsPage() {
    const supabase = await createClient()

    // Weekly net (last 8 weeks)
    const { data: weeklyNet } = await supabase
        .from('weekly_net_report')
        .select('*')
        .order('week_start', { ascending: false })
        .limit(8)

    const currentWeekNet = weeklyNet?.[0]?.net || 0
    const lastWeekNet = weeklyNet?.[1]?.net || 0

    // Stats Overview
    const thisMonth = new Date()
    thisMonth.setDate(1)

    const { data: monthlyTransactions } = await supabase
        .from('transactions')
        .select('type, amount')
        .gte('date', thisMonth.toISOString())

    const monthlyIncome = monthlyTransactions?.filter(t => t.type === 'income').reduce((sum, t) => sum + t.amount, 0) || 0
    const monthlyExpenses = monthlyTransactions?.filter(t => t.type === 'expense').reduce((sum, t) => sum + t.amount, 0) || 0
    const monthlyNet = monthlyIncome - monthlyExpenses

    const { data: activeOrders } = await supabase
        .from('orders')
        .select('id')
        .in('status', ['pending', 'confirmed', 'preparing'])

    const { data: activeProjects } = await supabase
        .from('projects')
        .select('id')
        .eq('status', 'in_progress')

    return (
        <div className="space-y-6 p-6">
            <div>
                <h1 className="text-3xl font-bold">CMNS Intelligence</h1>
                <p className="text-muted-foreground">Reportes y Analítica</p>
            </div>

            <Tabs defaultValue="overview" className="space-y-4">
                <TabsList>
                    <TabsTrigger value="overview">Overview</TabsTrigger>
                    <TabsTrigger value="codelylabs">CodelyLabs</TabsTrigger>
                    <TabsTrigger value="camvys">Camvys</TabsTrigger>
                    <TabsTrigger value="zypher">Zypher</TabsTrigger>
                </TabsList>

                {/* Overview Tab */}
                <TabsContent value="overview" className="space-y-4">
                    {/* Top Stats */}
                    <div className="grid gap-4 md:grid-cols-4">
                        <Card>
                            <CardHeader className="pb-2">
                                <div className="text-sm text-muted-foreground">Neto Este Mes</div>
                                <div className={`text-2xl font-bold ${monthlyNet >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                                    ${monthlyNet.toFixed(2)}
                                </div>
                            </CardHeader>
                        </Card>
                        <Card>
                            <CardHeader className="pb-2">
                                <div className="text-sm text-muted-foreground">Neto Esta Semana</div>
                                <div className={`text-2xl font-bold ${currentWeekNet >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                                    ${currentWeekNet.toFixed(2)}
                                </div>
                            </CardHeader>
                        </Card>
                        <Card>
                            <CardHeader className="pb-2">
                                <div className="text-sm text-muted-foreground">Órdenes Activas</div>
                                <div className="text-2xl font-bold">{activeOrders?.length || 0}</div>
                            </CardHeader>
                        </Card>
                        <Card>
                            <CardHeader className="pb-2">
                                <div className="text-sm text-muted-foreground">Proyectos Activos</div>
                                <div className="text-2xl font-bold">{activeProjects?.length || 0}</div>
                            </CardHeader>
                        </Card>
                    </div>

                    {/* Weekly Net Trend */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Neto Semanal (Últimas 8 Semanas)</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-2">
                                {weeklyNet?.map((week: any) => (
                                    <div key={week.week_start} className="flex items-center gap-4">
                                        <div className="text-sm w-28">
                                            {new Date(week.week_start).toLocaleDateString('es-ES', { month: 'short', day: 'numeric' })}
                                        </div>
                                        <div className="flex-1 h-8 bg-gray-100 rounded-full overflow-hidden relative">
                                            <div
                                                className={`h-full ${week.net >= 0 ? 'bg-green-500' : 'bg-red-500'}`}
                                                style={{ width: `${Math.min(Math.abs(week.net) / 10, 100)}%` }}
                                            />
                                        </div>
                                        <div className={`text-sm font-semibold w-24 text-right ${week.net >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                                            ${week.net.toFixed(2)}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* CodelyLabs Tab */}
                <TabsContent value="codelylabs">
                    <Card>
                        <CardHeader>
                            <CardTitle>Funnel de Landings</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground text-sm mb-4">
                                Ejecuta las migraciones de reportes para ver el funnel completo
                            </p>
                            <div className="text-sm text-gray-600">
                                Próximo: Prospectados → Propuestas → Ganados → Entregados
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Camvys Tab */}
                <TabsContent value="camvys" className="space-y-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Pedidos Por Entregar</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground text-sm">
                                {activeOrders?.length || 0} órdenes pendientes de entrega
                            </p>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Stock Bajo</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground text-sm">
                                Ejecuta las migraciones para ver productos con stock crítico
                            </p>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Zypher Tab */}
                <TabsContent value="zypher">
                    <Card>
                        <CardHeader>
                            <CardTitle>Preventa Activa (Drops)</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-muted-foreground text-sm">
                                Análisis de drops disponible después de ejecutar migraciones
                            </p>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}
