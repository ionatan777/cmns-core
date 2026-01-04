# Configuración de Gemini AI para Insights CRM

Para activar el análisis con IA en la página `/crm/insights`, necesitas obtener una API key de Google Gemini:

## Pasos para Configurar

1. **Obtener API Key**:
   - Ir a: https://makersuite.google.com/app/apikey
   - Crear una nueva API key de Gemini
   - Copiar la key

2. **Configurar en el Proyecto**:
   ```bash
   # En tu archivo .env.local, agregar:
   GEMINI_API_KEY=tu_api_key_aqui
   ```

3. **Reiniciar el Servidor**:
   ```bash
   npm run dev
   ```

4. **Probar**:
   - Ir a `/crm/insights`
   - Deberías ver análisis automático con IA

## Características del Análisis IA

El sistema analiza automáticamente:
- ✅ Tasa de conversión
- ✅ Productos más vendidos
- ✅ Patrones de compra
- ✅ Recomendaciones personalizadas
- ✅ Mejores horarios para contactar
- ✅ Efectividad por canal (WhatsApp, Call, Email)

## Costo

Gemini tiene un tier gratuito generoso:
- 60 requests por minuto
- Suficiente para análisis diario del CRM

---

**Nota**: Si no configuras la API key, la página mostrará métricas básicas sin el análisis de IA.
