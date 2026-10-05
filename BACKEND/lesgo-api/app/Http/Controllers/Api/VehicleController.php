<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VehicleController extends Controller
{
    /**
     * GET /api/v1/drivers/vehicles - List current driver's vehicles
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $driverProfile = $user->driverProfile;

        if (!$driverProfile) {
            return $this->success([]);
        }

        $vehicles = Vehicle::where('driver_id', $driverProfile->id)
            ->orderByDesc('is_primary')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn($v) => $this->formatVehicle($v));

        return $this->success($vehicles);
    }

    /**
     * POST /api/v1/drivers/vehicles - Add a new vehicle
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $driverProfile = $user->driverProfile;

        if (!$driverProfile) {
            return $this->error('Driver profile not found', 404);
        }

        $validated = $request->validate([
            'vehicle_type' => ['required', 'string', 'in:motorcycle,bicycle,car,scooter'],
            'plate_number' => ['required', 'string', 'max:20'],
            'make_model'   => ['required', 'string', 'max:200'],
            'color'        => ['nullable', 'string', 'max:50'],
            'is_default'   => ['nullable', 'boolean'],
        ]);

        // Parse make_model into brand and model
        $parts = $this->parseMakeModel($validated['make_model']);

        $isDefault = $validated['is_default'] ?? false;

        // If this is the first vehicle or is_default, unset other defaults
        $existingCount = Vehicle::where('driver_id', $driverProfile->id)->count();
        if ($isDefault || $existingCount === 0) {
            Vehicle::where('driver_id', $driverProfile->id)
                ->update(['is_primary' => false]);
            $isDefault = true;
        }

        $vehicle = Vehicle::create([
            'driver_id'    => $driverProfile->id,
            'partner_id'   => $driverProfile->partner_id,
            'type'         => $validated['vehicle_type'],
            'plate_number' => $validated['plate_number'],
            'brand'        => $parts['brand'],
            'model'        => $parts['model'],
            'color'        => $validated['color'] ?? null,
            'is_primary'   => $isDefault,
            'status'       => 'active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle added successfully',
            'data'    => $this->formatVehicle($vehicle),
        ], 201);
    }

    /**
     * PUT /api/v1/drivers/vehicles/{id} - Update a vehicle
     */
    public function update(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $driverProfile = $user->driverProfile;

        if (!$driverProfile) {
            return $this->error('Driver profile not found', 404);
        }

        $vehicle = Vehicle::where('id', $id)
            ->where('driver_id', $driverProfile->id)
            ->first();

        if (!$vehicle) {
            return $this->error('Vehicle not found', 404);
        }

        $validated = $request->validate([
            'vehicle_type' => ['nullable', 'string', 'in:motorcycle,bicycle,car,scooter'],
            'plate_number' => ['nullable', 'string', 'max:20'],
            'make_model'   => ['nullable', 'string', 'max:200'],
            'color'        => ['nullable', 'string', 'max:50'],
            'is_default'   => ['nullable', 'boolean'],
        ]);

        if (isset($validated['vehicle_type'])) {
            $vehicle->type = $validated['vehicle_type'];
        }
        if (isset($validated['plate_number'])) {
            $vehicle->plate_number = $validated['plate_number'];
        }
        if (isset($validated['make_model'])) {
            $parts = $this->parseMakeModel($validated['make_model']);
            $vehicle->brand = $parts['brand'];
            $vehicle->model = $parts['model'];
        }
        if (isset($validated['color'])) {
            $vehicle->color = $validated['color'];
        }
        if (isset($validated['is_default']) && $validated['is_default']) {
            Vehicle::where('driver_id', $driverProfile->id)
                ->where('id', '!=', $vehicle->id)
                ->update(['is_primary' => false]);
            $vehicle->is_primary = true;
        }

        $vehicle->save();

        return $this->success($this->formatVehicle($vehicle), 'Vehicle updated successfully');
    }

    /**
     * DELETE /api/v1/drivers/vehicles/{id} - Remove a vehicle
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $driverProfile = $user->driverProfile;

        if (!$driverProfile) {
            return $this->error('Driver profile not found', 404);
        }

        $vehicle = Vehicle::where('id', $id)
            ->where('driver_id', $driverProfile->id)
            ->first();

        if (!$vehicle) {
            return $this->error('Vehicle not found', 404);
        }

        $wasPrimary = $vehicle->is_primary;
        $vehicle->delete();

        // If deleted vehicle was primary, set another as primary
        if ($wasPrimary) {
            $next = Vehicle::where('driver_id', $driverProfile->id)->first();
            if ($next) {
                $next->update(['is_primary' => true]);
            }
        }

        return $this->success(null, 'Vehicle removed successfully');
    }

    /**
     * Format vehicle for API response (matches frontend expectations)
     */
    private function formatVehicle(Vehicle $vehicle): array
    {
        $makeModel = trim(($vehicle->brand ?? '') . ' ' . ($vehicle->model ?? ''));

        return [
            'id'           => $vehicle->id,
            'vehicle_type' => $vehicle->type ?? 'motorcycle',
            'plate_number' => $vehicle->plate_number ?? '',
            'make_model'   => $makeModel ?: 'Unknown',
            'color'        => $vehicle->color ?? '',
            'is_default'   => (bool) $vehicle->is_primary,
            'created_at'   => $vehicle->created_at?->toISOString(),
            'updated_at'   => $vehicle->updated_at?->toISOString(),
        ];
    }

    /**
     * Parse "Honda Beat" into brand="Honda", model="Beat"
     */
    private function parseMakeModel(string $makeModel): array
    {
        $parts = explode(' ', trim($makeModel), 2);
        return [
            'brand' => $parts[0] ?? '',
            'model' => $parts[1] ?? '',
        ];
    }
}
