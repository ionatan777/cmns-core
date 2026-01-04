import { GoogleGenerativeAI } from '@google/generative-ai'
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
    try {
        const crmData = await request.json()

        // Verificar API key
        const apiKey = process.env.GEMINI_API_KEY
        if (!apiKey) {
            return NextResponse.json(
                { error: 'Gemini API key not configured' },
                { status: 500 }
            )
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

        return NextResponse.json({
            insights,
            recommendations,
            raw: text,
        })
    } catch (error: any) {
        console.error('Error in AI analysis:', error)
        return NextResponse.json(
            { error: error.message || 'Failed to analyze CRM data' },
            { status: 500 }
        )
    }
}
