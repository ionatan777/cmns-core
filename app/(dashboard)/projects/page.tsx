import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import Link from 'next/link'

export default async function ProjectsPage() {
    const supabase = await createClient()

    const { data: projects } = await supabase
        .from('projects')
        .select(`
      *,
      brand:brands(id, name),
      checklist:project_checklist(id, done)
    `)
        .order('created_at', { ascending: false })

    const stats = {
        total: projects?.length || 0,
        active: projects?.filter(p => p.status === 'in_progress').length || 0,
        completed: projects?.filter(p => p.status === 'completed').length || 0,
    }

    const getStatusBadge = (status: string) => {
        const variants: Record<string, any> = {
            draft: { label: 'Borrador', variant: 'secondary' },
            in_progress: { label: 'En Progreso', variant: 'default' },
            completed: { label: 'Completado', variant: 'default', className: 'bg-green-600' },
            suspended: { label: 'Suspendido', variant: 'destructive' },
        }
        const config = variants[status] || variants.draft
        return <Badge variant={config.variant} className={config.className}>{config.label}</Badge>
    }

    return (
        <div className="space-y-6 p-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Proyectos</h1>
                    <p className="text-muted-foreground">Landings de CodelyLabs</p>
                </div>
                <Button asChild>
                    <Link href="/projects/new">+ Nuevo Proyecto</Link>
                </Button>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Total Proyectos</div>
                        <div className="text-2xl font-bold">{stats.total}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">En Progreso</div>
                        <div className="text-2xl font-bold text-blue-600">{stats.active}</div>
                    </CardHeader>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <div className="text-sm text-muted-foreground">Completados</div>
                        <div className="text-2xl font-bold text-green-600">{stats.completed}</div>
                    </CardHeader>
                </Card>
            </div>

            {/* Projects Grid */}
            {!projects || projects.length === 0 ? (
                <Card>
                    <CardContent className="p-12 text-center">
                        <h3 className="text-lg font-semibold mb-2">No hay proyectos todavía</h3>
                        <p className="text-muted-foreground mb-4">Crea tu primer proyecto para empezar</p>
                        <Button asChild>
                            <Link href="/projects/new">+ Crear Proyecto</Link>
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {projects.map((project: any) => {
                        const checklistItems = project.checklist || []
                        const doneCount = checklistItems.filter((i: any) => i.done).length
                        const totalCount = checklistItems.length
                        const progress = totalCount > 0 ? (doneCount / totalCount) * 100 : 0

                        return (
                            <Card key={project.id} className="hover:shadow-lg transition-shadow">
                                <CardHeader>
                                    <div className="flex items-start justify-between">
                                        <div className="flex-1">
                                            <CardTitle className="text-lg">
                                                <Link href={`/projects/${project.id}`} className="hover:text-blue-600">
                                                    {project.client_name}
                                                </Link>
                                            </CardTitle>
                                            {project.domain && (
                                                <p className="text-sm text-muted-foreground mt-1">{project.domain}</p>
                                            )}
                                        </div>
                                        {getStatusBadge(project.status)}
                                    </div>
                                </CardHeader>
                                <CardContent>
                                    <div className="space-y-2">
                                        <div className="flex items-center justify-between text-sm">
                                            <span className="text-muted-foreground">Checklist</span>
                                            <span className="font-medium">{doneCount}/{totalCount}</span>
                                        </div>
                                        <Progress value={progress} className="h-2" />

                                        {project.published_url && (
                                            <a
                                                href={project.published_url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="text-sm text-blue-600 hover:underline block mt-2"
                                            >
                                                🔗 Ver publicado
                                            </a>
                                        )}
                                    </div>
                                </CardContent>
                            </Card>
                        )
                    })}
                </div>
            )}
        </div>
    )
}
