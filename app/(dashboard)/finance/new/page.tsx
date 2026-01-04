"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"

export default function NewTransactionPage() {
    const [type, setType] = useState<'income' | 'expense'>('income')
    const [amount, setAmount] = useState('')
    const [category, setCategory] = useState('')
    const [note, setNote] = useState('')

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()
        // TODO: Implement transaction creation with Supabase
        console.log('Creating transaction:', { type, amount, category, note })
        alert('Funcionalidad de creación pendiente - conectar con Supabase')
    }

    return (
        <div className="flex min-h-screen flex-col">
            {/* Header */}
            <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
                <div className="flex h-16 items-center gap-4 px-6">
                    <h1 className="text-xl font-semibold">Nueva Transacción</h1>
                    <div className="ml-auto">
                        <Button variant="ghost" asChild>
                            <a href="/finance/transactions">Cancelar</a>
                        </Button>
                    </div>
                </div>
            </header>

            {/* Content */}
            <div className="flex-1 p-6">
                <div className="mx-auto max-w-2xl">
                    <Card>
                        <CardHeader>
                            <CardTitle>Registrar Movimiento</CardTitle>
                            <CardDescription>
                                Registra un ingreso o gasto. El sistema aplicará las reglas de asignación automáticamente.
                            </CardDescription>
                        </CardHeader>
                        <CardContent>
                            <form onSubmit={handleSubmit} className="space-y-6">
                                {/* Tipo de Transacción */}
                                <div className="space-y-2">
                                    <Label>Tipo de Transacción</Label>
                                    <div className="grid grid-cols-2 gap-4">
                                        <Button
                                            type="button"
                                            variant={type === 'income' ? 'default' : 'outline'}
                                            className="h-20"
                                            onClick={() => setType('income')}
                                        >
                                            <div className="text-center">
                                                <div className="text-2xl">💰</div>
                                                <div className="mt-1 font-semibold">Ingreso</div>
                                            </div>
                                        </Button>
                                        <Button
                                            type="button"
                                            variant={type === 'expense' ? 'default' : 'outline'}
                                            className="h-20"
                                            onClick={() => setType('expense')}
                                        >
                                            <div className="text-center">
                                                <div className="text-2xl">💸</div>
                                                <div className="mt-1 font-semibold">Gasto</div>
                                            </div>
                                        </Button>
                                    </div>
                                </div>

                                {/* Monto */}
                                <div className="space-y-2">
                                    <Label htmlFor="amount">Monto (USD)</Label>
                                    <Input
                                        id="amount"
                                        type="number"
                                        step="0.01"
                                        placeholder="0.00"
                                        value={amount}
                                        onChange={(e) => setAmount(e.target.value)}
                                        required
                                        className="text-2xl"
                                    />
                                </div>

                                {/* Marca */}
                                <div className="space-y-2">
                                    <Label htmlFor="brand">Marca</Label>
                                    <Select>
                                        <SelectTrigger id="brand">
                                            <SelectValue placeholder="Selecciona una marca" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="camvys">Camvys</SelectItem>
                                            <SelectItem value="codelylabs">CodelyLabs</SelectItem>
                                            <SelectItem value="zypher">Zypher</SelectItem>
                                        </SelectContent>
                                    </Select>
                                </div>

                                {/* Cuenta */}
                                <div className="space-y-2">
                                    <Label htmlFor="account">Cuenta</Label>
                                    <Select>
                                        <SelectTrigger id="account">
                                            <SelectValue placeholder="Selecciona una cuenta" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="bank">Banco Principal</SelectItem>
                                            <SelectItem value="cash">Efectivo</SelectItem>
                                            <SelectItem value="camvys-bank">Banco Camvys</SelectItem>
                                        </SelectContent>
                                    </Select>
                                </div>

                                {/* Categoría */}
                                <div className="space-y-2">
                                    <Label htmlFor="category">Categoría</Label>
                                    <Input
                                        id="category"
                                        placeholder="Ej: Venta Landing, Marketing, Reposición"
                                        value={category}
                                        onChange={(e) => setCategory(e.target.value)}
                                    />
                                    <p className="text-sm text-muted-foreground">
                                        {type === 'income' && '💡 Tip: "Venta Landing" activará la regla de CodelyLabs'}
                                        {type === 'expense' && '💡 Tip: "Marketing" asignará al fondo de Marketing'}
                                    </p>
                                </div>

                                {/* Nota */}
                                <div className="space-y-2">
                                    <Label htmlFor="note">Nota (Opcional)</Label>
                                    <Textarea
                                        id="note"
                                        placeholder="Descripción adicional..."
                                        value={note}
                                        onChange={(e) => setNote(e.target.value)}
                                        rows={3}
                                    />
                                </div>

                                {/* Fecha */}
                                <div className="space-y-2">
                                    <Label htmlFor="date">Fecha</Label>
                                    <Input
                                        id="date"
                                        type="date"
                                        defaultValue={new Date().toISOString().split('T')[0]}
                                        required
                                    />
                                </div>

                                {/* Submit */}
                                <div className="flex gap-4 pt-4">
                                    <Button type="submit" className="flex-1" size="lg">
                                        Registrar Transacción
                                    </Button>
                                    <Button type="button" variant="outline" asChild>
                                        <a href="/finance/transactions">Cancelar</a>
                                    </Button>
                                </div>
                            </form>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
