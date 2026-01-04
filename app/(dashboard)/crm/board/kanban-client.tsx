'use client'

import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import Link from 'next/link'

interface KanbanBoardClientProps {
    stages: any[]
    leadsByStage: Record<string, any[]>
}

export default function KanbanBoardClient({ stages, leadsByStage }: KanbanBoardClientProps) {
    const onDragEnd = async (result: any) => {
        if (!result.destination) return

        const { source, destination, draggableId } = result

        // Si no cambió de columna, no hacer nada
        if (source.droppableId === destination.droppableId) return

        // TODO: Actualizar stage_id del lead en Supabase
        console.log(`Move lead ${draggableId} from ${source.droppableId} to ${destination.droppableId}`)
    }

    const getDaysAgo = (date: string | null) => {
        if (!date) return null
        const diff = Date.now() - new Date(date).getTime()
        return Math.floor(diff / (1000 * 60 * 60 * 24))
    }

    return (
        <DragDropContext onDragEnd={onDragEnd}>
            <div className="flex gap-4 overflow-x-auto pb-4">
                {stages.map((stage: any) => {
                    const leads = leadsByStage[stage.id] || []

                    return (
                        <div key={stage.id} className="flex-shrink-0 w-80">
                            <div className="mb-3">
                                <div className="flex items-center gap-2">
                                    <div
                                        className="w-3 h-3 rounded-full"
                                        style={{ backgroundColor: stage.color }}
                                    />
                                    <h3 className="font-semibold">{stage.name}</h3>
                                    <Badge variant="secondary" className="ml-auto">
                                        {leads.length}
                                    </Badge>
                                </div>
                            </div>

                            <Droppable droppableId={stage.id}>
                                {(provided, snapshot) => (
                                    <div
                                        ref={provided.innerRef}
                                        {...provided.droppableProps}
                                        className={`space-y-2 min-h-[200px] p-2 rounded-lg transition-colors ${snapshot.isDraggingOver ? 'bg-muted' : 'bg-transparent'
                                            }`}
                                    >
                                        {leads.map((lead: any, index: number) => {
                                            const daysAgo = getDaysAgo(lead.last_contact_at)

                                            return (
                                                <Draggable key={lead.id} draggableId={lead.id} index={index}>
                                                    {(provided, snapshot) => (
                                                        <Card
                                                            ref={provided.innerRef}
                                                            {...provided.draggableProps}
                                                            {...provided.dragHandleProps}
                                                            className={`cursor-move ${snapshot.isDragging ? 'shadow-lg rotate-2' : ''
                                                                }`}
                                                        >
                                                            <CardHeader className="p-3 pb-2">
                                                                <Link
                                                                    href={`/crm/leads/${lead.id}`}
                                                                    className="font-medium text-sm hover:text-blue-600"
                                                                >
                                                                    {lead.contact?.business_name || lead.contact?.name}
                                                                </Link>
                                                                <p className="text-xs text-muted-foreground">
                                                                    {lead.product}
                                                                </p>
                                                            </CardHeader>
                                                            <CardContent className="p-3 pt-0">
                                                                <div className="flex items-center justify-between">
                                                                    {lead.value_estimated && (
                                                                        <span className="text-sm font-semibold text-green-600">
                                                                            ${lead.value_estimated}
                                                                        </span>
                                                                    )}
                                                                    {daysAgo !== null && (
                                                                        <Badge
                                                                            variant={daysAgo > 7 ? 'destructive' : 'secondary'}
                                                                            className="text-xs"
                                                                        >
                                                                            {daysAgo === 0
                                                                                ? 'Hoy'
                                                                                : `${daysAgo}d`}
                                                                        </Badge>
                                                                    )}
                                                                </div>
                                                            </CardContent>
                                                        </Card>
                                                    )}
                                                </Draggable>
                                            )
                                        })}
                                        {provided.placeholder}
                                    </div>
                                )}
                            </Droppable>
                        </div>
                    )
                })}
            </div>
        </DragDropContext>
    )
}
