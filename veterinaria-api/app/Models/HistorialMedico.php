<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HistorialMedico extends Model
{
    use HasFactory;

    protected $fillable = [
        'mascota_id',
        'cita_id',
        'fecha',
        'tipo',
        'diagnostico',
        'tratamiento',
        'observaciones',
        'realizado_por',
        'archivos_meta',
    ];

    protected $casts = [
        'fecha' => 'datetime',
        'archivos_meta' => 'array',
    ];

    public function mascota()
    {
        return $this->belongsTo(Mascota::class);
    }

    public function cita()
    {
        return $this->belongsTo(Cita::class);
    }

    public function realizadoPor()
    {
        return $this->belongsTo(Veterinario::class, 'realizado_por');
    }

    public function archivos()
    {
        return $this->morphMany(Archivo::class, 'relacionado');
    }
}
