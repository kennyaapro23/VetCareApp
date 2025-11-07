<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Mascota extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'nombre',
        'especie',
        'raza',
        'sexo',
        'fecha_nacimiento',
        'color',
        'chip_id',
        'foto_url',
    ];

    protected $casts = [
        'fecha_nacimiento' => 'date',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($model) {
            if (empty($model->public_id)) {
                $model->public_id = (string) Str::uuid();
            }
        });
    }

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function historialMedicos()
    {
        return $this->hasMany(HistorialMedico::class);
    }

    public function citas()
    {
        return $this->hasMany(Cita::class);
    }

    public function archivos()
    {
        return $this->morphMany(Archivo::class, 'relacionado');
    }

    /**
     * Accessor para calcular edad de la mascota
     */
    public function getEdadAttribute()
    {
        if (!$this->fecha_nacimiento) {
            return null;
        }

        $nacimiento = \Carbon\Carbon::parse($this->fecha_nacimiento);
        $ahora = \Carbon\Carbon::now();

        $years = $nacimiento->diffInYears($ahora);
        $months = $nacimiento->copy()->addYears($years)->diffInMonths($ahora);

        if ($years > 0) {
            return $years . ' año' . ($years > 1 ? 's' : '') . 
                   ($months > 0 ? ' y ' . $months . ' mes' . ($months > 1 ? 'es' : '') : '');
        } else {
            return $months . ' mes' . ($months > 1 ? 'es' : '');
        }
    }
}
