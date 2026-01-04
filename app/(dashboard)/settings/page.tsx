import Link from 'next/link'

export default function SettingsPage() {
    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-3xl font-bold text-white">⚙️ Configuración</h1>
                <p className="text-gray-400 mt-1">Administra la configuración del sistema</p>
            </div>

            {/* Settings Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {/* Users */}
                <Link
                    href="/users"
                    className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10 hover:border-blue-500/50 transition-all group"
                >
                    <div className="text-4xl mb-4">👥</div>
                    <h3 className="text-xl font-semibold text-white group-hover:text-blue-400 transition-colors">
                        Gestión de Usuarios
                    </h3>
                    <p className="text-gray-400 mt-2 text-sm">
                        Crear, editar y administrar usuarios del sistema
                    </p>
                </Link>

                {/* Brands */}
                <Link
                    href="/brands"
                    className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10 hover:border-purple-500/50 transition-all group"
                >
                    <div className="text-4xl mb-4">🏷️</div>
                    <h3 className="text-xl font-semibold text-white group-hover:text-purple-400 transition-colors">
                        Marcas
                    </h3>
                    <p className="text-gray-400 mt-2 text-sm">
                        Configurar marcas y sus ajustes
                    </p>
                </Link>

                {/* Integrations */}
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10 opacity-60">
                    <div className="text-4xl mb-4">🔗</div>
                    <h3 className="text-xl font-semibold text-white">
                        Integraciones
                    </h3>
                    <p className="text-gray-400 mt-2 text-sm">
                        Conectar con servicios externos
                    </p>
                    <span className="inline-block mt-3 text-xs bg-yellow-500/20 text-yellow-400 px-2 py-1 rounded">
                        Próximamente
                    </span>
                </div>

                {/* Notifications */}
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10 opacity-60">
                    <div className="text-4xl mb-4">🔔</div>
                    <h3 className="text-xl font-semibold text-white">
                        Notificaciones
                    </h3>
                    <p className="text-gray-400 mt-2 text-sm">
                        Configurar alertas y notificaciones
                    </p>
                    <span className="inline-block mt-3 text-xs bg-yellow-500/20 text-yellow-400 px-2 py-1 rounded">
                        Próximamente
                    </span>
                </div>

                {/* Security */}
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10 opacity-60">
                    <div className="text-4xl mb-4">🔒</div>
                    <h3 className="text-xl font-semibold text-white">
                        Seguridad
                    </h3>
                    <p className="text-gray-400 mt-2 text-sm">
                        Autenticación y permisos
                    </p>
                    <span className="inline-block mt-3 text-xs bg-yellow-500/20 text-yellow-400 px-2 py-1 rounded">
                        Próximamente
                    </span>
                </div>

                {/* Backups */}
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10 opacity-60">
                    <div className="text-4xl mb-4">💾</div>
                    <h3 className="text-xl font-semibold text-white">
                        Respaldos
                    </h3>
                    <p className="text-gray-400 mt-2 text-sm">
                        Gestionar backups de datos
                    </p>
                    <span className="inline-block mt-3 text-xs bg-yellow-500/20 text-yellow-400 px-2 py-1 rounded">
                        Próximamente
                    </span>
                </div>
            </div>

            {/* Quick Stats */}
            <div className="bg-white/5 backdrop-blur-lg rounded-xl p-6 border border-white/10">
                <h2 className="text-lg font-semibold text-white mb-4">📊 Estado del Sistema</h2>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="text-center">
                        <div className="text-2xl font-bold text-green-400">✓</div>
                        <div className="text-gray-400 text-sm">Base de Datos</div>
                    </div>
                    <div className="text-center">
                        <div className="text-2xl font-bold text-green-400">✓</div>
                        <div className="text-gray-400 text-sm">API</div>
                    </div>
                    <div className="text-center">
                        <div className="text-2xl font-bold text-green-400">✓</div>
                        <div className="text-gray-400 text-sm">Autenticación</div>
                    </div>
                    <div className="text-center">
                        <div className="text-2xl font-bold text-green-400">✓</div>
                        <div className="text-gray-400 text-sm">Storage</div>
                    </div>
                </div>
            </div>
        </div>
    )
}
