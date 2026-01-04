# 🚀 Guía de Deployment - CMNS Core

Esta guía te llevará paso a paso para desplegar CMNS Core a producción usando **Vercel** y **Supabase**.

---

## 📋 Checklist Pre-Deployment

Antes de desplegar, asegúrate de tener:

- [ ] ✅ Código funcionando localmente
- [ ] ✅ Cuenta en [GitHub](https://github.com)
- [ ] ✅ Cuenta en [Vercel](https://vercel.com)
- [ ] ✅ Proyecto Supabase configurado
- [ ] ✅ Todas las migraciones SQL ejecutadas
- [ ] ✅ Variables de entorno listas

---

##1️⃣ Preparar Repositorio GitHub

### 1.1 Inicializar Git (si no lo has hecho)

```bash
cd "c:/GRUPO CMNS/cmns-core"
git init
```

### 1.2 Crear primer commit

```bash
git add .
git commit -m "feat: Initial commit - CMNS Core ERP System

- Multi-brand ERP system (Camvys, CodelyLabs, Zypher)
- Finance module with automatic fund allocation
- CRM with Kanban board and AI insights
- Project management with maintenance contracts
- Inventory and orders management
- Goals tracking and reports
"
```

### 1.3 Crear repositorio en GitHub

1. Ve a https://github.com/new
2. Nombre del repositorio: `cmns-core` (o el que prefieras)
3. Descripción: `Sistema ERP Multi-Marca con IA`
4. Visibilidad: **Public** (para portfolio)
5. **NO** inicialices con README (ya lo tenemos)
6. Click en "Create repository"

### 1.4 Conectar y subir

```bash
git remote add origin https://github.com/TU_USUARIO/cmns-core.git
git branch -M main
git push -u origin main
```

✅ **Verifica**: Tu código debería estar visible en GitHub ahora.

---

## 2️⃣ Configurar Supabase para Producción

### 2.1 Verificar que las migraciones estén ejecutadas

En Supabase SQL Editor, verifica que existan estas tablas:

```sql
-- Debería retornar todas las tablas
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

Deberías ver: `organizations`, `brands`, `memberships`, `funds`, `accounts`, `transactions`, `contacts`, `leads`, `pipelines`, `products`, `orders`, `goals`, etc.

### 2.2 Verificar RLS (Row Level Security)

```sql
-- Debería retornar policies para cada tabla
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

### 2.3 Obtener credenciales de producción

En Supabase → Settings → API:

- **Project URL**: `https://[proyecto].supabase.co`
- **Anon public key**: `eyJhbGc...` (clave larga)

⚠️ **IMPORTANTE**: Guarda estas credenciales, las necesitarás en Vercel.

---

## 3️⃣ Desplegar a Vercel

### 3.1 Crear cuenta en Vercel

1. Ve a https://vercel.com
2. Click en "Sign Up"
3. Elige "Continue with GitHub"
4. Autoriza a Vercel

### 3.2 Importar proyecto

1. En el dashboard de Vercel, click en **"Add New"** → **"Project"**
2. Busca tu repositorio `cmns-core`
3. Click en **"Import"**

### 3.3 Configurar proyecto

**Framework Preset**: Next.js (auto-detectado)  
**Root Directory**: `./` (dejar por defecto)  
**Build Command**: `next build` (auto-detectado)  
**Output Directory**: `.next` (auto-detectado)

### 3.4 Agregar Variables de Entorno

Click en **"Environment Variables"** y agrega:

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | Tu Supabase Project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Tu Supabase Anon Key |
| `NEXT_PUBLIC_APP_URL` | `https://tu-proyecto.vercel.app` |
| `GEMINI_API_KEY` | Tu Gemini API Key (opcional) |

⚠️ **Nota sobre `NEXT_PUBLIC_APP_URL`**: 
- Primero ponlo temporalmente como `https://cmns-core.vercel.app`
- Después del primer deploy, Vercel te dará una URL real
- Vuelve a Settings → Environment Variables y actualízalo

### 3.5 Deploy

1. Click en **"Deploy"**
2. Espera 2-3 minutos mientras Vercel construye tu app
3. ✅ ¡Listo! Tu app está en vivo

---

## 4️⃣ Post-Deployment

### 4.1 Actualizar `NEXT_PUBLIC_APP_URL`

1. Copia tu URL de Vercel (ej: `https://cmns-core-abc123.vercel.app`)
2. Ve a Vercel → Settings → Environment Variables
3. Edita `NEXT_PUBLIC_APP_URL` con la URL correcta
4. Click en **"Save"**
5. Ve a Deployments → Click en los 3 puntos del último deploy → **"Redeploy"**

### 4.2 Crear usuario de producción

1. Ve a tu app desplegada
2. Debería aparecer la página de login
3. Ve a Supabase → Authentication → Users
4. Click en "Add user"
5. Email: `tu_email@example.com`
6. Password: `tu_password_seguro`
7. Click en "Create user"

### 4.3 Agregar membership

En Supabase SQL Editor:

```sql
INSERT INTO memberships (organization_id, user_id, role)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'UUID_DEL_USUARIO_QUE_ACABAS_DE_CREAR',
  'owner'
);
```

### 4.4 ¡Probar!

1. Ve a tu URL de producción
2. Inicia sesión con las credenciales
3. Verifica que todos los módulos funcionen

---

## 5️⃣ Configuración Opcional

### Custom Domain (Dominio Personalizado)

Si tienes un dominio:

1. Ve a Vercel → Settings → Domains
2. Click en "Add"
3. Ingresa tu dominio (ej: `cmns-core.com`)
4. Sigue las instrucciones para configurar DNS
5. Actualiza `NEXT_PUBLIC_APP_URL` con tu nuevo dominio

### Configurar Gemini AI

Si no configuraste Gemini:

1. Ve a https://makersuite.google.com/app/apikey
2. Click en "Create API Key"
3. Copia la key
4. Ve a Vercel → Settings → Environment Variables
5. Agrega `GEMINI_API_KEY` con la key
6. Redeploy

---

## 🐛 Troubleshooting

### Error: "Invalid API key"

**Solución**: Verifica que `NEXT_PUBLIC_SUPABASE_ANON_KEY` sea el "anon public" key, NO el "service role" key.

### Error: "Auth session missing"

**Solución**: Verifica que `NEXT_PUBLIC_APP_URL` coincida exactamente con tu URL de Vercel.

### Build falla en Vercel

**Solución**: 
1. Verifica que `npm run build` funcione localmente
2. Revisa los logs de build en Vercel
3. Asegúrate de que todas las dependencias estén en `package.json`

### AI Insights no funcionan

**Solución**: 
1. Verifica que `GEMINI_API_KEY` esté configurada
2. Asegúrate de usar `gemini-1.5-flash` o `gemini-1.5-pro` como modelo

---

## 📊 Monitoreo

### Vercel Analytics

Vercel te da analytics gratis:

1. Ve a tu proyecto → Analytics
2. Verás: visitantes, páginas vistas, errores

### Supabase Logs

Para ver logs de la base de datos:

1. Ve a Supabase → Database → Logs
2. Filtra por errores o queries lentas

---

## 🔄 Actualizar la App

Cuando hagas cambios al código:

```bash
git add .
git commit -m "feat: descripción del cambio"
git push
```

Vercel automáticamente detectará el push y redesplegará tu app. ✨

---

## ✅ Checklist Final

- [ ] ✅ App desplegada en Vercel
- [ ] ✅ Todas las variables de entorno configuradas
- [ ] ✅ Usuario de producción creado
- [ ] ✅ Membership creada
- [ ] ✅ Login funciona
- [ ] ✅ Todos los módulos accesibles
- [ ] ✅ Sin errores en la consola
- [ ] ✅ URL actualizada en GitHub README

---

## 🎉 ¡Felicitaciones!

Tu app está ahora en producción. Comparte tu link:

- **GitHub**: `https://github.com/TU_USUARIO/cmns-core`
- **Live Demo**: `https://tu-proyecto.vercel.app`

---

## 📧 Soporte

Si tienes problemas:

1. Revisa los logs en Vercel
2. Revisa los logs en Supabase
3. Abre un issue en GitHub
4. Contacta: jhonatanpillajo79@gmail.com

¡Éxito! 🚀
