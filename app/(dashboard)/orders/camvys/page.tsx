import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

export default async function CamvysOrdersPage() {
    const supabase = await createClient()

    // Obtener marca Camvys
    const { data: camvysBrand, error: brandError } = await supabase
        .from('brands')
        .select('id')
        .eq('name', 'camvys')
        .single()

    if (brandError || !camvysBrand) {
        return (
            <div className="space-y-6 p-6">
                <h1 className="text-3xl font-bold">Órdenes Camvys</h1>
                <Card className="border-2 border-dashed">
                    <CardContent className="p-8 text-center">
                        <p className="text-muted-foreground">
                            Ejecuta las migraciones SQL primero: <code>EJECUTAR_PROJECTS_INVENTORY.sql</code>
                        </p>
                    </CardContent>
                </Card>
            </div>
        )
    }

    const { data: orders } = await supabase
        .from('orders')
        .select(`
      *,
      contact:contacts(name, business_name),
      items:order_items(id)
    `)
        .eq('brand_id', camvysBrand.id)
        .order('created_at', { ascending: false })

    const stats = {
        total: orders?.length || 0,
        pending: orders?.filter(o => o.status === 'pending').length || 0,
        confirmed: orders?.filter(o => o.status === 'confirmed').length || 0,
        totalRevenue: orders?.reduce((sum, o) => sum + (o.paid ? o.total : 0), 0) || 0,
    }

    const getStatusBadge = (status: string) => {
        const config: Record<string, any> = {
            pending: { label: 'Pendiente', variant: 'secondary' },
            confirmed: { label: 'Confirmado', variant: 'default' },
            preparing: { label: 'Preparando', variant: 'default' },
            shipped: { label: 'Enviado', variant: 'default' },
            delivered: { label: 'Entregado', className: 'bg-green-600' },
            cancelled: { label: 'Cancelado', variant: 'destructive' },
        }
        const c = config[status] || config.pending
        return <Badge variant={c.variant} className={c.className}>{c.label}</Badge>
    }

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Órdenes Camvys</h1>
                    <p className="text-muted-foreground">E-commerce y Ventas Directas</p>
                </div>
                <Button asChild>
                    <Link href="/orders/camvys/new">+ Nueva Orden</Link>
                </Button>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-4">
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Total Órdenes</div>
                        <div className="text-2xl font-bold">{stats.total}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Pendientes</div>
                        <div className="text-2xl font-bold text-orange-600">{stats.pending}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Confirmadas</div>
                        <div className="text-2xl font-bold text-blue-600">{stats.confirmed}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Ingresos</div>
                        <div className="text-2xl font-bold text-green-600">${stats.totalRevenue.toFixed(2)}</div>
                    </CardHeader>
                </Card>
            </div>

            {/* Orders List */}
            <Card>
                <CardHeader>
                    <CardTitle>Lista de Órdenes Camvys</CardTitle>
                </CardHeader>
                <CardContent>
                    {!orders || orders.length === 0 ? (
                        <div className="text-center py-8 text-muted-foreground">
                            No hay órdenes registradas para Camvys
                        </div>
                    ) : (
                        <div className="space-y-3">
                            {orders.map((order: any) => (
                                <Link
                                    key={order.id}
                                    href={`/orders/${order.id}`}
                                    className="block border rounded-lg p-4 hover:bg-muted/50 transition-colors"
                                >
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2 mb-1">
                                                <span className="font-mono font-semibold">{order.order_number}</span>
                                                {getStatusBadge(order.status)}
                                                {order.paid && <Badge variant="outline" className="text-green-600">Pagado</Badge>}
                                            </div>
                                            <div className="text-sm">
                                                {order.contact?.business_name || order.contact?.name}
                                            </div>
                                            <div className="text-xs text-muted-foreground">
                                                {order.items?.length || 0} items • {order.delivery_method}
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <div className="text-xl font-bold text-green-600">
                                                ${order.total.toFixed(2)}
                                            </div>
                                            <div className="text-xs text-muted-foreground">
                                                {new Date(order.created_at).toLocaleDateString('es-ES')}
                                            </div>
                                        </div>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}
