import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

export default async function CRMTodayPage() {
    const supabase = await createClient()

    // Obtener tareas pendientes de hoy y atrasadas
    const today = new Date()
    today.setHours(23, 59, 59, 999)

    const { data: tasks } = await supabase
        .from('tasks')
        .select(`
      *,
      lead:leads(
        id,
        product,
        contact:contacts(name, business_name)
      )
    `)
        .eq('status', 'pending')
        .lte('due_at', today.toISOString())
        .order('due_at', { ascending: true })

    // Agrupar tareas
    const now = new Date()
    const todayStart = new Date()
    todayStart.setHours(0, 0, 0, 0)

    const overdueTasks = tasks?.filter(t => new Date(t.due_at) < todayStart) || []
    const todayTasks = tasks?.filter(t => {
        const dueDate = new Date(t.due_at)
        return dueDate >= todayStart && dueDate <= today
    }) || []

    const getDaysUntil = (date: string) => {
        const diff = new Date(date).getTime() - now.getTime()
        return Math.ceil(diff / (1000 * 60 * 60 * 24))
    }

    const getTaskIcon = (type: string) => {
        switch (type) {
            case 'call': return '📞'
            case 'message': return '💬'
            case 'meeting': return '🤝'
            case 'proposal': return '📄'
            default: return '📋'
        }
    }

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Tareas de Hoy</h1>
                    <p className="text-muted-foreground">
                        {overdueTasks.length + todayTasks.length} tareas pendientes
                    </p>
                </div>
                <Button asChild>
                    <Link href="/crm/board">Ver Kanban →</Link>
                </Button>
            </div>

            {/* Tareas Atrasadas */}
            {overdueTasks.length > 0 && (
                <div>
                    <h2 className="text-xl font-semibold text-red-600 mb-3">
                        ⚠️ Atrasadas ({overdueTasks.length})
                    </h2>
                    <div className="space-y-2">
                        {overdueTasks.map((task: any) => (
                            <Card key={task.id} className="border-l-4 border-l-red-500">
                                <CardContent className="p-4">
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2">
                                                <span className="text-lg">{getTaskIcon(task.type)}</span>
                                                <span className="font-medium">{task.title}</span>
                                                <Badge variant="destructive" className="text-xs">
                                                    {Math.abs(getDaysUntil(task.due_at))} días atrasada
                                                </Badge>
                                            </div>
                                            {task.description && (
                                                <p className="text-sm text-muted-foreground mt-1">{task.description}</p>
                                            )}
                                            {task.lead && (
                                                <Link
                                                    href={`/crm/leads/${task.lead.id}`}
                                                    className="text-sm text-blue-600 hover:underline mt-1 inline-block"
                                                >
                                                    {task.lead.contact?.business_name || task.lead.contact?.name} - {task.lead.product}
                                                </Link>
                                            )}
                                        </div>
                                        <Button size="sm" variant="outline">Completar</Button>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                </div>
            )}

            {/* Tareas de Hoy */}
            <div>
                <h2 className="text-xl font-semibold mb-3">
                    📅 Hoy ({todayTasks.length})
                </h2>
                {todayTasks.length === 0 ? (
                    <Card>
                        <CardContent className="p-8 text-center text-muted-foreground">
                            ✅ No tienes tareas pendientes para hoy
                        </CardContent>
                    </Card>
                ) : (
                    <div className="space-y-2">
                        {todayTasks.map((task: any) => (
                            <Card key={task.id} className="border-l-4 border-l-blue-500">
                                <CardContent className="p-4">
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2">
                                                <span className="text-lg">{getTaskIcon(task.type)}</span>
                                                <span className="font-medium">{task.title}</span>
                                                <Badge variant="secondary" className="text-xs">
                                                    {new Date(task.due_at).toLocaleTimeString('es-ES', {
                                                        hour: '2-digit',
                                                        minute: '2-digit'
                                                    })}
                                                </Badge>
                                            </div>
                                            {task.description && (
                                                <p className="text-sm text-muted-foreground mt-1">{task.description}</p>
                                            )}
                                            {task.lead && (
                                                <Link
                                                    href={`/crm/leads/${task.lead.id}`}
                                                    className="text-sm text-blue-600 hover:underline mt-1 inline-block"
                                                >
                                                    {task.lead.contact?.business_name || task.lead.contact?.name} - {task.lead.product}
                                                </Link>
                                            )}
                                        </div>
                                        <Button size="sm" variant="outline">Completar</Button>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                )}
            </div>

            {/* Resumen */}
            <Card className="bg-blue-50 border-blue-200">
                <CardHeader>
                    <CardTitle className="text-lg">💡 Tip: Seguimiento consistente</CardTitle>
                </CardHeader>
                <CardContent className="text-sm text-gray-700">
                    Las tareas de seguimiento se crean automáticamente cuando un lead entra a "Prospectado".
                    Mantén la consistencia completando tus follow-ups a tiempo para mejorar tu tasa de conversión.
                </CardContent>
            </Card>
        </div>
    )
}
