import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// GET - Listar todos los usuarios
export async function GET() {
    try {
        const supabase = await createClient()

        // Obtener usuarios de la tabla profiles
        const { data: profiles, error: profilesError } = await supabase
            .from('profiles')
            .select('*')
            .order('created_at', { ascending: false })

        if (profilesError) {
            console.error('Error fetching profiles:', profilesError)

            // Si la tabla profiles no existe, devolver array vacío
            if (profilesError.code === '42P01') {
                return NextResponse.json({ users: [], message: 'Tabla profiles no encontrada' })
            }
        }

        // Transformar datos
        const users = (profiles || []).map(profile => ({
            id: profile.id,
            email: profile.email || '',
            name: profile.full_name || profile.name || '',
            role: profile.role || 'user',
            status: profile.status || 'active',
            created_at: profile.created_at,
            last_sign_in: profile.last_sign_in_at || null
        }))

        return NextResponse.json({ users })

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

        const supabase = await createClient()

        // Crear usuario en Supabase Auth
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true, // Auto-confirmar email
            user_metadata: {
                full_name: name,
                role: role || 'user'
            }
        })

        if (authError) {
            console.error('Auth error:', authError)

            // Si admin API no está disponible, intentar signup normal
            const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        full_name: name,
                        role: role || 'user'
                    }
                }
            })

            if (signUpError) {
                return NextResponse.json({ error: signUpError.message }, { status: 400 })
            }

            // Intentar crear perfil manualmente
            if (signUpData.user) {
                try {
                    await supabase.from('profiles').upsert({
                        id: signUpData.user.id,
                        email: email,
                        full_name: name,
                        role: role || 'user',
                        status: 'active',
                        created_at: new Date().toISOString()
                    })
                } catch (e) {
                    console.log('Profile creation optional:', e)
                }
            }

            return NextResponse.json({
                success: true,
                message: 'Usuario creado (requiere confirmación de email)',
                user: signUpData.user
            })
        }

        // Si admin API funcionó, crear perfil
        if (authData.user) {
            try {
                await supabase.from('profiles').upsert({
                    id: authData.user.id,
                    email: email,
                    full_name: name,
                    role: role || 'user',
                    status: 'active',
                    created_at: new Date().toISOString()
                })
            } catch (e) {
                console.log('Profile creation optional:', e)
            }
        }

        return NextResponse.json({
            success: true,
            message: 'Usuario creado exitosamente',
            user: authData.user
        })

    } catch (error: any) {
        console.error('Error in POST /api/users:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
    }
}
