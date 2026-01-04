'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function DebugAccessPage() {
    const router = useRouter()
    const [loading, setLoading] = useState(false)

    const handleDebugLogin = async () => {
        setLoading(true)
        try {
            // Llamar a la API de debug login
            const response = await fetch('/api/debug-login', {
                method: 'POST',
            })

            if (response.ok) {
                // Redirigir al dashboard
                router.push('/overview')
                router.refresh()
            } else {
                alert('Error al crear sesión de debug')
            }
        } catch (error) {
            console.error('Error:', error)
            alert('Error de conexión')
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-purple-900 via-blue-900 to-black">
            <div className="bg-white/10 backdrop-blur-lg p-8 rounded-2xl shadow-2xl border border-white/20 max-w-md w-full">
                <h1 className="text-3xl font-bold text-white mb-2 text-center">
                    🔧 Debug Access
                </h1>
                <p className="text-white/70 text-center mb-8">
                    Acceso temporal de desarrollo
                </p>

                <button
                    onClick={handleDebugLogin}
                    disabled={loading}
                    className="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-semibold py-4 px-6 rounded-xl transition-all duration-200 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    {loading ? 'Accediendo...' : '🚀 Acceder al Dashboard'}
                </button>

                <p className="text-white/50 text-xs text-center mt-6">
                    ⚠️ Solo para desarrollo - Remover en producción
                </p>
            </div>
        </div>
    )
}
