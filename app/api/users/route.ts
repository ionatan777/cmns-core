import { query, queryOne } from '@/lib/db'
import { NextRequest, NextResponse } from 'next/server'
import { v4 as uuidv4 } from 'uuid'

// GET - Listar todos los usuarios
export async function GET() {
    try {
        const users = await query(`
            SELECT id, email, name, role, status, created_at, updated_at, last_login_at
            FROM app_users
            ORDER BY created_at DESC
        `)

        return NextResponse.json({ users })

    } catch (error: any) {
        console.error('Error in GET /api/users:', error)

        // Si la tabla no existe, devolver mensaje para crear
        if (error.message?.includes('does not exist')) {
            return NextResponse.json({
                users: [],
                message: 'Tabla app_users no encontrada. Ejecuta la migración.',
                needsMigration: true
            })
        }

        return NextResponse.json({ error: error.message, users: [] }, { status: 500 })
    }
}

// POST - Crear nuevo usuario
export async function POST(request: NextRequest) {
    try {
        const body = await request.json()
        const { email, password, name, role } = body

        if (!email || !password) {
            return NextResponse.json({ error: 'Email y contraseña son requeridos' }, { status: 400 })
        }

        if (password.length < 6) {
            return NextResponse.json({ error: 'La contraseña debe tener al menos 6 caracteres' }, { status: 400 })
        }

        // Verificar si el email ya existe
        const existing = await queryOne(`SELECT id FROM app_users WHERE email = $1`, [email.toLowerCase()])

        if (existing) {
            return NextResponse.json({ error: 'El email ya está registrado' }, { status: 400 })
        }

        // Hash simple de contraseña (en producción usar bcrypt)
        const passwordHash = Buffer.from(password).toString('base64')
        const userId = uuidv4()
        const now = new Date().toISOString()

        // Insertar usuario
        await query(`
            INSERT INTO app_users (id, email, password_hash, name, role, status, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, 'active', $6, $6)
        `, [userId, email.toLowerCase(), passwordHash, name || '', role || 'user', now])

        // Obtener usuario creado
        const newUser = await queryOne(`SELECT * FROM app_users WHERE id = $1`, [userId])

        return NextResponse.json({
            success: true,
            message: 'Usuario creado exitosamente',
            user: {
                id: newUser.id,
                email: newUser.email,
                name: newUser.name,
                role: newUser.role,
                status: newUser.status
            }
        })

    } catch (error: any) {
        console.error('Error in POST /api/users:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
    }
}
