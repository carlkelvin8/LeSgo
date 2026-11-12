<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePartnerBranchRequest;
use App\Http\Requests\UpdatePartnerBranchRequest;
use App\Models\Partner;
use App\Models\PartnerBranch;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class PartnerBranchController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/v1/partners/{partnerId}/branches",
     *     summary="List branches for a partner",
     *     tags={"Partner Branches"},
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="partnerId", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="List of branches",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/PartnerBranch"))
     *         )
     *     ),
     *     @OA\Response(response=404, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function index(int $partnerId): JsonResponse
    {
        $partner = Partner::findOrFail($partnerId);

        return $this->success(
            $partner->branches()->orderByDesc('is_primary')->orderBy('name')->get()
        );
    }

    /**
     * @OA\Post(
     *     path="/api/v1/partners/{partnerId}/branches",
     *     summary="Create a branch for a partner",
     *     tags={"Partner Branches"},
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="partnerId", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\RequestBody(required=true, @OA\JsonContent(required={"name"},
     *         @OA\Property(property="name", type="string", example="Makati Branch"),
     *         @OA\Property(property="address", type="string"),
     *         @OA\Property(property="latitude", type="number", format="float"),
     *         @OA\Property(property="longitude", type="number", format="float")
     *     )),
     *     @OA\Response(response=201, description="Branch created",
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/PartnerBranch"))
     *     ),
     *     @OA\Response(response=422, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function store(StorePartnerBranchRequest $request, int $partnerId): JsonResponse
    {
        $partner = Partner::findOrFail($partnerId);
        $this->authorize('update', $partner);

        $branch = DB::transaction(function () use ($partner, $request) {
            $data = $request->validated();
            // The first branch is always the primary one.
            $data['is_primary'] = ($data['is_primary'] ?? false) || ! $partner->branches()->exists();
            $branch = $partner->branches()->create($data);
            if ($branch->is_primary) {
                $this->demoteOtherPrimaries($branch);
            }

            return $branch;
        });

        return $this->created($branch->fresh(), 'Branch created successfully');
    }

    /**
     * @OA\Patch(
     *     path="/api/v1/branches/{id}",
     *     summary="Update a branch",
     *     tags={"Partner Branches"},
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\RequestBody(required=true, @OA\JsonContent(
     *         @OA\Property(property="name", type="string"),
     *         @OA\Property(property="address", type="string")
     *     )),
     *     @OA\Response(response=200, description="Branch updated",
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/PartnerBranch"))
     *     ),
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse"),
     *     @OA\Response(response=404, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function update(UpdatePartnerBranchRequest $request, PartnerBranch $branch): JsonResponse
    {
        $this->authorize('update', $branch->partner);

        $data = $request->validated();
        if (array_key_exists('is_primary', $data) && ! $data['is_primary'] && $branch->is_primary) {
            return $this->error('Choose another branch as primary instead of unsetting this one.', 422);
        }

        DB::transaction(function () use ($branch, $data) {
            $branch->update($data);
            if ($branch->is_primary) {
                $this->demoteOtherPrimaries($branch);
            }
        });

        return $this->success($branch->fresh(), 'Branch updated successfully');
    }

    /**
     * @OA\Delete(
     *     path="/api/v1/branches/{id}",
     *     summary="Delete a branch",
     *     tags={"Partner Branches"},
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="Branch deleted",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Branch deleted successfully")
     *         )
     *     ),
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse"),
     *     @OA\Response(response=404, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function destroy(PartnerBranch $branch): JsonResponse
    {
        $partner = $branch->partner;
        $this->authorize('update', $partner);

        if ($partner->branches()->count() <= 1) {
            return $this->error('A store needs at least one branch. Edit this branch instead.', 422);
        }

        $hasActiveOrders = $branch->orders()
            ->whereNotIn('status', ['completed', 'cancelled', 'rejected', 'failed'])
            ->exists();
        if ($hasActiveOrders) {
            return $this->error('This branch still has active orders. Finish them before deleting it.', 422);
        }

        DB::transaction(function () use ($branch, $partner) {
            $wasPrimary = $branch->is_primary;
            $branch->delete();
            if ($wasPrimary) {
                $partner->branches()->orderBy('id')->first()?->update(['is_primary' => true]);
            }
        });

        return $this->message('Branch deleted successfully');
    }

    private function demoteOtherPrimaries(PartnerBranch $branch): void
    {
        PartnerBranch::query()
            ->where('partner_id', $branch->partner_id)
            ->whereKeyNot($branch->id)
            ->where('is_primary', true)
            ->update(['is_primary' => false]);
    }
}
