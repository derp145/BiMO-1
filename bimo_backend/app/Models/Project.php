<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    protected $table = 'projects';

    public $timestamps = false;
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'title',
        'category',
        'created_at',
        'deleted_at',
        'is_optimized',
        'is_completed',
        'components',
        'audit_log',
        'region',
        'city',
        'barangay',
        'prompt_or_url',
        'author_name',
        'thumbnail_url',
        'build_instructions',
        'created_db_at',
        'updated_at',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'deleted_at' => 'datetime',
        'is_optimized' => 'boolean',
        'is_completed' => 'boolean',
        'components' => 'array',
        'audit_log' => 'array',
        'build_instructions' => 'array',
        'created_db_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}