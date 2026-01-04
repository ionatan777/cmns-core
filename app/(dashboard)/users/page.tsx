'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'

type User = {
    id: string
    email: string
    name: string
    role: 'owner' | 'admin' | 'user'
    status: 'active' | 'inactive'
    created_at: string
    last_sign_in: string | null
}

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([])
    const [loading, setLoading] = useState(true)
    const [showModal, setShowModal] = useState(false)
    const [newUser, setNewUser] = useState({ email: '', password: '', name: '', role: 'user' })
    const [creating, setCreating] = useState(false)
    const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null)

    useEffect(() => {
        fetchUsers()
    }, [])

    const fetchUsers = async () => {
        try {
            const res = await fetch('/api/users')
            const data = await res.json()
            if (data.users) {
                setUsers(data.users)
            }
        } catch (error) {
            console.error('Error fetching users:', error)
        } finally {
            setLoading(false)
        }
    }

    const handleCreateUser = async (e: React.FormEvent) => {
        e.preventDefault()
        setCreating(true)
        setMessage(null)

        try {
            const res = await fetch('/api/users', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(newUser)
            })
            const data = await res.json()

            if (res.ok) {
                setMessage({ type: 'success', text: '✅ Usuario creado exitosamente' })
                setNewUser({ email: '', password: '', name: '', role: 'user' })
                setShowModal(false)
                fetchUsers()
            } else {
                setMessage({ type: 'error', text: data.error || 'Error al crear usuario' })
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'Error de conexión' })
        } finally {
            setCreating(false)
        }
    }

    const getRoleBadge = (role: string) => {
        const styles = {
            owner: 'bg-purple-500/20 text-purple-400 border-purple-500/30',
            admin: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
            user: 'bg-gray-500/20 text-gray-400 border-gray-500/30'
        }
        return styles[role as keyof typeof styles] || styles.user
    }

    const getStatusBadge = (status: string) => {
        return status === 'active'
            ? 'bg-green-500/20 text-green-400 border-green-500/30'
            : 'bg-red-500/20 text-red-400 border-red-500/30'
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-3xl font-bold text-white">👥 Gestión de Usuarios</h1>
                    <p className="text-gray-400 mt-1">Administra los usuarios del sistema</p>
                </div>
                <button
                    onClick={() => setShowModal(true)}
                    className="flex items-center gap-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-4 py-2 rounded-lg font-medium transition-all"
                >
                    <span className="text-xl">+</span>
                    Nuevo Usuario
                </button>
            </div>

            {/* Message */}
            {message && (
                <div className={`p-4 rounded-lg ${message.type === 'success' ? 'bg-green-500/20 text-green-400 border border-green-500/30' : 'bg-red-500/20 text-red-400 border border-red-500/30'}`}>
                    {message.text}
                </div>
            )}

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-4 border border-white/10">
                    <div className="text-2xl font-bold text-white">{users.length}</div>
                    <div className="text-gray-400 text-sm">Total Usuarios</div>
                </div>
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-4 border border-white/10">
                    <div className="text-2xl font-bold text-green-400">{users.filter(u => u.status === 'active').length}</div>
                    <div className="text-gray-400 text-sm">Activos</div>
                </div>
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-4 border border-white/10">
                    <div className="text-2xl font-bold text-purple-400">{users.filter(u => u.role === 'admin' || u.role === 'owner').length}</div>
                    <div className="text-gray-400 text-sm">Administradores</div>
                </div>
                <div className="bg-white/5 backdrop-blur-lg rounded-xl p-4 border border-white/10">
                    <div className="text-2xl font-bold text-blue-400">{users.filter(u => u.role === 'user').length}</div>
                    <div className="text-gray-400 text-sm">Usuarios Estándar</div>
                </div>
            </div>

            {/* Users Table */}
            <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 overflow-hidden">
                <div className="p-4 border-b border-white/10">
                    <h2 className="text-lg font-semibold text-white">Lista de Usuarios</h2>
                </div>

                {loading ? (
                    <div className="p-8 text-center text-gray-400">
                        <div className="animate-spin w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
                        Cargando usuarios...
                    </div>
                ) : users.length === 0 ? (
                    <div className="p-8 text-center text-gray-400">
                        <div className="text-4xl mb-4">👤</div>
                        <p>No hay usuarios registrados</p>
                        <button
                            onClick={() => setShowModal(true)}
                            className="mt-4 text-blue-400 hover:text-blue-300"
                        >
                            Crear el primer usuario →
                        </button>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-white/5">
                                <tr>
                                    <th className="text-left p-4 text-gray-400 font-medium">Usuario</th>
                                    <th className="text-left p-4 text-gray-400 font-medium">Email</th>
                                    <th className="text-left p-4 text-gray-400 font-medium">Rol</th>
                                    <th className="text-left p-4 text-gray-400 font-medium">Estado</th>
                                    <th className="text-left p-4 text-gray-400 font-medium">Último Acceso</th>
                                    <th className="text-right p-4 text-gray-400 font-medium">Acciones</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5">
                                {users.map((user) => (
                                    <tr key={user.id} className="hover:bg-white/5 transition-colors">
                                        <td className="p-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center text-white font-bold">
                                                    {user.name?.charAt(0)?.toUpperCase() || user.email?.charAt(0)?.toUpperCase() || '?'}
                                                </div>
                                                <div>
                                                    <div className="text-white font-medium">{user.name || 'Sin nombre'}</div>
                                                    <div className="text-gray-500 text-sm">ID: {user.id.substring(0, 8)}...</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="p-4 text-gray-300">{user.email}</td>
                                        <td className="p-4">
                                            <span className={`px-2 py-1 rounded-full text-xs border ${getRoleBadge(user.role)}`}>
                                                {user.role === 'owner' ? '👑 Owner' : user.role === 'admin' ? '⚡ Admin' : '👤 User'}
                                            </span>
                                        </td>
                                        <td className="p-4">
                                            <span className={`px-2 py-1 rounded-full text-xs border ${getStatusBadge(user.status)}`}>
                                                {user.status === 'active' ? '🟢 Activo' : '🔴 Inactivo'}
                                            </span>
                                        </td>
                                        <td className="p-4 text-gray-400 text-sm">
                                            {user.last_sign_in ? new Date(user.last_sign_in).toLocaleDateString('es-ES') : 'Nunca'}
                                        </td>
                                        <td className="p-4 text-right">
                                            <Link
                                                href={`/users/${user.id}`}
                                                className="text-blue-400 hover:text-blue-300 text-sm"
                                            >
                                                Editar →
                                            </Link>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Create User Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
                    <div className="bg-gray-900 border border-white/10 rounded-2xl p-6 w-full max-w-md mx-4 shadow-2xl">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold text-white">➕ Crear Usuario</h2>
                            <button
                                onClick={() => setShowModal(false)}
                                className="text-gray-400 hover:text-white text-2xl"
                            >
                                ×
                            </button>
                        </div>

                        <form onSubmit={handleCreateUser} className="space-y-4">
                            <div>
                                <label className="block text-gray-400 text-sm mb-2">Nombre</label>
                                <input
                                    type="text"
                                    value={newUser.name}
                                    onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                                    placeholder="Nombre del usuario"
                                />
                            </div>

                            <div>
                                <label className="block text-gray-400 text-sm mb-2">Email *</label>
                                <input
                                    type="email"
                                    required
                                    value={newUser.email}
                                    onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                                    placeholder="email@ejemplo.com"
                                />
                            </div>

                            <div>
                                <label className="block text-gray-400 text-sm mb-2">Contraseña *</label>
                                <input
                                    type="password"
                                    required
                                    minLength={6}
                                    value={newUser.password}
                                    onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                                    placeholder="Mínimo 6 caracteres"
                                />
                            </div>

                            <div>
                                <label className="block text-gray-400 text-sm mb-2">Rol</label>
                                <select
                                    value={newUser.role}
                                    onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-blue-500"
                                >
                                    <option value="user" className="bg-gray-900">👤 Usuario</option>
                                    <option value="admin" className="bg-gray-900">⚡ Administrador</option>
                                    <option value="owner" className="bg-gray-900">👑 Owner</option>
                                </select>
                            </div>

                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => setShowModal(false)}
                                    className="flex-1 bg-white/5 hover:bg-white/10 text-white py-3 rounded-lg transition-colors"
                                >
                                    Cancelar
                                </button>
                                <button
                                    type="submit"
                                    disabled={creating}
                                    className="flex-1 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white py-3 rounded-lg font-medium transition-all disabled:opacity-50"
                                >
                                    {creating ? 'Creando...' : 'Crear Usuario'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    )
}
