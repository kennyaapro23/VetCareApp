<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Servicio extends Model
{
    use HasFactory;

    protected $fillable = [
        'codigo',
        'nombre',
        'descripcion',
        'tipo',
        'duracion_minutos',
        'precio',
        'requiere_vacuna_info',
    ];

    protected $casts = [
        'precio' => 'decimal:2',
        'requiere_vacuna_info' => 'boolean',
    ];

    public function citas()
    {
        return $this->belongsToMany(Cita::class, 'cita_servicio')
                    ->withPivot('cantidad', 'precio_unitario', 'notas')
                    ->withTimestamps();
    }

    /**
     * Verificar si el servicio es una vacuna
     */
    public function isVaccine()
    {
        return $this->tipo === 'vacuna';
    }
}
