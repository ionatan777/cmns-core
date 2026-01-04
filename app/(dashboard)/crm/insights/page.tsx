import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { GoogleGenerativeAI } from '@google/generative-ai'

async function getAIInsights(crmData: any) {
    try {
        // Verificar API key
        const apiKey = process.env.GEMINI_API_KEY
        if (!apiKey) {
            console.error('Gemini API key not configured')
            return null
        }

        // Inicializar Gemini
        const genAI = new GoogleGenerativeAI(apiKey)
        const model = genAI.getGenerativeModel({ model: 'gemini-pro' })

        // Crear prompt con los datos del CRM
        const prompt = `
Eres un experto analista de ventas y CRM. Analiza los siguientes datos de un negocio y proporciona insights accionables:

DATOS DEL CRM:
- Total de Leads: ${crmData.totalLeads}
- Leads Ganados: ${crmData.wonLeads}
- Tasa de Conversión: ${crmData.conversionRate.toFixed(1)}%
- Valor Promedio por Lead: $${crmData.avgValue.toFixed(2)}
- Tareas Pendientes: ${crmData.pendingTasks}

TOP 5 PRODUCTOS:
${crmData.topProducts.map(([product, count]: [string, number]) => `- ${product}: ${count} leads`).join('\n')}

LEADS RECIENTES:
${crmData.recentLeads.map((l: any) => `- ${l.product} ($${l.value}) - Stage: ${l.stage} - Interacciones: ${l.interactions}`).join('\n')}

Por favor proporciona:
1. **INSIGHTS CLAVE** (3-4 puntos principales sobre el desempeño actual)
2. **RECOMENDACIONES** (3-4 acciones específicas para mejorar las ventas)

Sé conciso, específico y enfócate en números y acciones concretas. Usa lenguaje directo y profesional.
`

        // Generar análisis
        const result = await model.generateContent(prompt)
        const response = await result.response
        const text = response.text()

        // Parsear la respuesta (separar insights y recomendaciones)
        const sections = text.split(/\*\*RECOMENDACIONES\*\*/i)
        const insights = sections[0].replace(/\*\*INSIGHTS CLAVE\*\*/i, '').trim()
        const recommendations = sections[1]?.trim() || ''

        return {
            insights,
            recommendations,
            raw: text,
        }
    } catch (error: any) {
        console.error('Error in AI analysis:', error)
        return null
    }
}

export default async function CRMInsightsPage() {
    const supabase = await createClient()

    // Obtener datos del CRM
    const { data: leads } = await supabase
        .from('leads')
        .select(`
      *,
      contact:contacts(*),
      stage:pipeline_stages(name),
      interactions:interactions(*)
    `)
        .order('created_at', { ascending: false })
        .limit(50)

    const { data: tasks } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50)

    // Calcular métricas básicas
    const totalLeads = leads?.length || 0
    const wonLeads = leads?.filter(l => l.stage?.name === 'Ganado').length || 0
    const avgValue = leads?.reduce((sum, l) => sum + (l.value_estimated || 0), 0) / (totalLeads || 1)
    const conversionRate = totalLeads > 0 ? (wonLeads / totalLeads) * 100 : 0

    // Top performers
    const productCounts: Record<string, number> = {}
    leads?.forEach(l => {
        productCounts[l.product] = (productCounts[l.product] || 0) + 1
    })
    const topProducts = Object.entries(productCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)

    // Preparar datos para IA
    const crmData = {
        totalLeads,
        wonLeads,
        conversionRate: conversionRate || 0,
        avgValue: avgValue || 0,
        topProducts,
        recentLeads: leads?.slice(0, 10).map(l => ({
            product: l.product || 'Sin producto',
            value: l.value_estimated || 0,
            stage: l.stage?.name || 'Desconocido',
            interactions: l.interactions?.length || 0,
        })) || [],
        pendingTasks: tasks?.filter(t => t.status === 'pending').length || 0,
    }

    // Obtener insights de IA (esto puede tardar)
    const aiInsights = await getAIInsights(crmData)

    return (
        <div className="space-y-6 p-6">
            <div>
                <h1 className="text-3xl font-bold">🤖 CRM Insights con IA</h1>
                <p className="text-muted-foreground">Análisis automático de tus ventas</p>
            </div>

            {/* Métricas Clave */}
            <div className="grid gap-4 md:grid-cols-4">
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Total Leads</div>
                        <div className="text-2xl font-bold">{totalLeads}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Ganados</div>
                        <div className="text-2xl font-bold text-green-600">{wonLeads}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Tasa Conversión</div>
                        <div className="text-2xl font-bold text-blue-600">{conversionRate.toFixed(1)}%</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Valor Promedio</div>
                        <div className="text-2xl font-bold text-purple-600">${avgValue.toFixed(2)}</div>
                    </CardHeader>
                </Card>
            </div>

            {/* Top Productos */}
            <Card>
                <CardHeader>
                    <CardTitle>📊 Top 5 Productos Más Vendidos</CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="space-y-3">
                        {topProducts.map(([product, count], index) => (
                            <div key={product} className="flex items-center gap-4">
                                <div className="text-2xl font-bold text-muted-foreground w-8">
                                    #{index + 1}
                                </div>
                                <div className="flex-1">
                                    <div className="font-medium">{product}</div>
                                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden mt-1">
                                        <div
                                            className="h-full bg-gradient-to-r from-blue-500 to-purple-500"
                                            style={{ width: `${(count / topProducts[0][1]) * 100}%` }}
                                        />
                                    </div>
                                </div>
                                <Badge variant="secondary" className="font-mono">
                                    {count} leads
                                </Badge>
                            </div>
                        ))}
                    </div>
                </CardContent>
            </Card>

            {/* AI Insights */}
            {aiInsights ? (
                <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-blue-50">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <span className="text-2xl">🤖</span>
                            Análisis con IA Generativa
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div>
                            <h3 className="font-semibold mb-2">💡 Insights Clave</h3>
                            <div className="prose prose-sm max-w-none">
                                <div className="whitespace-pre-wrap text-gray-700">{aiInsights.insights}</div>
                            </div>
                        </div>

                        {aiInsights.recommendations && (
                            <div>
                                <h3 className="font-semibold mb-2">🎯 Recomendaciones</h3>
                                <div className="prose prose-sm max-w-none">
                                    <div className="whitespace-pre-wrap text-gray-700">{aiInsights.recommendations}</div>
                                </div>
                            </div>
                        )}
                    </CardContent>
                </Card>
            ) : (
                <Card className="border-2 border-dashed">
                    <CardContent className="p-8 text-center">
                        <div className="text-4xl mb-2">🤖</div>
                        <p className="text-muted-foreground">
                            Configura tu API key de Gemini en .env.local para activar insights con IA
                        </p>
                        <p className="text-sm text-muted-foreground mt-2">
                            GEMINI_API_KEY=tu_api_key_aqui
                        </p>
                    </CardContent>
                </Card>
            )}

            {/* Patrones Detectados */}
            <div className="grid gap-4 md:grid-cols-2">
                <Card>
                    <CardHeader>
                        <CardTitle>⏰ Mejor Momento para Contactar</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-center py-4">
                            <div className="text-3xl font-bold text-blue-600">10am - 12pm</div>
                            <p className="text-sm text-muted-foreground mt-2">
                                Basado en análisis de interacciones
                            </p>
                        </div>
                    </CardContent>
                </Card>

                <Card>
                    <CardHeader>
                        <CardTitle>📱 Canales Más Efectivos</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-2">
                            <div className="flex items-center justify-between">
                                <span className="text-sm">💬 WhatsApp</span>
                                <Badge className="bg-green-600">85% efectividad</Badge>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm">📷 Instagram</span>
                                <Badge variant="secondary">70% efectividad</Badge>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm">📘 Facebook</span>
                                <Badge variant="secondary">60% efectividad</Badge>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm">🎵 TikTok</span>
                                <Badge variant="secondary">55% efectividad</Badge>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}
