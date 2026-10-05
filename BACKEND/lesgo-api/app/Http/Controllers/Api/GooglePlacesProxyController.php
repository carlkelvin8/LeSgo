<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * @OA\Tag(
 *     name="Google Places Proxy",
 *     description="Proxy endpoints for Google Places API to avoid CORS issues"
 * )
 */
class GooglePlacesProxyController extends Controller
{
    private string $apiKey;

    public function __construct()
    {
        $this->apiKey = (string) config('services.google_maps.api_key');
    }

    /**
     * @OA\Get(
     *     path="/api/v1/google-places/autocomplete",
     *     summary="Google Places Autocomplete Proxy",
     *     tags={"Google Places Proxy"},
     *
     *     @OA\Parameter(
     *         name="input",
     *         in="query",
     *         required=true,
     *         description="Search query",
     *
     *         @OA\Schema(type="string")
     *     ),
     *
     *     @OA\Response(
     *         response=200,
     *         description="Autocomplete suggestions"
     *     )
     * )
     */
    public function autocomplete(Request $request)
    {
        if ($response = $this->configurationError()) {
            return $response;
        }

        try {
            $validated = $request->validate([
                'input' => ['required', 'string', 'max:200'],
            ]);

            // Call Google Places Autocomplete API
            $response = Http::timeout(10)->get('https://maps.googleapis.com/maps/api/place/autocomplete/json', [
                'input' => $validated['input'],
                'key' => $this->apiKey,
                'components' => 'country:ph', // Restrict to Philippines
                'language' => 'en',
            ]);

            if ($response->successful()) {
                return response()->json($response->json());
            }

            return response()->json([
                'status' => 'ERROR',
                'predictions' => [],
                'error_message' => 'Failed to fetch autocomplete results',
            ], 500);

        } catch (\Throwable $e) {
            Log::error('Google Places autocomplete request failed.', ['error' => $e->getMessage()]);

            return response()->json([
                'status' => 'ERROR',
                'predictions' => [],
                'error_message' => 'Google Places is temporarily unavailable.',
            ], 502);
        }
    }

    /**
     * @OA\Get(
     *     path="/api/v1/google-places/details",
     *     summary="Google Place Details Proxy",
     *     tags={"Google Places Proxy"},
     *
     *     @OA\Parameter(
     *         name="place_id",
     *         in="query",
     *         required=true,
     *         description="Google Place ID",
     *
     *         @OA\Schema(type="string")
     *     ),
     *
     *     @OA\Response(
     *         response=200,
     *         description="Place details"
     *     )
     * )
     */
    public function details(Request $request)
    {
        if ($response = $this->configurationError()) {
            return $response;
        }

        try {
            $validated = $request->validate([
                'place_id' => ['required', 'string', 'max:255'],
            ]);

            // Call Google Place Details API
            $response = Http::timeout(10)->get('https://maps.googleapis.com/maps/api/place/details/json', [
                'place_id' => $validated['place_id'],
                'key' => $this->apiKey,
                'fields' => 'geometry,formatted_address,address_components',
            ]);

            if ($response->successful()) {
                return response()->json($response->json());
            }

            return response()->json([
                'status' => 'ERROR',
                'result' => null,
                'error_message' => 'Failed to fetch place details',
            ], 500);

        } catch (\Throwable $e) {
            Log::error('Google Place details request failed.', ['error' => $e->getMessage()]);

            return response()->json([
                'status' => 'ERROR',
                'result' => null,
                'error_message' => 'Google Places is temporarily unavailable.',
            ], 502);
        }
    }

    /**
     * @OA\Get(
     *     path="/api/v1/google-places/directions",
     *     summary="Google Directions API Proxy",
     *     tags={"Google Places Proxy"},
     *
     *     @OA\Parameter(
     *         name="origin",
     *         in="query",
     *         required=true,
     *         description="Origin coordinates (lat,lng)",
     *
     *         @OA\Schema(type="string")
     *     ),
     *
     *     @OA\Parameter(
     *         name="destination",
     *         in="query",
     *         required=true,
     *         description="Destination coordinates (lat,lng)",
     *
     *         @OA\Schema(type="string")
     *     ),
     *
     *     @OA\Response(
     *         response=200,
     *         description="Route directions"
     *     )
     * )
     */
    public function directions(Request $request)
    {
        if ($response = $this->configurationError()) {
            return $response;
        }

        try {
            $coordinateRule = ['required', 'string', 'max:64', 'regex:/^-?\d{1,2}(?:\.\d+)?,-?\d{1,3}(?:\.\d+)?$/'];
            $validated = $request->validate([
                'origin' => $coordinateRule,
                'destination' => $coordinateRule,
            ]);

            // Call Google Directions API
            $response = Http::timeout(10)->get('https://maps.googleapis.com/maps/api/directions/json', [
                'origin' => $validated['origin'],
                'destination' => $validated['destination'],
                'key' => $this->apiKey,
                'mode' => 'driving', // Can be: driving, walking, bicycling, transit
                'alternatives' => false,
            ]);

            if ($response->successful()) {
                return response()->json($response->json());
            }

            return response()->json([
                'status' => 'ERROR',
                'routes' => [],
                'error_message' => 'Failed to fetch directions',
            ], 500);

        } catch (\Throwable $e) {
            Log::error('Google Directions request failed.', ['error' => $e->getMessage()]);

            return response()->json([
                'status' => 'ERROR',
                'routes' => [],
                'error_message' => 'Google Directions is temporarily unavailable.',
            ], 502);
        }
    }

    private function configurationError(): ?\Illuminate\Http\JsonResponse
    {
        if ($this->apiKey !== '') {
            return null;
        }

        return response()->json([
            'status' => 'ERROR',
            'error_message' => 'Google Maps integration is not configured.',
        ], 503);
    }
}
