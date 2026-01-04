import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

export default async function GoalsPage() {
    const supabase = await createClient()

    const { data: goals } = await supabase
        .from('goals')
        .select('*, fund:funds(id, name)')
        .eq('status', 'active')
        .order('priority')
        .order('target_date')

    // Calcular datos para cada meta
    const goalsWithData = await Promise.all(
        (goals || []).map(async (goal) => {
            // Current amount
            let currentAmount = 0
            if (goal.fund_id) {
                const { data: balance } = await supabase.rpc('get_fund_balance', {
                    p_fund_id: goal.fund_id,
                })
                currentAmount = balance || 0
            }

            // Weekly pace required
            const { data: weeklyPace } = await supabase.rpc('get_goal_weekly_pace', {
                p_goal_id: goal.id,
            })

            // On track?
            const { data: onTrack } = await supabase.rpc('is_goal_on_track', {
                p_goal_id: goal.id,
            })

            // Days left
            const daysLeft = Math.ceil(
                (new Date(goal.target_date).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
            )

            return {
                ...goal,
                currentAmount,
                weeklyPace: weeklyPace || 0,
                onTrack: onTrack || false,
                daysLeft,
                progress: (currentAmount / goal.target_amount) * 100,
            }
        })
    )

    const stats = {
        total: goalsWithData.length,
        onTrack: goalsWithData.filter(g => g.onTrack).length,
        late: goalsWithData.filter(g => !g.onTrack).length,
    }

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Metas</h1>
                    <p className="text-muted-foreground">Motor de decisiones automático</p>
                </div>
                <Button asChild>
                    <Link href="/goals/new">+ Nueva Meta</Link>
                </Button>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Total Metas</div>
                        <div className="text-2xl font-bold">{stats.total}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Vas Bien</div>
                        <div className="text-2xl font-bold text-green-600">{stats.onTrack}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Vas Tarde</div>
                        <div className="text-2xl font-bold text-orange-600">{stats.late}</div>
                    </CardHeader>
                </Card>
            </div>

            {/* Goals List */}
            {goalsWithData.length === 0 ? (
                <Card>
                    <CardContent className="p-12 text-center">
                        <h3 className="text-lg font-semibold mb-2">No hay metas configuradas</h3>
                        <p className="text-muted-foreground mb-4">
                            Crea metas para que el sistema te guíe automáticamente
                        </p>
                        <Button asChild>
                            <Link href="/goals/new">+ Crear Meta</Link>
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-4 md:grid-cols-2">
                    {goalsWithData.map((goal: any) => (
                        <Card key={goal.id} className={`border-l-4 ${goal.onTrack ? 'border-l-green-500' : 'border-l-orange-500'}`}>
                            <CardHeader>
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <CardTitle className="text-lg">{goal.name}</CardTitle>
                                        {goal.fund && (
                                            <p className="text-sm text-muted-foreground">Fondo: {goal.fund.name}</p>
                                        )}
                                    </div>
                                    <Badge variant={goal.onTrack ? 'default' : 'destructive'} className={goal.onTrack ? 'bg-green-600' : ''}>
                                        {goal.onTrack ? '✅ Vas bien' : '⚠️ Vas tarde'}
                                    </Badge>
                                </div>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                {/* Progress */}
                                <div>
                                    <div className="flex items-baseline justify-between mb-2">
                                        <span className="text-2xl font-bold">${goal.currentAmount.toFixed(2)}</span>
                                        <span className="text-sm text-muted-foreground">/ ${goal.target_amount.toFixed(2)}</span>
                                    </div>
                                    <Progress value={Math.min(goal.progress, 100)} className="h-2" />
                                    <div className="text-sm text-muted-foreground mt-1 text-right">
                                        {goal.progress.toFixed(1)}%
                                    </div>
                                </div>

                                {/* Metrics */}
                                <div className="grid grid-cols-2 gap-3 text-sm border-t pt-3">
                                    <div>
                                        <div className="text-muted-foreground">Ritmo Semanal</div>
                                        <div className="font-semibold text-orange-600">
                                            ${goal.weeklyPace.toFixed(2)}/sem
                                        </div>
                                    </div>
                                    <div>
                                        <div className="text-muted-foreground">Días Restantes</div>
                                        <div className="font-semibold">
                                            {goal.daysLeft > 0 ? `${goal.daysLeft} días` : 'Vencida'}
                                        </div>
                                    </div>
                                    <div>
                                        <div className="text-muted-foreground">Fecha Límite</div>
                                        <div className="font-medium">
                                            {new Date(goal.target_date).toLocaleDateString('es-ES')}
                                        </div>
                                    </div>
                                    <div>
                                        <div className="text-muted-foreground">Prioridad</div>
                                        <Badge variant="outline">
                                            {goal.priority === 1 ? 'Alta' : goal.priority === 2 ? 'Media' : 'Baja'}
                                        </Badge>
                                    </div>
                                </div>

                                {/* Action */}
                                {!goal.onTrack && (
                                    <div className="bg-orange-50 border border-orange-200 rounded-md p-3">
                                        <div className="text-sm font-medium text-orange-800">
                                            💡 Necesitas aumentar tus ingresos o reducir gastos
                                        </div>
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* Info */}
            <Card className="bg-blue-50 border-blue-200">
                <CardHeader>
                    <CardTitle className="text-lg">🤖 Motor de Decisiones</CardTitle>
                </CardHeader>
                <CardContent className="text-sm text-gray-700">
                    El sistema calcula automáticamente cuánto necesitas aportar semanalmente a cada meta.
                    Si detecta que vas tarde, te alertará y creará tareas para ajustar tu estrategia.
                </CardContent>
            </Card>
        </div>
    )
}
