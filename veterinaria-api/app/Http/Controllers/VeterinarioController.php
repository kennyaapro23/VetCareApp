<?php

namespace App\Http\Controllers;

use App\Models\Veterinario;
use App\Models\AgendaDisponibilidad;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class VeterinarioController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:sanctum');
    }

    /**
     * Listar veterinarios
     */
    public function index(Request $request)
    {
        $query = Veterinario::with(['user']);

        // Búsqueda por nombre o especialidad
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nombre', 'like', "%{$search}%")
                  ->orWhere('especialidad', 'like', "%{$search}%")
                  ->orWhere('matricula', 'like', "%{$search}%");
            });
        }

        // Filtro por especialidad
        if ($request->has('especialidad')) {
            $query->where('especialidad', $request->especialidad);
        }

        $veterinarios = $query->orderBy('nombre')->paginate(20);

        return response()->json($veterinarios);
    }

    /**
     * Crear veterinario
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id|unique:veterinarios,user_id',
            'nombre' => 'required|string|max:150',
            'matricula' => 'nullable|string|max:50|unique:veterinarios,matricula',
            'especialidad' => 'nullable|string|max:100',
            'telefono' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:150',
            'disponibilidad' => 'nullable|array',
        ]);

        DB::beginTransaction();
        try {
            $veterinario = Veterinario::create($validated);

            // Auditoría
            \App\Models\AuditLog::create([
                'user_id' => auth()->id(),
                'accion' => 'crear_veterinario',
                'tabla' => 'veterinarios',
                'registro_id' => $veterinario->id,
                'cambios' => json_encode($veterinario->toArray()),
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Veterinario creado exitosamente',
                'veterinario' => $veterinario
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al crear veterinario: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ver veterinario
     */
    public function show($id)
    {
        $veterinario = Veterinario::with([
            'user',
            'agendasDisponibilidad',
            'citas' => function ($query) {
                $query->where('fecha', '>=', now())
                      ->orderBy('fecha')
                      ->limit(20)
                      ->with(['mascota', 'cliente']);
            }
        ])->findOrFail($id);

        return response()->json($veterinario);
    }

    /**
     * Actualizar veterinario
     */
    public function update(Request $request, $id)
    {
        $veterinario = Veterinario::findOrFail($id);

        $validated = $request->validate([
            'user_id' => 'nullable|exists:users,id|unique:veterinarios,user_id,' . $id,
            'nombre' => 'sometimes|required|string|max:150',
            'matricula' => 'nullable|string|max:50|unique:veterinarios,matricula,' . $id,
            'especialidad' => 'nullable|string|max:100',
            'telefono' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:150',
            'disponibilidad' => 'nullable|array',
        ]);

        DB::beginTransaction();
        try {
            $veterinario->update($validated);

            // Auditoría
            \App\Models\AuditLog::create([
                'user_id' => auth()->id(),
                'accion' => 'actualizar_veterinario',
                'tabla' => 'veterinarios',
                'registro_id' => $veterinario->id,
                'cambios' => json_encode($veterinario->getChanges()),
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Veterinario actualizado exitosamente',
                'veterinario' => $veterinario
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al actualizar veterinario: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Eliminar veterinario
     */
    public function destroy($id)
    {
        $veterinario = Veterinario::findOrFail($id);

        // Verificar si tiene citas futuras
        $citasFuturas = $veterinario->citas()->where('fecha', '>=', now())->count();
        if ($citasFuturas > 0) {
            return response()->json([
                'error' => 'No se puede eliminar el veterinario porque tiene citas futuras programadas'
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Auditoría
            \App\Models\AuditLog::create([
                'user_id' => auth()->id(),
                'accion' => 'eliminar_veterinario',
                'tabla' => 'veterinarios',
                'registro_id' => $veterinario->id,
                'cambios' => json_encode($veterinario->toArray()),
            ]);

            $veterinario->delete();

            DB::commit();

            return response()->json([
                'message' => 'Veterinario eliminado exitosamente'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al eliminar veterinario: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener disponibilidad de un veterinario
     */
    public function getDisponibilidad($id, Request $request)
    {
        $veterinario = Veterinario::findOrFail($id);

        // Obtener fecha (por defecto hoy)
        $fecha = $request->query('fecha', now()->format('Y-m-d'));
        $diaSemana = \Carbon\Carbon::parse($fecha)->dayOfWeek;

        // Obtener horarios configurados para ese día
        $agendas = AgendaDisponibilidad::where('veterinario_id', $id)
            ->where('dia_semana', $diaSemana)
            ->where('activo', true)
            ->get();

        // Obtener citas ya agendadas para ese día
        $citas = \App\Models\Cita::where('veterinario_id', $id)
            ->whereDate('fecha', $fecha)
            ->whereNotIn('estado', ['cancelada'])
            ->select('fecha', 'duracion_minutos')
            ->get();

        return response()->json([
            'veterinario' => $veterinario->only(['id', 'nombre', 'especialidad']),
            'fecha' => $fecha,
            'dia_semana' => $diaSemana,
            'horarios_configurados' => $agendas,
            'citas_agendadas' => $citas,
        ]);
    }

    /**
     * Configurar horarios de disponibilidad
     */
    public function setDisponibilidad(Request $request, $id)
    {
        $veterinario = Veterinario::findOrFail($id);

        $validated = $request->validate([
            'horarios' => 'required|array',
            'horarios.*.dia_semana' => 'required|integer|between:0,6',
            'horarios.*.hora_inicio' => 'required|date_format:H:i',
            'horarios.*.hora_fin' => 'required|date_format:H:i|after:horarios.*.hora_inicio',
            'horarios.*.intervalo_minutos' => 'required|integer|min:10|max:120',
            'horarios.*.activo' => 'required|boolean',
        ]);

        DB::beginTransaction();
        try {
            // Eliminar horarios anteriores
            AgendaDisponibilidad::where('veterinario_id', $id)->delete();

            // Crear nuevos horarios
            foreach ($validated['horarios'] as $horario) {
                AgendaDisponibilidad::create([
                    'veterinario_id' => $id,
                    'dia_semana' => $horario['dia_semana'],
                    'hora_inicio' => $horario['hora_inicio'],
                    'hora_fin' => $horario['hora_fin'],
                    'intervalo_minutos' => $horario['intervalo_minutos'],
                    'activo' => $horario['activo'],
                ]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Horarios de disponibilidad configurados exitosamente',
                'horarios' => $veterinario->agendasDisponibilidad
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => 'Error al configurar horarios: ' . $e->getMessage()
            ], 500);
        }
    }
}
