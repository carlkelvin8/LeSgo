<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MediaStorageService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ProofImageController extends Controller
{
    /**
     * Serve proof-of-delivery images with CORS headers.
     * Supports object storage (S3/R2) and legacy public disk files.
     */
    public function show(Request $request, $orderId, $filename)
    {
        try {
            $order = \App\Models\Order::findOrFail($orderId);
            $user = $request->user();
            $isCustomer = (int) $order->customer_id === (int) $user->id;
            $isAssignedDriver = $order->driver_id !== null
                && (int) ($user->driverProfile?->id ?? 0) === (int) $order->driver_id;
            $isAdmin = $user->isAdmin();
            $isOrderPartner = ($user->isPartnerAdmin() || $user->isPartnerStaff())
                && (int) ($user->partner?->id ?? 0) === (int) $order->partner_id;
            if (! ($isCustomer || $isAssignedDriver || $isAdmin || $isOrderPartner)) {
                return $this->error('You are not authorized to view these proof images.', 403);
            }
            if (basename($filename) !== $filename || str_contains($filename, '..')) {
                return $this->error('Invalid image path.', 404);
            }

            $path = "proof_images/{$orderId}/{$filename}";

            if (MediaStorageService::isCloudDiskConfigured()
                && MediaStorageService::exists($path)) {
                $publicUrl = MediaStorageService::publicUrl($path);
                if ($publicUrl) {
                    return redirect($publicUrl);
                }

                return $this->streamFromCloudDisk($path);
            }

            if (Storage::disk('public')->exists($path)) {
                $fullPath = Storage::disk('public')->path($path);
                $mimeType = mime_content_type($fullPath) ?: 'image/jpeg';

                $response = response()->file($fullPath, [
                    'Content-Type'                => $mimeType,
                ]);
                $response->headers->set('Cache-Control', 'private, no-store');
                return $response;
            }

            return response()->json([
                'success' => false,
                'message' => 'Image not found',
                'path'    => $path,
            ], 404);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error serving image: ' . $e->getMessage(),
            ], 500);
        }
    }

    private function streamFromCloudDisk(string $path): StreamedResponse
    {
        $disk = MediaStorageService::resolveMediaDisk();
        $relative = MediaStorageService::normalizeStoredPath($path) ?? $path;
        $mimeType = Storage::disk($disk)->mimeType($relative) ?: 'image/jpeg';

        return response()->stream(function () use ($disk, $relative) {
            $stream = Storage::disk($disk)->readStream($relative);
            if ($stream) {
                fpassthru($stream);
                if (is_resource($stream)) {
                    fclose($stream);
                }
            }
        }, 200, [
            'Content-Type'                 => $mimeType,
            'Cache-Control'                => 'private, no-store',
        ]);
    }
}
