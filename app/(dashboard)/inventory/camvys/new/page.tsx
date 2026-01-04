'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

export default function NewCamvysProductPage() {
    const router = useRouter()
    const [loading, setLoading] = useState(false)
    const [formData, setFormData] = useState({
        name: '',
        sku: '',
        description: '',
        cost: '',
        price: '',
        category: '',
        image_url: '',
    })

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)

        try {
            const supabase = createClient()

            // Obtener brand_id de Camvys
            const { data: brand } = await supabase
                .from('brands')
                .select('id, organization_id')
                .eq('name', 'camvys')
                .single()

            if (!brand) {
                alert('Error: Marca Camvys no encontrada')
                return
            }

            // Crear producto
            const { error } = await supabase.from('products').insert({
                organization_id: brand.organization_id,
                brand_id: brand.id,
                name: formData.name,
                sku: formData.sku,
                description: formData.description || null,
                cost: parseFloat(formData.cost),
                price: parseFloat(formData.price),
                category: formData.category || null,
                image_url: formData.image_url || null,
                active: true,
            })

            if (error) throw error

            alert('✅ Producto creado exitosamente')
            router.push('/inventory/camvys')
        } catch (error: any) {
            console.error('Error creando producto:', error)
            alert('Error: ' + error.message)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="p-6 max-w-2xl mx-auto">
            <div className="mb-6">
                <h1 className="text-3xl font-bold">Nuevo Producto Camvys</h1>
                <p className="text-muted-foreground">Agregar producto al inventario de e-commerce</p>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Información del Producto</CardTitle>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <Label htmlFor="name">Nombre *</Label>
                                <Input
                                    id="name"
                                    required
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder="Ej: Camiseta Deportiva"
                                />
                            </div>
                            <div>
                                <Label htmlFor="sku">SKU *</Label>
                                <Input
                                    id="sku"
                                    required
                                    value={formData.sku}
                                    onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                                    placeholder="Ej: CAM-001"
                                />
                            </div>
                        </div>

                        <div>
                            <Label htmlFor="description">Descripción</Label>
                            <Textarea
                                id="description"
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                placeholder="Descripción del producto..."
                                rows={3}
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <Label htmlFor="cost">Costo *</Label>
                                <Input
                                    id="cost"
                                    type="number"
                                    step="0.01"
                                    required
                                    value={formData.cost}
                                    onChange={(e) => setFormData({ ...formData, cost: e.target.value })}
                                    placeholder="0.00"
                                />
                            </div>
                            <div>
                                <Label htmlFor="price">Precio de Venta *</Label>
                                <Input
                                    id="price"
                                    type="number"
                                    step="0.01"
                                    required
                                    value={formData.price}
                                    onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                                    placeholder="0.00"
                                />
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <Label htmlFor="category">Categoría</Label>
                                <Input
                                    id="category"
                                    value={formData.category}
                                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                                    placeholder="Ej: Ropa, Accesorios..."
                                />
                            </div>
                            <div>
                                <Label htmlFor="image_url">URL de Imagen</Label>
                                <Input
                                    id="image_url"
                                    type="url"
                                    value={formData.image_url}
                                    onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                                    placeholder="https://..."
                                />
                            </div>
                        </div>

                        <div className="flex gap-2 pt-4">
                            <Button type="submit" disabled={loading} className="flex-1">
                                {loading ? 'Creando...' : '✅ Crear Producto'}
                            </Button>
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => router.push('/inventory/camvys')}
                                disabled={loading}
                            >
                                Cancelar
                            </Button>
                        </div>
                    </form>
                </CardContent>
            </Card>
        </div>
    )
}
