<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('projects', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('title');
            $table->string('category')->default('engineering');
            $table->dateTime('created_at')->nullable();
            $table->dateTime('deleted_at')->nullable();
            $table->boolean('is_optimized')->default(true);
            $table->boolean('is_completed')->default(false);
            $table->json('components')->nullable();
            $table->json('audit_log')->nullable();
            $table->string('region')->nullable();
            $table->string('city')->nullable();
            $table->string('barangay')->nullable();
            $table->text('prompt_or_url')->nullable();
            $table->string('author_name')->nullable();
            $table->string('thumbnail_url')->nullable();
            $table->json('build_instructions')->nullable();
            $table->dateTime('created_db_at')->useCurrent();
            $table->dateTime('updated_at')->useCurrent()->useCurrentOnUpdate();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('projects');
    }
};
