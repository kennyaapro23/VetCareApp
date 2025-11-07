<?php

namespace App\Http\Controllers;

use App\Models\Cliente;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClienteController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:sanctum');
    }

    /**
     * Listar clientes
     */
    public function index(Request $request)
    {
        $query = Cliente::with(['user', 'mascotas']);

        // Búsqueda por nombre o email
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nombre', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('telefono', 'like', "%{$search}%");
            });
        }

        $clientes = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json($clientes);
    }

    /**
     * Crear cliente
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id|unique:clientes,user_id',
            'nombre' => 'required|string|max:150',
            'telefono' => 'nullable|string|max:20',
            'email' => 'required|email|unique:clientes,email',
            'documento_tipo' => 'nullable|string|max:50',
            'documento_num' => 'nullable|string|max:50',
            'direccion' => 'nullable|string|max:255',
            'notas' => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            $cliente = Cliente::create($validated);

            // Auditoría
            \App\Models\AuditLog::create([
                'user_id' => auth()->id(),
                'accion' => 'crear_cliente',
                'tabla' => 'clientes',
                'registro_id' => $cliente->id,
                'cambios' => json_encode($cliente->toArray()),
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Cliente creado exitosamente',
                'cliente' => $cliente
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al crear cliente: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ver cliente
     */
    public function show($id)
    {
        $cliente = Cliente::with([
            'user',
            'mascotas',
            'citas' => function ($query) {
                $query->latest()->limit(10)->with(['mascota', 'veterinario']);
            },
            'facturas'
        ])->findOrFail($id);

        return response()->json($cliente);
    }

    /**
     * Actualizar cliente
     */
    public function update(Request $request, $id)
    {
        $cliente = Cliente::findOrFail($id);

        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id|unique:clientes,user_id,' . $id,
            'nombre' => 'sometimes|required|string|max:150',
            'telefono' => 'nullable|string|max:20',
            'email' => 'sometimes|required|email|unique:clientes,email,' . $id,
            'documento_tipo' => 'nullable|string|max:50',
            'documento_num' => 'nullable|string|max:50',
            'direccion' => 'nullable|string|max:255',
            'notas' => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            $cliente->update($validated);

            // Auditoría
            \App\Models\AuditLog::create([
                'user_id' => auth()->id(),
                'accion' => 'actualizar_cliente',
                'tabla' => 'clientes',
                'registro_id' => $cliente->id,
                'cambios' => json_encode($cliente->getChanges()),
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Cliente actualizado exitosamente',
                'cliente' => $cliente
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al actualizar cliente: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Eliminar cliente
     */
    public function destroy($id)
    {
        $cliente = Cliente::findOrFail($id);

        // Verificar si tiene mascotas
        if ($cliente->mascotas()->count() > 0) {
            return response()->json([
                'error' => 'No se puede eliminar el cliente porque tiene mascotas asociadas'
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Auditoría
            \App\Models\AuditLog::create([
                'user_id' => auth()->id(),
                'accion' => 'eliminar_cliente',
                'tabla' => 'clientes',
                'registro_id' => $cliente->id,
                'cambios' => json_encode($cliente->toArray()),
            ]);

            $cliente->delete();

            DB::commit();

            return response()->json([
                'message' => 'Cliente eliminado exitosamente'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al eliminar cliente: ' . $e->getMessage()
            ], 500);
        }
    }
}
