# 🚀 CMNS Core - Sistema ERP Multi-Marca Inteligente

<div align="center">

![Next.js](https://img.shields.io/badge/Next.js-16.1-black?style=for-the-badge&logo=next.js)
![React](https://img.shields.io/badge/React-19.2-61DAFB?style=for-the-badge&logo=react)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0-3178C6?style=for-the-badge&logo=typescript)
![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?style=for-the-badge&logo=supabase)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-4.0-38B2AC?style=for-the-badge&logo=tailwind-css)
![Gemini AI](https://img.shields.io/badge/Gemini-AI-4285F4?style=for-the-badge&logo=google)

**Sistema de gestión empresarial completo con inteligencia artificial para múltiples marcas**

[📖 Documentación](./DEPLOYMENT.md) • [🐛 Reportar Bug](../../issues)

</div>

---

## 📋 Tabla de Contenidos

- [Acerca del Proyecto](#-acerca-del-proyecto)
- [Características Principales](#-características-principales)
- [Tech Stack](#️-tech-stack)
- [Instalación](#-instalación)
- [Configuración](#️-configuración)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Licencia](#-licencia)

---

## 🎯 Acerca del Proyecto

**CMNS Core** es un sistema ERP (Enterprise Resource Planning) diseñado para gestionar múltiples marcas desde una sola plataforma. Integra inteligencia artificial para proporcionar insights automáticos y automatizar procesos de negocio.

### Marcas Gestionadas

- **🛒 Camvys** - E-commerce de productos físicos
- **💻 CodelyLabs** - Desarrollo de software y landing pages
- **💎 Zypher** - Marca premium de drops exclusivos

### ¿Por qué CMNS Core?

- ✅ **Multi-Tenant**: Seguridad RLS (Row Level Security) a nivel de base de datos
- ✅ **Inteligencia Artificial**: Insights automáticos con Google Gemini
- ✅ **Automatización**: Triggers, funciones y reglas de negocio automatizadas
- ✅ **Real-Time**: Sincronización en tiempo real con Supabase
- ✅ **Moderno**: Built with Next.js 16 y React Server Components

---

## ✨ Características Principales

### 💰 Gestión Financiera
- Sistema de fondos con asignación automática
- Reglas de distribución configurables
- Historial completo de transacciones
- Dashboard con métricas en tiempo real

### 👥 CRM Inteligente
- **Kanban Board** con drag & drop para gestión de leads
- **Seguimiento automático** de tareas (WhatsApp +24h, Llamada +72h)
- **AI Insights** - Análisis automático de ventas con Gemini
- Timeline de interacciones por lead
- Pipelines personalizables por marca

### 🚀 Gestión de Proyectos (CodelyLabs)
- Checklist automático de 7 ítems por proyecto
- Contratos de mantenimiento recurrente
- Actualización automática de estado

### 📦 Inventario & Órdenes
- Gestión separada por marca (Camvys / Zypher)
- Actualización automática de stock
- Políticas de reorden configurables
- Tracking de movimientos

### 🎯 Metas & Reportes
- Seguimiento de objetivos financieros
- Evaluación automática de progreso
- Vistas materializadas para análisis rápido
- Top productos por ventas y margen

### 🤖 Inteligencia Artificial
- Análisis automático de patrones de venta
- Recomendaciones personalizadas
- Identificación de mejores horarios de contacto
- Análisis de efectividad por canal

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: Next.js 16.1 (App Router)
- **UI Library**: React 19.2
- **Lenguaje**: TypeScript 5
- **Styling**: Tailwind CSS 4
- **Components**: Radix UI + shadcn/ui
- **Drag & Drop**: @hello-pangea/dnd

### Backend & Database
- **BaaS**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth
- **Real-time**: Supabase Realtime
- **Security**: Row Level Security (RLS)

### AI & ML
- **LLM**: Google Gemini Pro
- **SDK**: @google/generative-ai

### DevOps
- **Hosting**: Vercel
- **Database**: Supabase Cloud

---

## 🚀 Instalación

### Prerrequisitos

- Node.js 20+ 
- npm o pnpm
- Cuenta en Supabase
- (Opcional) Gemini API Key para AI features

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/TU_USUARIO/cmns-core.git
   cd cmns-core
   ```

2. **Instalar dependencias**
   ```bash
   npm install
   ```

3. **Configurar variables de entorno**
   ```bash
   cp .env.example .env.local
   ```
   
   Editar `.env.local` con tus credenciales (ver [.env.example](./.env.example))

4. **Configurar base de datos**
   
   Ejecutar las migraciones SQL en Supabase SQL Editor (en orden):
   ```
   1. db/EJECUTAR_ESTO.sql          # Core + Finance
   2. db/EJECUTAR_CRM.sql           # CRM Module
   3. db/EJECUTAR_PROJECTS_INVENTORY.sql  # Projects + Inventory
   4. db/EJECUTAR_GOALS_REPORTS.sql # Goals + Reports
   ```

5. **Crear usuario**
   
   En Supabase → Authentication → Users, crear un usuario y luego:
   ```sql
   INSERT INTO memberships (organization_id, user_id, role)
   VALUES (
     '00000000-0000-0000-0000-000000000001',
     'TU_USER_ID',
     'owner'
   );
   ```

6. **Iniciar servidor**
   ```bash
   npm run dev
   ```

7. **Abrir en el navegador**: `http://localhost:3000`

Para más detalles, consulta [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## ⚙️ Configuración

### Variables de Entorno

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `NEXT_PUBLIC_SUPABASE_URL` | URL del proyecto Supabase | ✅ |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Anon key de Supabase | ✅ |
| `NEXT_PUBLIC_APP_URL` | URL de la aplicación | ✅ |
| `GEMINI_API_KEY` | API key de Google Gemini | ⚠️ Opcional* |

*Sin Gemini API key, el módulo de AI Insights no funcionará, pero el resto de la app sí.

---

## 📁 Estructura del Proyecto

```
cmns-core/
├── app/
│   ├── (auth)/              # Páginas de autenticación
│   ├── (dashboard)/         # Páginas del dashboard
│   │   ├── finance/         # Módulo de finanzas
│   │   ├── crm/            # Módulo CRM
│   │   ├── projects/       # Módulo de proyectos
│   │   ├── inventory/      # Módulo de inventario
│   │   └── orders/         # Módulo de órdenes
│   └── api/                # API Routes
├── components/ui/          # shadcn/ui components
├── db/                    # Migraciones SQL
├── lib/                   # Utilidades y tipos
└── public/               # Assets estáticos
```

---

## 📄 Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para más información.

---

## 📧 Contacto

**Jhonatan Pillajo** - Estudiante de Ingeniería en Software

- Email: jhonatanpillajo79@gmail.com
- GitHub: [@TU_USUARIO](https://github.com/TU_USUARIO)

**Link del Proyecto**: [https://github.com/TU_USUARIO/cmns-core](https://github.com/TU_USUARIO/cmns-core)

---

<div align="center">

### ⭐ Si este proyecto te resultó útil, considera darle una estrella!

**Hecho con ❤️ usando Next.js, Supabase y Gemini AI**

</div>
