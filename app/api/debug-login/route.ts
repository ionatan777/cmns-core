import { createClient } from '@/lib/supabase/server'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST() {
    try {
        const supabase = await createClient()

        // Crear el usuario de debug directamente en Supabase Auth
        // Usar email y contraseña que especificaste
        const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
            email: 'codelylabs.tech@yahoo.com',
            password: 'maya2026.',
        })

        if (authError) {
            console.error('Auth error:', authError)

            // Si no existe, intentar crear el usuario
            const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
                email: 'codelylabs.tech@yahoo.com',
                password: 'maya2026.',
                options: {
                    emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
                }
            })

            if (signUpError) {
                console.error('SignUp error:', signUpError)
                return NextResponse.json({ error: signUpError.message }, { status: 400 })
            }

            // Si el signup fue exitoso, devolver la sesión
            if (signUpData.session) {
                return NextResponse.json({
                    success: true,
                    message: 'Usuario creado y sesión iniciada',
                    user: signUpData.user
                })
            }
        }

        if (authData?.session) {
            return NextResponse.json({
                success: true,
                message: 'Sesión iniciada exitosamente',
                user: authData.user
            })
        }

        return NextResponse.json({ error: 'No se pudo crear la sesión' }, { status: 400 })

    } catch (error: any) {
        console.error('Debug login error:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
    }
}
