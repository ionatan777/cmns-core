import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

export default async function ProductsPage() {
    const supabase = await createClient()

    const { data: products } = await supabase
        .from('products')
        .select('*, brand:brands(name)')
        .eq('active', true)
        .order('name')

    // Obtener stock de cada producto
    const productsWithStock = await Promise.all(
        (products || []).map(async (product) => {
            const { data: stockData } = await supabase.rpc('get_product_stock', {
                p_product_id: product.id,
            })
            return {
                ...product,
                stock: stockData || 0,
                margin: ((product.price - product.cost) / product.cost) * 100,
            }
        })
    )

    const stats = {
        total: productsWithStock.length,
        lowStock: productsWithStock.filter(p => p.stock < 10).length,
        totalValue: productsWithStock.reduce((sum, p) => sum + (p.stock * p.price), 0),
    }

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Productos</h1>
                    <p className="text-muted-foreground">Inventario Camvys y Zypher</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" asChild>
                        <Link href="/inventory/movements">Ver Movimientos</Link>
                    </Button>
                    <Button asChild>
                        <Link href="/inventory/products/new">+ Nuevo Producto</Link>
                    </Button>
                </div>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Total Productos</div>
                        <div className="text-2xl font-bold">{stats.total}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Stock Bajo</div>
                        <div className="text-2xl font-bold text-orange-600">{stats.lowStock}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Valor Inventario</div>
                        <div className="text-2xl font-bold text-green-600">${stats.totalValue.toFixed(2)}</div>
                    </CardHeader>
                </Card>
            </div>

            {/* Products Table */}
            <Card>
                <CardHeader>
                    <CardTitle>Lista de Productos</CardTitle>
                </CardHeader>
                <CardContent>
                    {productsWithStock.length === 0 ? (
                        <div className="text-center py-8 text-muted-foreground">
                            No hay productos registrados
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead>
                                    <tr className="border-b">
                                        <th className="text-left p-2">SKU</th>
                                        <th className="text-left p-2">Producto</th>
                                        <th className="text-left p-2">Marca</th>
                                        <th className="text-right p-2">Stock</th>
                                        <th className="text-right p-2">Costo</th>
                                        <th className="text-right p-2">Precio</th>
                                        <th className="text-right p-2">Margen</th>
                                        <th className="text-center p-2">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {productsWithStock.map((product: any) => (
                                        <tr key={product.id} className="border-b hover:bg-muted/50">
                                            <td className="p-2 font-mono text-sm">{product.sku}</td>
                                            <td className="p-2">
                                                <div className="font-medium">{product.name}</div>
                                                {product.category && (
                                                    <div className="text-xs text-muted-foreground">{product.category}</div>
                                                )}
                                            </td>
                                            <td className="p-2">{product.brand?.name}</td>
                                            <td className="p-2 text-right">
                                                <Badge
                                                    variant={product.stock < 10 ? 'destructive' : 'secondary'}
                                                    className="font-mono"
                                                >
                                                    {product.stock}
                                                </Badge>
                                            </td>
                                            <td className="p-2 text-right">${product.cost.toFixed(2)}</td>
                                            <td className="p-2 text-right font-semibold">${product.price.toFixed(2)}</td>
                                            <td className="p-2 text-right">
                                                <span className={product.margin > 30 ? 'text-green-600' : 'text-orange-600'}>
                                                    {product.margin.toFixed(1)}%
                                                </span>
                                            </td>
                                            <td className="p-2 text-center">
                                                <Button size="sm" variant="outline" asChild>
                                                    <Link href={`/inventory/products/${product.id}`}>Ver</Link>
                                                </Button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}
