<?php

namespace App\Http\Controllers\Api;

use App\Models\DocumentVerification;
use App\Http\Controllers\Controller;
use App\Services\MediaStorageService;
use App\Services\RegistrationDocumentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DocumentSubmissionController extends Controller
{
    /**
     * Complete identity onboarding for an authenticated Google customer.
     */
    public function submitIdentityOnboarding(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'selfie' => ['required', 'file', 'mimes:jpeg,jpg,png', 'max:10240'],
            'id_type' => ['required', 'string', 'in:philippine_national_id,drivers_license,passport,umid,sss_id,postal_id,voters_id,prc_id'],
            'id_number' => ['required', 'string', 'max:100'],
            'valid_id_front' => ['required', 'file', 'mimes:jpeg,jpg,png', 'max:10240'],
            'valid_id_back' => ['required', 'file', 'mimes:jpeg,jpg,png', 'max:10240'],
        ]);

        $user = $request->user();
        if (!$user?->isCustomer()) {
            return $this->error('Identity onboarding is only available for customer accounts.', 403);
        }

        $existing = DocumentVerification::query()
            ->where('user_id', $user->id)
            ->where('document_type', 'valid_id')
            ->whereIn('status', ['pending', 'under_review', 'approved'])
            ->first();

        if ($existing) {
            return $this->success($existing, 'Identity verification was already submitted.');
        }

        $paths = [];
        try {
            $paths = RegistrationDocumentService::storeCustomerDocuments($request);

            $document = DB::transaction(function () use ($user, $validated, $paths) {
                $user->update(['profile_picture' => $paths['selfie_path']]);

                return DocumentVerification::create([
                    'user_id' => $user->id,
                    'document_type' => 'valid_id',
                    'document_number' => $validated['id_number'],
                    'document_urls' => [
                        MediaStorageService::publicUrl($paths['valid_id_front_path']),
                        MediaStorageService::publicUrl($paths['valid_id_back_path']),
                    ],
                    'description' => 'Submitted during Google account onboarding.',
                    'status' => 'pending',
                    'submitted_at' => now(),
                    'metadata' => [
                        'id_type' => $validated['id_type'],
                        'selfie_url' => MediaStorageService::publicUrl($paths['selfie_path']),
                        'capture_method' => 'camera',
                        'registration_submission' => true,
                    ],
                    'verification_attempts' => 0,
                ]);
            });
        } catch (\Throwable $e) {
            RegistrationDocumentService::discardDocuments($paths);
            \Log::error('Customer identity onboarding failed', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return $this->error('Failed to submit identity verification. Please try again.', 500);
        }

        return $this->created($document, 'Identity verification submitted successfully.');
    }

    /**
     * Submit a document for verification.
     */
    public function submit(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'document_type' => 'required|in:drivers_license,vehicle_registration,insurance,barangay_clearance,ncr_clearance',
            'document_number' => 'required|string|max:100',
            'document_urls' => 'required|array|min:1',
            'document_urls.*' => 'required|url',
            'description' => 'nullable|string|max:1000',
            'expiry_date' => 'nullable|date|after:today',
            'metadata' => 'nullable|array',
        ]);

        $user = $request->user();

        // Check if user already has this document type pending or approved
        $existingDoc = DocumentVerification::where('user_id', $user->id)
            ->where('document_type', $validated['document_type'])
            ->whereIn('status', ['pending', 'approved', 'under_review'])
            ->first();

        if ($existingDoc) {
            return $this->error(
                "You already have a {$validated['document_type']} document that is pending or approved.",
                409
            );
        }

        $document = DocumentVerification::create([
            'user_id' => $user->id,
            'document_type' => $validated['document_type'],
            'document_number' => $validated['document_number'],
            'document_urls' => $validated['document_urls'],
            'description' => $validated['description'] ?? null,
            'status' => 'pending',
            'submitted_at' => now(),
            'expires_at' => $validated['expiry_date'] ?? null,
            'metadata' => $validated['metadata'] ?? null,
            'verification_attempts' => 0,
        ]);

        $document->load('user:id,name,email');

        return $this->created($document, 'Document submitted successfully');
    }

    /**
     * Get current user's documents.
     */
    public function myDocuments(Request $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'status' => 'nullable|in:pending,approved,rejected,expired,under_review',
            'document_type' => 'nullable|string',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = DocumentVerification::where('user_id', $user->id)
            ->orderByDesc('submitted_at');

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        if (!empty($validated['document_type'])) {
            $query->where('document_type', $validated['document_type']);
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $documents = $query->paginate($perPage);

        return $this->success($documents, 'Documents retrieved successfully');
    }

    /**
     * Get available document types.
     */
    public function documentTypes(): JsonResponse
    {
        return $this->success([
            [
                'type' => 'drivers_license',
                'label' => "Driver's License",
                'description' => 'Valid professional driver\'s license',
                'required' => true,
                'accepts_expiry_date' => true,
                'notes' => 'Must be currently valid and not expired',
            ],
            [
                'type' => 'vehicle_registration',
                'label' => 'Vehicle Registration (OR/CR)',
                'description' => 'Official Receipt and Certificate of Registration for vehicle',
                'required' => true,
                'accepts_expiry_date' => true,
                'notes' => 'Must be registered under applicant\'s name',
            ],
            [
                'type' => 'insurance',
                'label' => 'Vehicle Insurance',
                'description' => 'Comprehensive vehicle insurance certificate',
                'required' => false,
                'accepts_expiry_date' => true,
                'notes' => 'Optional but recommended',
            ],
            [
                'type' => 'barangay_clearance',
                'label' => 'Barangay Clearance',
                'description' => 'Barangay clearance certificate',
                'required' => false,
                'accepts_expiry_date' => false,
                'notes' => 'Optional document',
            ],
            [
                'type' => 'ncr_clearance',
                'label' => 'NCR Clearance',
                'description' => 'National Capital Region clearance (if applicable)',
                'required' => false,
                'accepts_expiry_date' => true,
                'notes' => 'Only required for NCR operations',
            ],
        ], 'Document types retrieved successfully');
    }

    /**
     * Get verification status for all user's documents.
     */
    public function verificationStatus(Request $request): JsonResponse
    {
        $user = $request->user();

        $documents = DocumentVerification::where('user_id', $user->id)
            ->whereIn('status', ['pending', 'approved', 'rejected', 'under_review'])
            ->get();

        $verifiedCount = $documents->where('status', 'approved')->count();
        $totalCount = $documents->count();
        $pendingCount = $documents->where('status', 'pending')->count();
        $rejectedCount = $documents->where('status', 'rejected')->count();

        // Determine overall status
        if ($rejectedCount > 0) {
            $overallStatus = 'action_required';
        } elseif ($pendingCount > 0) {
            $overallStatus = 'pending';
        } elseif ($verifiedCount > 0) {
            $overallStatus = 'verified';
        } else {
            $overallStatus = 'not_started';
        }

        return $this->success([
            'overall_status' => $overallStatus,
            'verified_documents' => $verifiedCount,
            'pending_documents' => $pendingCount,
            'rejected_documents' => $rejectedCount,
            'total_documents' => $totalCount,
            'documents' => $documents->map(function ($doc) {
                return [
                    'id' => $doc->id,
                    'document_type' => $doc->document_type,
                    'status' => $doc->status,
                    'submitted_at' => $doc->submitted_at?->toISOString(),
                    'reviewed_at' => $doc->reviewed_at?->toISOString(),
                    'rejection_reason' => $doc->rejection_reason,
                    'expires_at' => $doc->expires_at?->toISOString(),
                ];
            }),
        ], 'Verification status retrieved successfully');
    }

    /**
     * Get document details.
     */
    public function show(Request $request, $documentId): JsonResponse
    {
        $user = $request->user();

        $document = DocumentVerification::where('user_id', $user->id)
            ->find($documentId);

        if (!$document) {
            return $this->error('Document not found.', 404);
        }

        return $this->success($document, 'Document details retrieved successfully');
    }

    /**
     * Resubmit a rejected document.
     */
    public function resubmit(Request $request, $documentId): JsonResponse
    {
        $user = $request->user();

        $document = DocumentVerification::where('user_id', $user->id)
            ->find($documentId);

        if (!$document) {
            return $this->error('Document not found.', 404);
        }

        if ($document->status !== 'rejected') {
            return $this->error('Can only resubmit rejected documents.', 400);
        }

        $validated = $request->validate([
            'document_urls' => 'nullable|array|min:1',
            'document_urls.*' => 'required|url',
            'description' => 'nullable|string|max:1000',
            'metadata' => 'nullable|array',
        ]);

        $updateData = [
            'status' => 'pending',
            'rejection_reason' => null,
            'admin_notes' => null,
            'submitted_at' => now(),
            'reviewed_at' => null,
            'verification_attempts' => $document->verification_attempts + 1,
            'last_attempt_at' => now(),
        ];

        if (!empty($validated['document_urls'])) {
            $updateData['document_urls'] = $validated['document_urls'];
        }

        if (isset($validated['description'])) {
            $updateData['description'] = $validated['description'];
        }

        if (isset($validated['metadata'])) {
            $updateData['metadata'] = $validated['metadata'];
        }

        $document->update($updateData);

        return $this->success($document, 'Document resubmitted successfully');
    }
}
