<?php

namespace App\Http\Controllers;

use App\Models\Cliente;
use App\Models\Mascota;
use Illuminate\Http\Request;

class QRController extends Controller
{
    /**
     * Lookup de QR code
     * Recibe un token (UUID) y tipo (mascota, cliente)
     * Devuelve datos del recurso
     */
    public function lookup(Request $request, $token)
    {
        $type = $request->query('type', 'mascota');

        // Validar formato UUID
        if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i', $token)) {
            return response()->json([
                'error' => 'Token inválido'
            ], 400);
        }

        try {
            if ($type === 'mascota') {
                $mascota = Mascota::where('public_id', $token)
                    ->with([
                        'cliente',
                        'historialMedicos' => function ($query) {
                            $query->latest()->limit(5)->with('realizadoPor');
                        },
                        'citas' => function ($query) {
                            $query->latest()->limit(5)->with('veterinario');
                        }
                    ])
                    ->firstOrFail();

                return response()->json([
                    'type' => 'mascota',
                    'data' => [
                        'id' => $mascota->id,
                        'nombre' => $mascota->nombre,
                        'especie' => $mascota->especie,
                        'raza' => $mascota->raza,
                        'sexo' => $mascota->sexo,
                        'fecha_nacimiento' => $mascota->fecha_nacimiento,
                        'chip_id' => $mascota->chip_id,
                        'foto_url' => $mascota->foto_url,
                        'cliente' => [
                            'nombre' => $mascota->cliente->nombre,
                            'telefono' => $mascota->cliente->telefono,
                            'email' => $mascota->cliente->email,
                        ],
                        'historial_medico' => $mascota->historialMedicos,
                        'ultimas_citas' => $mascota->citas,
                    ]
                ]);
            }

            if ($type === 'cliente') {
                $cliente = Cliente::where('public_id', $token)
                    ->with([
                        'mascotas',
                        'citas' => function ($query) {
                            $query->latest()->limit(10)->with(['mascota', 'veterinario']);
                        }
                    ])
                    ->firstOrFail();

                return response()->json([
                    'type' => 'cliente',
                    'data' => [
                        'id' => $cliente->id,
                        'nombre' => $cliente->nombre,
                        'email' => $cliente->email,
                        'telefono' => $cliente->telefono,
                        'direccion' => $cliente->direccion,
                        'mascotas' => $cliente->mascotas,
                        'ultimas_citas' => $cliente->citas,
                    ]
                ]);
            }

            return response()->json([
                'error' => 'Tipo no válido. Use: mascota o cliente'
            ], 400);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'error' => 'Recurso no encontrado'
            ], 404);
        }
    }

    /**
     * Generar QR para una mascota
     */
    public function generateMascotaQR($id)
    {
        $mascota = Mascota::findOrFail($id);

        // URL del lookup
        $url = route('api.qr.lookup', [
            'token' => $mascota->public_id,
            'type' => 'mascota'
        ]);

        // TODO: Generar QR usando SimpleSoftwareIO/simple-qrcode
        // $qrCode = QrCode::format('png')->size(300)->generate($url);

        return response()->json([
            'mascota_id' => $mascota->id,
            'public_id' => $mascota->public_id,
            'qr_url' => $url,
            // 'qr_image' => base64_encode($qrCode), // Imagen en base64
        ]);
    }

    /**
     * Generar QR para un cliente
     */
    public function generateClienteQR($id)
    {
        $cliente = Cliente::findOrFail($id);

        $url = route('api.qr.lookup', [
            'token' => $cliente->public_id,
            'type' => 'cliente'
        ]);

        return response()->json([
            'cliente_id' => $cliente->id,
            'public_id' => $cliente->public_id,
            'qr_url' => $url,
        ]);
    }
}
