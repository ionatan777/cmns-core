export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <div className="flex min-h-screen">
            {/* Sidebar - será implementado en próxima fase */}
            <aside className="hidden w-64 border-r bg-muted/40 lg:block">
                <div className="flex h-full flex-col gap-4 p-4">
                    <div className="flex items-center gap-2 font-semibold">
                        <div className="flex h-8 w-8 items-center justify-center rounded-md bg-primary text-primary-foreground">
                            CM
                        </div>
                        <span>GRUPO CMNS</span>
                    </div>

                    <nav className="flex flex-col gap-1">
                        <a href="/overview" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            📊 Overview
                        </a>

                        <div className="mt-2 px-3 text-xs font-semibold text-muted-foreground">
                            FINANZAS
                        </div>
                        <a href="/finance/transactions" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            💰 Transacciones
                        </a>
                        <a href="/finance/funds" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            📊 Fondos
                        </a>
                        <a href="/finance/new" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            Nueva Transacción
                        </a>

                        <hr className="my-2" />

                        {/* CRM */}
                        <div className="px-3 py-2 text-xs font-semibold text-muted-foreground">
                            CRM
                        </div>
                        <a href="/crm/today" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            📋 Tareas de Hoy
                        </a>
                        <a href="/crm/board" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            📊 Kanban
                        </a>
                        <a href="/crm/insights" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            🤖 Insights IA
                        </a>

                        <hr className="my-2" />

                        {/* Projects */}
                        <div className="px-3 py-2 text-xs font-semibold text-muted-foreground">
                            PROYECTOS
                        </div>
                        <a href="/projects" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            🌐 CodelyLabs
                        </a>

                        <hr className="my-2" />

                        {/* Inventory & Orders */}
                        <div className="px-3 py-2 text-xs font-semibold text-muted-foreground">
                            VENTAS
                        </div>
                        <a href="/orders/camvys" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            📦 Órdenes Camvys
                        </a>
                        <a href="/orders/zypher" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            💎 Órdenes Zypher
                        </a>
                        <a href="/inventory/camvys" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            🛒 Inv. Camvys
                        </a>
                        <a href="/inventory/zypher" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            💎 Inv. Zypher
                        </a>

                        <hr className="my-2" />

                        {/* Goals & Reports */}
                        <div className="px-3 py-2 text-xs font-semibold text-muted-foreground">
                            INTELIGENCIA
                        </div>
                        <a href="/goals" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            🎯 Metas
                        </a>
                        <a href="/reports" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            📈 Reportes
                        </a>

                        <hr className="my-2" />
                        <a href="/settings" className="rounded-md px-3 py-2 text-sm hover:bg-muted">
                            ⚙️ Ajustes
                        </a>
                        <form action="/logout" method="POST">
                            <button type="submit" className="w-full rounded-md px-3 py-2 text-sm text-left hover:bg-muted text-red-600">
                                🚪 Cerrar Sesión
                            </button>
                        </form>
                    </nav>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1">
                {children}
            </main>
        </div>
    )
}
