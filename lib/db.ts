import { neon } from '@neondatabase/serverless'

// Crear cliente de Neon
export function getDb() {
    const databaseUrl = process.env.DATABASE_URL

    if (!databaseUrl) {
        throw new Error('DATABASE_URL environment variable is not set')
    }

    return neon(databaseUrl)
}

// Helper para ejecutar queries
export async function query<T = any>(sql: string, params: any[] = []): Promise<T[]> {
    const db = getDb()
    const result = await db(sql, params)
    return result as T[]
}

// Helper para ejecutar un query y obtener un solo resultado
export async function queryOne<T = any>(sql: string, params: any[] = []): Promise<T | null> {
    const results = await query<T>(sql, params)
    return results[0] || null
}
