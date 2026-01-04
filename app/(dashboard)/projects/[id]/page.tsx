import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { notFound } from 'next/navigation'
import Link from 'next/link'

export default async function ProjectDetailPage({ params }: { params: { id: string } }) {
    const supabase = await createClient()

    const { data: project } = await supabase
        .from('projects')
        .select(`
      *,
      brand:brands(id, name),
      lead:leads(id, product, contact:contacts(name, business_name)),
      checklist:project_checklist(*),
      contract:maintenance_contracts(*)
    `)
        .eq('id', params.id)
        .single()

    if (!project) {
        notFound()
    }

    const checklist = (project.checklist || []).sort((a: any, b: any) => a.order_num - b.order_num)
    const contract = project.contract?.[0]

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <Link href="/projects" className="text-sm text-muted-foreground hover:underline mb-2 inline-block">
                        ← Volver a proyectos
                    </Link>
                    <h1 className="text-3xl font-bold">{project.client_name}</h1>
                    {project.domain && <p className="text-muted-foreground">{project.domain}</p>}
                </div>
                <Badge>{project.status}</Badge>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                {/* Main Column */}
                <div className="md:col-span-2 space-y-6">
                    {/* Checklist */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Checklist de Entrega</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-3">
                                {checklist.map((item: any, index: number) => (
                                    <div key={item.id} className="flex items-start gap-3 border-b pb-3 last:border-0">
                                        <input
                                            type="checkbox"
                                            checked={item.done}
                                            className="mt-1 h-5 w-5"
                                            readOnly
                                        />
                                        <div className="flex-1">
                                            <div className={`${item.done ? 'line-through text-muted-foreground' : ''}`}>
                                                {index + 1}. {item.item}
                                            </div>
                                            {item.completed_at && (
                                                <div className="text-xs text-muted-foreground mt-1">
                                                    Completado: {new Date(item.completed_at).toLocaleDateString('es-ES')}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>

                            {project.status !== 'completed' && (
                                <Button className="w-full mt-4" variant="outline">
                                    Actualizar Checklist
                                </Button>
                            )}
                        </CardContent>
                    </Card>

                    {/* Links */}
                    {(project.published_url || project.preview_screenshot_url) && (
                        <Card>
                            <CardHeader>
                                <CardTitle>Enlaces</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-2">
                                {project.published_url && (
                                    <a
                                        href={project.published_url}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="block text-blue-600 hover:underline"
                                    >
                                        🔗 Ver sitio publicado
                                    </a>
                                )}
                                {project.preview_screenshot_url && (
                                    <a
                                        href={project.preview_screenshot_url}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="block text-blue-600 hover:underline"
                                    >
                                        📸 Ver captura
                                    </a>
                                )}
                            </CardContent>
                        </Card>
                    )}
                </div>

                {/* Sidebar */}
                <div className="space-y-6">
                    {/* Info */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Información</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-2 text-sm">
                            <div>
                                <div className="text-muted-foreground">Marca</div>
                                <div className="font-medium">{project.brand?.name}</div>
                            </div>
                            <div>
                                <div className="text-muted-foreground">Creado</div>
                                <div className="font-medium">
                                    {new Date(project.created_at).toLocaleDateString('es-ES')}
                                </div>
                            </div>
                            {project.completed_at && (
                                <div>
                                    <div className="text-muted-foreground">Completado</div>
                                    <div className="font-medium">
                                        {new Date(project.completed_at).toLocaleDateString('es-ES')}
                                    </div>
                                </div>
                            )}
                            {project.lead && (
                                <div>
                                    <div className="text-muted-foreground">Lead Asociado</div>
                                    <Link
                                        href={`/crm/leads/${project.lead.id}`}
                                        className="font-medium text-blue-600 hover:underline"
                                    >
                                        {project.lead.product}
                                    </Link>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Mantenimiento */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Mantenimiento</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {!contract ? (
                                <div className="text-center py-4">
                                    <p className="text-sm text-muted-foreground mb-3">
                                        No hay contrato de mantenimiento
                                    </p>
                                    <Button size="sm" variant="outline">
                                        + Crear Contrato
                                    </Button>
                                </div>
                            ) : (
                                <div className="space-y-3 text-sm">
                                    <div className="flex items-center justify-between">
                                        <span className="text-muted-foreground">Status</span>
                                        <Badge variant={contract.status === 'active' ? 'default' : 'secondary'}>
                                            {contract.status}
                                        </Badge>
                                    </div>
                                    <div className="flex items-center justify-between">
                                        <span className="text-muted-foreground">Mensualidad</span>
                                        <span className="font-semibold text-green-600">
                                            ${contract.monthly_fee}
                                        </span>
                                    </div>
                                    <div className="flex items-center justify-between">
                                        <span className="text-muted-foreground">Próximo Cobro</span>
                                        <span className="font-medium">
                                            {new Date(contract.next_billing_date).toLocaleDateString('es-ES')}
                                        </span>
                                    </div>
                                    {contract.hosting_included && (
                                        <div className="text-xs text-muted-foreground">
                                            ✓ Hosting incluido
                                        </div>
                                    )}

                                    {contract.status === 'active' && (
                                        <Button size="sm" variant="destructive" className="w-full mt-3">
                                            Suspender Mantenimiento
                                        </Button>
                                    )}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
