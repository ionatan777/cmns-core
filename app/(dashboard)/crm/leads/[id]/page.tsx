import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { notFound } from 'next/navigation'
import Link from 'next/link'

export default async function LeadDetailPage({ params }: { params: { id: string } }) {
    const supabase = await createClient()

    // Obtener lead con todas sus relaciones
    const { data: lead } = await supabase
        .from('leads')
        .select(`
      *,
      contact:contacts(*),
      stage:pipeline_stages(id, name, color),
      brand:brands(id, name)
    `)
        .eq('id', params.id)
        .single()

    if (!lead) {
        notFound()
    }

    // Obtener interacciones
    const { data: interactions } = await supabase
        .from('interactions')
        .select('*')
        .eq('lead_id', params.id)
        .order('created_at', { ascending: false })

    // Obtener tareas
    const { data: tasks } = await supabase
        .from('tasks')
        .select('*')
        .eq('lead_id', params.id)
        .order('due_at')

    const pendingTasks = tasks?.filter(t => t.status === 'pending') || []

    // Generar mensaje WhatsApp
    const whatsappMessage = `Hola ${lead.contact.name}! 👋

Soy de ${lead.brand?.name || 'GRUPO CMNS'}. ¿Cómo estás?

Estuve viendo ${lead.contact.business_name || 'tu negocio'} y quería comentarte sobre ${lead.product}.

¿Te parece bien si te envío más información? 😊`

    const whatsappUrl = `https://wa.me/${lead.contact.phone.replace(/[^0-9]/g, '')}?text=${encodeURIComponent(whatsappMessage)}`

    const getChannelIcon = (channel: string) => {
        switch (channel) {
            case 'whatsapp': return '💬'
            case 'dm': return '📱'
            case 'call': return '📞'
            case 'email': return '📧'
            case 'meeting': return '🤝'
            default: return '💭'
        }
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'active': return <Badge>Activo</Badge>
            case 'won': return <Badge className="bg-green-600">Ganado</Badge>
            case 'lost': return <Badge variant="destructive">Perdido</Badge>
            case 'archived': return <Badge variant="secondary">Archivado</Badge>
        }
    }

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <div className="flex items-center gap-2 mb-2">
                        <Link href="/crm/board" className="text-sm text-muted-foreground hover:underline">
                            ← Volver al Kanban
                        </Link>
                    </div>
                    <h1 className="text-3xl font-bold">
                        {lead.contact.business_name || lead.contact.name}
                    </h1>
                    <p className="text-muted-foreground">{lead.product}</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" asChild>
                        <a href={whatsappUrl} target="_blank" rel="noopener noreferrer">
                            💬 Abrir WhatsApp
                        </a>
                    </Button>
                    <Button
                        variant="secondary"
                        onClick={() => {
                            navigator.clipboard.writeText(whatsappMessage)
                            alert('Mensaje copiado al portapapeles!')
                        }}
                    >
                        📋 Copiar Mensaje
                    </Button>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                {/* Columna principal */}
                <div className="md:col-span-2 space-y-6">
                    {/* Info del Lead */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Información del Lead</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-3">
                            <div className="flex items-center justify-between">
                                <span className="text-sm text-muted-foreground">Estado</span>
                                {getStatusBadge(lead.status)}
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm text-muted-foreground">Stage</span>
                                <Badge style={{ backgroundColor: lead.stage.color }}>
                                    {lead.stage.name}
                                </Badge>
                            </div>
                            {lead.value_estimated && (
                                <div className="flex items-center justify-between">
                                    <span className="text-sm text-muted-foreground">Valor Estimado</span>
                                    <span className="font-semibold text-green-600">
                                        ${lead.value_estimated.toFixed(2)}
                                    </span>
                                </div>
                            )}
                            {lead.brand && (
                                <div className="flex items-center justify-between">
                                    <span className="text-sm text-muted-foreground">Marca</span>
                                    <span className="font-medium">{lead.brand.name}</span>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Timeline de Interacciones */}
                    <Card>
                        <CardHeader>
                            <div className="flex items-center justify-between">
                                <CardTitle>Historial de Interacciones</CardTitle>
                                <Button size="sm">+ Nueva Interacción</Button>
                            </div>
                        </CardHeader>
                        <CardContent>
                            {!interactions || interactions.length === 0 ? (
                                <p className="text-sm text-muted-foreground text-center py-4">
                                    No hay interacciones registradas todavía
                                </p>
                            ) : (
                                <div className="space-y-4">
                                    {interactions.map((interaction: any) => (
                                        <div key={interaction.id} className="border-l-2 pl-4 pb-4">
                                            <div className="flex items-center gap-2 mb-1">
                                                <span className="text-lg">{getChannelIcon(interaction.channel)}</span>
                                                <span className="text-sm font-medium capitalize">
                                                    {interaction.channel}
                                                </span>
                                                <span className="text-xs text-muted-foreground ml-auto">
                                                    {new Date(interaction.created_at).toLocaleDateString('es-ES', {
                                                        day: 'numeric',
                                                        month: 'short',
                                                        hour: '2-digit',
                                                        minute: '2-digit',
                                                    })}
                                                </span>
                                            </div>
                                            <p className="text-sm">{interaction.message}</p>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>

                {/* Sidebar */}
                <div className="space-y-6">
                    {/* Info del Contacto */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Contacto</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div>
                                <div className="text-sm text-muted-foreground">Nombre</div>
                                <div className="font-medium">{lead.contact.name}</div>
                            </div>
                            <div>
                                <div className="text-sm text-muted-foreground">Teléfono</div>
                                <div className="font-medium">{lead.contact.phone}</div>
                            </div>
                            {lead.contact.city && (
                                <div>
                                    <div className="text-sm text-muted-foreground">Ciudad</div>
                                    <div className="font-medium">{lead.contact.city}</div>
                                </div>
                            )}
                            {lead.contact.tags && lead.contact.tags.length > 0 && (
                                <div>
                                    <div className="text-sm text-muted-foreground mb-1">Tags</div>
                                    <div className="flex flex-wrap gap-1">
                                        {lead.contact.tags.map((tag: string) => (
                                            <Badge key={tag} variant="secondary" className="text-xs">
                                                {tag}
                                            </Badge>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Tareas Pendientes */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Tareas Pendientes</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {pendingTasks.length === 0 ? (
                                <p className="text-sm text-muted-foreground">No hay tareas pendientes</p>
                            ) : (
                                <div className="space-y-2">
                                    {pendingTasks.map((task: any) => {
                                        const dueDate = new Date(task.due_at)
                                        const isOverdue = dueDate < new Date()

                                        return (
                                            <div key={task.id} className="border rounded-md p-2">
                                                <div className="flex items-start gap-2">
                                                    <input type="checkbox" className="mt-1" />
                                                    <div className="flex-1">
                                                        <div className="text-sm font-medium">{task.title}</div>
                                                        <div
                                                            className={`text-xs ${isOverdue ? 'text-red-600' : 'text-muted-foreground'
                                                                }`}
                                                        >
                                                            {dueDate.toLocaleDateString('es-ES', {
                                                                day: 'numeric',
                                                                month: 'short',
                                                                hour: '2-digit',
                                                                minute: '2-digit',
                                                            })}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        )
                                    })}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
