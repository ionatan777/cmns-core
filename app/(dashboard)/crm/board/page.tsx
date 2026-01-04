import { createClient } from '@/lib/supabase/server'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import KanbanBoardClient from './kanban-client'

export default async function CRMBoardPage() {
    const supabase = await createClient()

    // Obtener todos los pipelines con sus stages
    const { data: pipelines } = await supabase
        .from('pipelines')
        .select(`
      id,
      name,
      brand_id,
      stages:pipeline_stages(*)
    `)
        .order('created_at')

    // Por ahora usar el primer pipeline (CodelyLabs)
    const pipeline = pipelines?.[0]

    if (!pipeline) {
        return (
            <div className="p-6">
                <div className="text-center py-12">
                    <h2 className="text-2xl font-bold mb-2">No hay pipelines configurados</h2>
                    <p className="text-muted-foreground mb-4">
                        Necesitas ejecutar las migraciones CRM primero
                    </p>
                </div>
            </div>
        )
    }

    // Obtener stages ordenados
    const stages = (pipeline.stages || []).sort((a: any, b: any) => a.order_num - b.order_num)

    // Obtener todos los leads activos
    const { data: leads } = await supabase
        .from('leads')
        .select(`
      *,
      contact:contacts(id, name, business_name, phone),
      stage:pipeline_stages(id, name, color)
    `)
        .eq('status', 'active')
        .order('created_at', { ascending: false })

    // Agrupar leads por stage
    const leadsByStage: Record<string, any[]> = {}
    stages.forEach((stage: any) => {
        leadsByStage[stage.id] = []
    })

    leads?.forEach((lead) => {
        if (leadsByStage[lead.stage_id]) {
            leadsByStage[lead.stage_id].push(lead)
        }
    })

    // Calcular estadísticas
    const totalLeads = leads?.length || 0
    const totalValue = leads?.reduce((sum, lead) => sum + (lead.value_estimated || 0), 0) || 0
    const avgValue = totalLeads > 0 ? totalValue / totalLeads : 0

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Kanban CRM</h1>
                    <p className="text-muted-foreground">{pipeline.name}</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" asChild>
                        <Link href="/crm/today">Ver Tareas →</Link>
                    </Button>
                    <Button asChild>
                        <Link href="/crm/leads/new">+ Nuevo Lead</Link>
                    </Button>
                </div>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <div className="rounded-lg border p-4">
                    <div className="text-sm text-muted-foreground">Total Leads Activos</div>
                    <div className="text-2xl font-bold">{totalLeads}</div>
                </div>
                <div className="rounded-lg border p-4">
                    <div className="text-sm text-muted-foreground">Valor Total Pipeline</div>
                    <div className="text-2xl font-bold text-green-600">${totalValue.toFixed(2)}</div>
                </div>
                <div className="rounded-lg border p-4">
                    <div className="text-sm text-muted-foreground">Ticket Promedio</div>
                    <div className="text-2xl font-bold">${avgValue.toFixed(2)}</div>
                </div>
            </div>

            {/* Kanban Board */}
            <KanbanBoardClient stages={stages} leadsByStage={leadsByStage} />

            {/* Empty state */}
            {totalLeads === 0 && (
                <div className="text-center py-12 border-2 border-dashed rounded-lg">
                    <h3 className="text-lg font-semibold mb-2">No hay leads todavía</h3>
                    <p className="text-muted-foreground mb-4">
                        Crea tu primer lead para empezar a gestionar tu pipeline
                    </p>
                    <Button asChild>
                        <Link href="/crm/leads/new">+ Crear Lead</Link>
                    </Button>
                </div>
            )}
        </div>
    )
}
