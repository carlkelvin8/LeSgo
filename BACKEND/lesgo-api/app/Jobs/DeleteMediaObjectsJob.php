<?php

namespace App\Jobs;

use App\Services\MediaStorageService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class DeleteMediaObjectsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;

    /** @var list<string> */
    public array $paths;

    /**
     * @param  array<int, string>  $paths
     */
    public function __construct(array $paths)
    {
        $this->paths = array_values(array_unique(array_filter(
            $paths,
            fn ($path) => is_string($path) && trim($path) !== ''
        )));
    }

    public function backoff(): array
    {
        return [10, 60, 300, 900];
    }

    public function handle(): void
    {
        foreach ($this->paths as $path) {
            MediaStorageService::deleteOrFail($path);
        }
    }
}
