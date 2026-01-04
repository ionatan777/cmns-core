# Guía de Configuración de Supabase - CMNS Core

Esta guía te llevará paso a paso para configurar tu proyecto Supabase para CMNS Core.

---

## 📋 Paso 1: Crear Proyecto Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Clic en **"New Project"**
3. Configurar:
   - **Name**: `CMNS Core`
   - **Database Password**: Genera una contraseña fuerte (guárdala)
   - **Region**: Selecciona la más cercana
   - **Pricing Plan**: Free (o el que prefieras)
4. Clic en **"Create new project"**
5. Espera 1-2 minutos a que el proyecto se inicialice

---

## 🔑 Paso 2: Obtener Credenciales

1. En el dashboard de tu proyecto, ve a **Settings** → **API**
2. Copia y guarda:
   - **Project URL** (ejemplo: `https://xxxxx.supabase.co`)
   - **anon/public key** (la clave larga que empieza con `eyJ...`)

---

## ⚙️ Paso 3: Configurar Variables de Entorno

1. En tu proyecto local, crea el archivo `.env.local`:

```bash
# En: c:/GRUPO CMNS/cmns-core/.env.local
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...tu-clave-aqui
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

2. Reemplaza los valores con tus credenciales de Supabase

---

## 🔐 Paso 4: Activar Auth (Email/Password)

1. Ve a **Authentication** → **Providers**
2. Asegúrate de que **Email** esté habilitado (debería estarlo por defecto)
3. Configura:
   - **Enable Email provider**: ✅ ON
   - **Confirm email**: Puedes desactivarlo para desarrollo
   - **Secure email change**: ON (recomendado)

---

## 📦 Paso 5: Crear Storage Bucket

1. Ve a **Storage**
2. Clic en **"Create a new bucket"**
3. Configurar:
   - **Name**: `attachments`
   - **Public bucket**: ❌ OFF (privado)
   - **File size limit**: 5 MB (ajusta según necesites)
4. Clic en **"Create bucket"**

### Configurar Políticas del Bucket

Después de crear el bucket, necesitas configurar las políticas de acceso:

1. Clic en el bucket `attachments`
2. Ve a **Policies** → **New Policy**
3. Clic en **"For full customization"**

**Política 1: SELECT (Lectura)**
```sql
-- Nombre: Users can view attachments in their organization
CREATE POLICY "Users can view attachments in their organization"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'attachments' 
  AND (storage.foldername(name))[1] = (
    SELECT organization_id::text 
    FROM memberships 
    WHERE user_id = auth.uid()
    LIMIT 1
  )
);
```

**Política 2: INSERT (Subir archivos)**
```sql
-- Nombre: Users can upload attachments to their organization folder
CREATE POLICY "Users can upload attachments to their organization folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'attachments'
  AND (storage.foldername(name))[1] = (
    SELECT organization_id::text 
    FROM memberships 
    WHERE user_id = auth.uid()
    LIMIT 1
  )
);
```

---

## 🗄️ Paso 6: Ejecutar Migraciones SQL

### Migración 1: Core Tables

1. En Supabase, ve a **SQL Editor**
2. Clic en **"New query"**
3. Copia todo el contenido de `db/migrations/001_core.sql`
4. Pega en el editor
5. Clic en **"Run"** (abajo a la derecha)
6. Verifica que salga: ✅ Success

### Migración 2: RLS Policies

1. Clic en **"New query"** nuevamente
2. Copia todo el contenido de `db/migrations/002_rls.sql`
3. Pega en el editor
4. Clic en **"Run"**
5. Verifica: ✅ Success

### Migración 3: Seed Data

1. Clic en **"New query"** nuevamente
2. Copia todo el contenido de `db/migrations/003_seed.sql`
3. Pega en el editor
4. Clic en **"Run"**
5. Verifica: ✅ Success

---

## 👤 Paso 7: Crear Usuario Owner

### 7.1 Crear Usuario en Auth

1. Ve a **Authentication** → **Users**
2. Clic en **"Add user"** → **"Create new user"**
3. Configurar:
   - **Email**: tu-email@ejemplo.com
   - **Password**: Elige una contraseña
   - **Auto Confirm User**: ✅ ON (para desarrollo)
4. Clic en **"Create user"**

### 7.2 Copiar User ID

1. En la lista de usuarios, copia el **UUID** del usuario recién creado
   - Se ve algo como: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

### 7.3 Crear Membership

1. Ve a **SQL Editor** → **"New query"**
2. Ejecuta (reemplaza `TU_USER_ID_AQUI` con el UUID copiado):

```sql
INSERT INTO memberships (organization_id, user_id, role)
VALUES (
  '00000000-0000-0000-0000-000000000001',  -- GRUPO CMNS
  'TU_USER_ID_AQUI',  -- <-- REEMPLAZAR con tu UUID
  'owner'
);
```

3. Clic en **"Run"**
4. Verifica: ✅ Success. No rows returned (es normal)

---

## ✅ Paso 8: Verificar Configuración

### Verificar Tablas

1. Ve a **Table Editor**
2. Deberías ver:
   - ✅ `organizations` (1 fila: GRUPO CMNS)
   - ✅ `memberships` (1 fila: tu usuario como owner)
   - ✅ `brands` (3 filas: camvys, codelylabs, zypher)
   - ✅ `audit_log` (0 filas, por ahora)

### Verificar Storage

1. Ve a **Storage**
2. Deberías ver:
   - ✅ Bucket `attachments` creado

### Verificar Auth

1. Ve a **Authentication** → **Users**
2. Deberías ver:
   - ✅ Tu usuario creado

---

## 🚀 Paso 9: Probar la Aplicación

1. Asegúrate de tener el archivo `.env.local` configurado
2. Reinicia el servidor de desarrollo:

```bash
# Detener el servidor actual (Ctrl+C)
npm run dev
```

3. Abre [http://localhost:3000](http://localhost:3000)
4. Deberías ver el dashboard sin errores

---

## 🐛 Troubleshooting

### Error: "No rows returned"
- ✅ Es normal después de INSERT/UPDATE exitosos

### Error: "relation does not exist"
- ❌ No se ejecutó correctamente una migración
- **Solución**: Revisa que ejecutaste 001, 002, 003 en orden

### Error: "RLS policy violation"
- ❌ No creaste la membership para tu usuario
- **Solución**: Ejecuta el INSERT de membership del Paso 7.3

### No puedo ver datos en Table Editor
- ❌ RLS está bloqueando la vista
- **Solución Temporal**: Ve a Table Editor → View all rows (ignora RLS temporalmente)
- **Solución Permanente**: Asegúrate de tener membership creada

### Storage policies no funcionan
- ❌ Las tablas `memberships` deben existir ANTES de crear policies del bucket
- **Solución**: Elimina las policies del bucket y vuélvelas a crear

---

## 📝 Checklist Final

- [ ] Proyecto Supabase creado
- [ ] Credenciales copiadas y guardadas
- [ ] Archivo `.env.local` creado con credenciales
- [ ] Auth habilitado (email/password)
- [ ] Bucket `attachments` creado
- [ ] Policies del bucket configuradas
- [ ] Migración 001_core.sql ejecutada ✅
- [ ] Migración 002_rls.sql ejecutada ✅
- [ ] Migración 003_seed.sql ejecutada ✅
- [ ] Usuario creado en Auth
- [ ] Membership creada (owner)
- [ ] Servidor local corriendo sin errores
- [ ] Dashboard accesible en localhost:3000

---

## 🎊 ¡Listo!

Tu proyecto Supabase está configurado correctamente. Ahora puedes continuar con el desarrollo de las funcionalidades de gestión.

**Próximos pasos**:
- Implementar sistema de login
- Crear pantallas de gestión (Organizations, Brands, Users)
- Desarrollar Módulo de Finanzas (Semana 2)

---

**Documentación adicional**:
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
