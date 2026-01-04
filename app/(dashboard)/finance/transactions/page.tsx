import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table"

// Mock data - will be replaced with real Supabase data
const mockTransactions = [
    {
        id: '1',
        date: '2026-01-02',
        type: 'income' as const,
        amount: 500,
        category: 'Venta Landing',
        account: 'Banco Principal',
        brand: 'CodelyLabs',
        note: 'Landing página inmobiliaria',
    },
    {
        id: '2',
        date: '2026-01-01',
        type: 'expense' as const,
        amount: 45,
        category: 'Marketing',
        account: 'Efectivo',
        brand: 'Camvys',
        note: 'Publicidad Facebook',
    },
]

export default function TransactionsPage() {
    return (
        <div className="flex min-h-screen flex-col">
            {/* Header */}
            <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
                <div className="flex h-16 items-center gap-4 px-6">
                    <h1 className="text-xl font-semibold">Transacciones</h1>
                    <div className="ml-auto flex items-center gap-4">
                        <Button variant="outline" size="sm">
                            Filtros
                        </Button>
                        <Button asChild size="sm">
                            <a href="/finance/new">+ Nueva Transacción</a>
                        </Button>
                    </div>
                </div>
            </header>

            {/* Content */}
            <div className="flex-1 space-y-6 p-6">
                {/* Summary Cards */}
                <div className="grid gap-4 md:grid-cols-3">
                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Ingresos del Mes</CardDescription>
                            <CardTitle className="text-3xl text-green-600">+$500.00</CardTitle>
                        </CardHeader>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Gastos del Mes</CardDescription>
                            <CardTitle className="text-3xl text-red-600">-$45.00</CardTitle>
                        </CardHeader>
                    </Card>
                    <Card>
                        <CardHeader className="pb-3">
                            <CardDescription>Neto del Mes</CardDescription>
                            <CardTitle className="text-3xl">$455.00</CardTitle>
                        </CardHeader>
                    </Card>
                </div>

                {/* Transactions Table */}
                <Card>
                    <CardHeader>
                        <CardTitle>Historial de Transacciones</CardTitle>
                        <CardDescription>
                            Todas las transacciones de la organización
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Fecha</TableHead>
                                    <TableHead>Tipo</TableHead>
                                    <TableHead>Categoría</TableHead>
                                    <TableHead>Marca</TableHead>
                                    <TableHead>Cuenta</TableHead>
                                    <TableHead>Nota</TableHead>
                                    <TableHead className="text-right">Monto</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {mockTransactions.map((tx) => (
                                    <TableRow key={tx.id}>
                                        <TableCell className="font-medium">
                                            {new Date(tx.date).toLocaleDateString('es-ES')}
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant={tx.type === 'income' ? 'default' : 'destructive'}>
                                                {tx.type === 'income' ? 'Ingreso' : 'Gasto'}
                                            </Badge>
                                        </TableCell>
                                        <TableCell>{tx.category}</TableCell>
                                        <TableCell>
                                            <span className="text-sm text-muted-foreground">{tx.brand}</span>
                                        </TableCell>
                                        <TableCell className="text-sm text-muted-foreground">
                                            {tx.account}
                                        </TableCell>
                                        <TableCell className="max-w-[200px] truncate text-sm text-muted-foreground">
                                            {tx.note}
                                        </TableCell>
                                        <TableCell className="text-right font-medium">
                                            <span className={tx.type === 'income' ? 'text-green-600' : 'text-red-600'}>
                                                {tx.type === 'income' ? '+' : '-'}${tx.amount.toFixed(2)}
                                            </span>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>

                        {mockTransactions.length === 0 && (
                            <div className="flex flex-col items-center justify-center py-12 text-center">
                                <p className="text-lg font-medium text-muted-foreground">
                                    No hay transacciones registradas
                                </p>
                                <p className="mt-2 text-sm text-muted-foreground">
                                    Crea tu primera transacción para comenzar a trackear tus finanzas
                                </p>
                                <Button asChild className="mt-4">
                                    <a href="/finance/new">+ Nueva Transacción</a>
                                </Button>
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}
