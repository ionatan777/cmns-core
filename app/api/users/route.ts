import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'
import { v4 as uuidv4 } from 'uuid'

// GET - Listar todos los usuarios
export async function GET() {
    try {
        const supabase = await createClient()

        // Obtener usuarios de la tabla app_users (nuestra tabla propia)
        const { data: users, error } = await supabase
            .from('app_users')
            .select('*')
            .order('created_at', { ascending: false })

        if (error) {
            console.error('Error fetching users:', error)

            // Si la tabla no existe, devolver array vacío
            if (error.code === '42P01') {
                return NextResponse.json({
                    users: [],
                    message: 'Tabla app_users no encontrada. Ejecuta la migración.',
                    needsMigration: true
                })
            }
            return NextResponse.json({ error: error.message, users: [] }, { status: 500 })
        }

        return NextResponse.json({ users: users || [] })

    } catch (error: any) {
        console.error('Error in GET /api/users:', error)
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

        const supabase = await createClient()

        // Verificar si el email ya existe
        const { data: existing } = await supabase
            .from('app_users')
            .select('id')
            .eq('email', email.toLowerCase())
            .single()

        if (existing) {
            return NextResponse.json({ error: 'El email ya está registrado' }, { status: 400 })
        }

        // Crear usuario en nuestra tabla propia
        const userId = uuidv4()
        const now = new Date().toISOString()

        // Hash simple de contraseña (en producción usar bcrypt)
        const passwordHash = Buffer.from(password).toString('base64')

        const { data: newUser, error: insertError } = await supabase
            .from('app_users')
            .insert({
                id: userId,
                email: email.toLowerCase(),
                password_hash: passwordHash,
                name: name || '',
                role: role || 'user',
                status: 'active',
                created_at: now,
                updated_at: now
            })
            .select()
            .single()

        if (insertError) {
            console.error('Insert error:', insertError)
            return NextResponse.json({ error: insertError.message }, { status: 400 })
        }

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
