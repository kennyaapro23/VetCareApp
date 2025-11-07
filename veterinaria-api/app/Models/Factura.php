<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Factura extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'cita_id',
        'total',
        'estado',
        'metodo_pago',
        'detalles',
    ];

    protected $casts = [
        'total' => 'decimal:2',
        'detalles' => 'array',
    ];

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function cita()
    {
        return $this->belongsTo(Cita::class);
    }
}
