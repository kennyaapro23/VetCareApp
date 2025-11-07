<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Archivo extends Model
{
    use HasFactory;

    protected $fillable = [
        'relacionado_tipo',
        'relacionado_id',
        'nombre',
        'url',
        'tipo_mime',
        'size',
        'uploaded_by',
    ];

    public function relacionado()
    {
        return $this->morphTo();
    }

    public function uploadedBy()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }
}
