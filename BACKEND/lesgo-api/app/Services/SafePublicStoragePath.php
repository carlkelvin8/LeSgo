<?php

namespace App\Services;

class SafePublicStoragePath
{
    public static function normalizeKey(string $path): ?string
    {
        $path = rawurldecode($path);
        if (str_contains($path, "\0") || str_contains($path, '\\')) {
            return null;
        }

        $segments = explode('/', $path);
        if ($segments === [] || collect($segments)->contains(
            static fn (string $segment): bool => $segment === '' || $segment === '.' || $segment === '..'
        )) {
            return null;
        }

        return implode('/', $segments);
    }

    public static function resolveLocalFile(string $key): ?string
    {
        $root = realpath(storage_path('app/public'));
        if ($root === false) {
            return null;
        }

        $candidate = realpath($root.DIRECTORY_SEPARATOR.str_replace('/', DIRECTORY_SEPARATOR, $key));
        if ($candidate === false || !is_file($candidate)) {
            return null;
        }

        $prefix = rtrim($root, DIRECTORY_SEPARATOR).DIRECTORY_SEPARATOR;
        $normalizedCandidate = DIRECTORY_SEPARATOR === '\\'
            ? strtolower($candidate)
            : $candidate;
        $normalizedPrefix = DIRECTORY_SEPARATOR === '\\'
            ? strtolower($prefix)
            : $prefix;

        return str_starts_with($normalizedCandidate, $normalizedPrefix) ? $candidate : null;
    }
}
