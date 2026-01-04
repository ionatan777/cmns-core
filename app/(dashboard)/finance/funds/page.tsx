import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { Badge } from '@/components/ui/badge'

interface Fund {
  id: string
  name: string
  description: string | null
  goal_amount: number | null
  goal_date: string | null
  color: string
}

export default async function FundsPage() {
  const supabase = await createClient()

  // Obtener fondos
  const { data: funds } = await supabase
    .from('funds')
    .select('*')
    .order('name')

  // Calcular saldos de fondos (necesitaremos una query más compleja)
  const fundsWithBalance = await Promise.all(
    (funds || []).map(async (fund) => {
      const { data: balance } = await supabase.rpc('get_fund_balance', {
        p_fund_id: fund.id,
      })

      return {
        ...fund,
        currentBalance: balance || 0,
      }
    })
  )

  // Calcular totales
  const totalAssigned = fundsWithBalance.reduce((sum, f) => sum + f.currentBalance, 0)
  const fundsWithGoals = fundsWithBalance.filter((f) => f.goal_amount)
  const avgProgress =
    fundsWithGoals.length > 0
      ? fundsWithGoals.reduce((sum, f) => sum + Math.min((f.currentBalance / (f.goal_amount || 1)) * 100, 100), 0) /
        fundsWithGoals.length
      : 0

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-3xl font-bold">Fondos</h1>
        <p className="text-muted-foreground">Gestiona la asignación de dinero a fondos virtuales</p>
      </div>

      {/* Resumen General */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader className="pb-3">
            <CardDescription>Total Asignado a Fondos</CardDescription>
            <CardTitle className="text-3xl">${totalAssigned.toFixed(2)}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-3">
            <CardDescription>Progreso Promedio (Fondos con Meta)</CardDescription>
            <CardTitle className="text-3xl">{avgProgress.toFixed(0)}%</CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Lista de Fondos */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {fundsWithBalance.map((fund) => {
          const progress = fund.goal_amount ? (fund.currentBalance / fund.goal_amount) * 100 : 0
          const daysRemaining = fund.goal_date
            ? Math.ceil((new Date(fund.goal_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))
            : null

          const weeklyRequired =
            fund.goal_amount && fund.goal_date
              ? Math.max(0, (fund.goal_amount - fund.currentBalance) / (daysRemaining || 1) / 7)
              : null

          return (
            <Card key={fund.id} className="border-l-4" style={{ borderLeftColor: fund.color }}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg">{fund.name}</CardTitle>
                  <div
                    className="h-3 w-3 rounded-full"
                    style={{ backgroundColor: fund.color }}
                  />
                </div>
                {fund.description && (
                  <CardDescription className="text-sm">{fund.description}</CardDescription>
                )}
              </CardHeader>
              <CardContent className="space-y-3">
                <div>
                  <div className="flex items-baseline justify-between mb-1">
                    <span className="text-2xl font-bold">${fund.currentBalance.toFixed(2)}</span>
                    {fund.goal_amount && (
                      <span className="text-sm text-muted-foreground">/ ${fund.goal_amount.toFixed(2)}</span>
                    )}
                  </div>
                  {fund.goal_amount && (
                    <Progress value={Math.min(progress, 100)} className="h-2" />
                  )}
                </div>

                {fund.goal_amount && (
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Progreso</span>
                      <span className="font-medium">{progress.toFixed(1)}%</span>
                    </div>
                    {daysRemaining !== null && (
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Días restantes</span>
                        <Badge variant={daysRemaining < 30 ? 'destructive' : 'secondary'}>
                          {daysRemaining} días
                        </Badge>
                      </div>
                    )}
                    {weeklyRequired !== null && weeklyRequired > 0 && (
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Ritmo semanal</span>
                        <span className="font-medium text-orange-600">
                          ${weeklyRequired.toFixed(2)}/semana
                        </span>
                      </div>
                    )}
                    {progress >= 100 && (
                      <Badge className="w-full justify-center" variant="default">
                        ✅ Meta Alcanzada
                      </Badge>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          )
        })}
      </div>

      {/* Info Box */}
      <Card className="bg-blue-50 border-blue-200">
        <CardHeader>
          <CardTitle className="text-lg">ℹ️ Asignación Automática</CardTitle>
        </CardHeader>
        <CardContent className="text-sm text-gray-700">
          Los fondos se asignan automáticamente cuando creas transacciones según las reglas configuradas. Por
          ejemplo, los ingresos de "Venta Landing" de CodelyLabs se dividen: 40% Universidad, 20% Deuda, 40% Caja
          Libre.
        </CardContent>
      </Card>
    </div>
  )
}
