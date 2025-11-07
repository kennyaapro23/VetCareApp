<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FcmToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'token',
        'plataforma',
        'ultimo_registro',
    ];

    protected $casts = [
        'ultimo_registro' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
