<?php

namespace App\Http\Controllers\Api;

use App\Events\OrderDriverAssigned;
use App\Http\Controllers\Controller;
use App\Http\Requests\FilterOrderRequest;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Requests\UpdateOrderStatusRequest;
use App\Jobs\NotifyDriverAssignedJob;
use App\Jobs\SendOrderConfirmationJob;
use App\Jobs\SendRatingReminderJob;
use App\Models\Address;
use App\Models\Order;
use App\Models\MenuItem;
use App\Models\Partner;
use App\Models\Service;
use App\Services\FareCalculatorService;
use App\Services\MediaStorageService;
use App\Services\MenuItemOptionsHelper;
use App\Services\OrderCancellationService;
use App\Services\OrderDriverWalletService;
use App\Services\OrderWalletPaymentService;
use App\Services\RealtimeService;
use App\Services\RiderCommissionService;
use App\Services\VoucherService;
use App\Services\WalletService;
use App\Services\WalletValidationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function __construct(
        private RealtimeService $realtimeService,
        private FareCalculatorService $fareCalculator
    ) {}

    /**
     * @OA\Get(
     *     path="/api/v1/orders",
     *     summary="List orders (scoped by role)",
     *     tags={"Orders"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Parameter(name="status", in="query", required=false, @OA\Schema(type="string", enum={"pending","searching_driver","accepted","picked_up","completed","cancelled"})),
     *     @OA\Parameter(name="payment_status", in="query", required=false, @OA\Schema(type="string", enum={"pending","paid","failed"})),
     *     @OA\Parameter(name="service_id", in="query", required=false, @OA\Schema(type="integer")),
     *     @OA\Parameter(name="per_page", in="query", required=false, @OA\Schema(type="integer", example=20)),
     *
     *     @OA\Response(response=200, description="Paginated orders",
     *
     *         @OA\JsonContent(
     *
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Order")),
     *             @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta"),
     *             @OA\Property(property="links", ref="#/components/schemas/PaginationLinks")
     *         )
     *     ),
     *
     *     @OA\Response(response=401, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function index(FilterOrderRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();

        \Log::info('OrderController@index called', [
            'user_id' => $user->id,
            'user_role' => $user->role,
            'filters' => $validated,
        ]);

        $query = $this->scopedOrdersQuery($user)->with([
            'customer:id,name,email,phone_number,profile_picture,profile_photo_url',
            'partner:id,name',
            'driverProfile:id,user_id,status,rating,plate_number,vehicle_type',
            'driverProfile.user:id,name,email,phone_number,profile_picture,profile_photo_url',
            'service:id,name,code,icon_url',
            'lesbuyItems:id,order_id,menu_item_id,name,quantity,unit,notes,selected_options,estimated_price,actual_price,image_url',
        ]);

        if (! empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        if (! empty($validated['payment_status'])) {
            $query->where('payment_status', $validated['payment_status']);
        }

        if (! empty($validated['service_id'])) {
            $query->where('service_id', (int) $validated['service_id']);
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $paginator = $query->orderByDesc('id')->paginate($perPage);

        \Log::info('OrderController@index result', [
            'user_id' => $user->id,
            'total_orders' => $paginator->total(),
            'returned_orders' => $paginator->count(),
            'order_ids' => $paginator->pluck('id')->toArray(),
        ]);

        return $this->success($paginator);
    }

    /**
     * @OA\Post(
     *     path="/api/v1/orders",
     *     summary="Create a new order",
     *     tags={"Orders"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\RequestBody(required=true,
     *
     *         @OA\JsonContent(required={"service_id","pickup","dropoff","estimated_distance_m"},
     *
     *             @OA\Property(property="service_id", type="integer", example=1),
     *             @OA\Property(property="pickup", type="object",
     *                 @OA\Property(property="address", type="string", example="123 Rizal St"),
     *                 @OA\Property(property="lat", type="number", example=14.5995),
     *                 @OA\Property(property="lng", type="number", example=120.9842)
     *             ),
     *             @OA\Property(property="dropoff", type="object",
     *                 @OA\Property(property="address", type="string", example="456 Mabini Ave"),
     *                 @OA\Property(property="lat", type="number", example=14.6090),
     *                 @OA\Property(property="lng", type="number", example=121.0000)
     *             ),
     *             @OA\Property(property="estimated_distance_m", type="integer", example=5200),
     *             @OA\Property(property="payment_method", type="string", enum={"cash","gcash","maya","card","wallet","xendit"}, example="cash"),
     *             @OA\Property(property="save_addresses", type="boolean", example=false),
     *             @OA\Property(property="scheduled_at", type="string", format="date-time", nullable=true)
     *         )
     *     ),
     *
     *     @OA\Response(response=201, description="Order created",
     *
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/Order"))
     *     ),
     *
     *     @OA\Response(response=422, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function store(StoreOrderRequest $request, VoucherService $voucherService): JsonResponse
    {
        $data = $request->validated();
        $user = $request->user();
        $service = Service::findOrFail($data['service_id']);

        if (! $service->is_active) {
            return $this->error('This service is currently unavailable.', 422);
        }

        // Block orders to closed stores
        if (! empty($data['partner_id'])) {
            $partner = Partner::find($data['partner_id']);
            if ($partner && ! $partner->is_open) {
                return $this->error('This store is currently closed and not accepting orders.', 422);
            }
        }

        $serviceCode = strtoupper((string) ($service->code ?? 'LESGO'));

        if ($serviceCode === 'LESRIDE' && ($data['vehicle_type'] ?? null) !== 'tricycle') {
            return $this->error('Only the Tricycle option is currently available for LesRide.', 422);
        }

        if ($serviceCode !== 'LESRIDE' && ($data['vehicle_type'] ?? null) === 'tricycle') {
            return $this->error('The Tricycle option is only available for LesRide.', 422);
        }

        // Auto-calculate distance fallback for Manual Orders (LesBuy/LesEat) when
        // client sends 0/null — mirrors OrderEstimateController fallback.
        // Fixes: "The estimated distance m field must be at least 1."
        $straightLineDistanceM = $this->calculateHaversineDistance(
            (float) $data['pickup']['lat'],
            (float) $data['pickup']['lng'],
            (float) $data['dropoff']['lat'],
            (float) $data['dropoff']['lng']
        );

        if (empty($data['estimated_distance_m']) || $data['estimated_distance_m'] < 1) {
            $data['estimated_distance_m'] = (int) round($straightLineDistanceM);
        }

        // Clamp to valid range — same as OrderEstimateController: max(500, min(distance, 30000))
        // but respect LesRide 30km vs others 25km? Keep 30km limit consistent with StoreOrderRequest max.
        $maxDistanceM = $serviceCode === 'LESRIDE' ? 30000 : 30000;
        $data['estimated_distance_m'] = max(500, min((int) $data['estimated_distance_m'], $maxDistanceM));

        if ($serviceCode === 'LESRIDE') {
            if ($straightLineDistanceM < 10) {
                return $this->error('Pickup and destination must be different.', 422);
            }

            if ($straightLineDistanceM > $data['estimated_distance_m'] + 250) {
                return $this->error('The route distance does not match the selected locations.', 422);
            }
        }

        $data['items'] = $data['items'] ?? [];
        $itemSubtotal = 0.0;
        if ($serviceCode === 'LESEAT') {
            if (empty($data['items']) || empty($data['partner_id'])) {
                return $this->error('A restaurant and at least one menu item are required.', 422);
            }
            foreach ($data['items'] as &$item) {
                $menuItem = MenuItem::query()
                    ->whereKey($item['menu_item_id'] ?? 0)
                    ->where('partner_id', $data['partner_id'])
                    ->where('is_available', true)
                    ->first();
                if (!$menuItem) {
                    return $this->error('A menu item is no longer available. Refresh the cart and try again.', 422);
                }
                $canonicalOptions = $this->resolveCanonicalMenuOptions(
                    $menuItem->options ?? [],
                    $item['selected_options'] ?? [],
                );
                if ($canonicalOptions === null) {
                    return $this->error('A selected menu option is no longer available. Refresh the cart and try again.', 422);
                }
                $unitPrice = MenuItemOptionsHelper::calculateUnitPrice(
                    (float) $menuItem->price,
                    $canonicalOptions,
                );
                $clientPrice = (float) ($item['estimated_price'] ?? -1);
                if ($clientPrice < 0 || abs(round($clientPrice, 2) - $unitPrice) > 0.01) {
                    return $this->error('A menu price has changed. Refresh the cart before ordering.', 409);
                }
                $item['estimated_price'] = $unitPrice;
                $item['selected_options'] = $canonicalOptions;
                $itemSubtotal += $unitPrice * (int) $item['quantity'];
            }
            unset($item);
        } else {
            foreach ($data['items'] as $item) {
                $price = (float) ($item['estimated_price'] ?? 0);
                $quantity = (int) ($item['quantity'] ?? 0);
                if (!is_finite($price) || $price < 0 || $quantity < 1) {
                    return $this->error('Order item amounts are invalid.', 422);
                }
                $itemSubtotal += $price * $quantity;
            }
        }
        $itemSubtotal = round($itemSubtotal, 2);

        $distanceKm = $data['estimated_distance_m'] / 1000;
        $allowedMetaKeys = [
            'special_instructions', 'manual_assignment',
            'restaurant_name', 'restaurants', 'order_type',
            'items', 'vehicle_type', 'passenger_name', 'distance_km',
            'duration_seconds', 'item_description', 'item_weight',
        ];
        $meta = array_intersect_key($request->input('meta') ?? [], array_flip($allowedMetaKeys));
        if ($serviceCode === 'LESRIDE') {
            $meta['vehicle_type'] = 'tricycle';
            $meta['passenger_name'] = $data['passenger_name'] ?? $user->name;
        }
        // Prices and fee thresholds are computed from validated order inputs;
        // never let request metadata choose a payable amount or fee bracket.
        $orderValue = in_array($serviceCode, ['LESBUY', 'LESEAT'], true) ? $itemSubtotal : 0.0;
        $weightKg = (float) ($data['estimated_weight_kg'] ?? 0);
        $fareBreakdown = $this->fareCalculator->calculate(
            $service,
            $distanceKm,
            $orderValue,
            $weightKg
        );
        $meta['subtotal'] = $itemSubtotal;
        $meta['delivery_fee'] = (float) $fareBreakdown['total'];
        $meta['discount'] = 0.0;
        $meta['grand_total'] = round($itemSubtotal + (float) $fareBreakdown['total'], 2);
        $meta['total'] = $meta['grand_total'];
        $meta['items'] = array_map(static fn (array $item): array => [
            'name' => $item['name'],
            'estimated_price' => (float) ($item['estimated_price'] ?? 0),
            'quantity' => (int) $item['quantity'],
        ], $data['items']);
        $saveAddresses = (bool) ($data['save_addresses'] ?? false);

        try {
            $order = DB::transaction(function () use ($user, $data, $fareBreakdown, $meta, $saveAddresses, $voucherService) {
                $pickupAddressId = null;
                $dropoffAddressId = null;

                if ($saveAddresses) {
                    $pickupAddress = Address::create([
                        'user_id' => $user->id,
                        'label' => $data['pickup_label'] ?? 'Pickup',
                        'contact_name' => $data['pickup']['contact_name'] ?? $user->name,
                        'contact_phone' => $data['pickup']['contact_phone'] ?? $user->phone_number,
                        'address_line1' => $data['pickup']['address'],
                        'country' => 'PH',
                        'latitude' => $data['pickup']['lat'],
                        'longitude' => $data['pickup']['lng'],
                        'is_default' => false,
                    ]);

                    $dropoffAddress = Address::create([
                        'user_id' => $user->id,
                        'label' => $data['dropoff_label'] ?? 'Dropoff',
                        'contact_name' => $data['dropoff']['contact_name'] ?? $user->name,
                        'contact_phone' => $data['dropoff']['contact_phone'] ?? $user->phone_number,
                        'address_line1' => $data['dropoff']['address'],
                        'country' => 'PH',
                        'latitude' => $data['dropoff']['lat'],
                        'longitude' => $data['dropoff']['lng'],
                        'is_default' => false,
                    ]);

                    $pickupAddressId = $pickupAddress->id;
                    $dropoffAddressId = $dropoffAddress->id;
                }

                $order = Order::create([
                    'customer_id' => $user->id,
                    'partner_id' => $data['partner_id'] ?? null,
                    'driver_id' => null,
                    'service_id' => $data['service_id'],
                    'pickup_address_id' => $pickupAddressId,
                    'dropoff_address_id' => $dropoffAddressId,
                    'pickup_address' => $data['pickup']['address'],
                    'pickup_lat' => $data['pickup']['lat'],
                    'pickup_lng' => $data['pickup']['lng'],
                    'pickup_contact_name' => $data['pickup']['contact_name'] ?? $user->name,
                    'pickup_contact_phone' => $data['pickup']['contact_phone'] ?? $user->phone_number,
                    'dropoff_address' => $data['dropoff']['address'],
                    'dropoff_lat' => $data['dropoff']['lat'],
                    'dropoff_lng' => $data['dropoff']['lng'],
                    'dropoff_contact_name' => $data['dropoff']['contact_name'] ?? $user->name,
                    'dropoff_contact_phone' => $data['dropoff']['contact_phone'] ?? $user->phone_number,
                    'notes' => $data['notes'] ?? null,
                    'item_description' => $data['item_description'] ?? null,
                    'estimated_weight_kg' => $data['estimated_weight_kg'] ?? null,
                    'vehicle_type' => $data['vehicle_type'] ?? null,
                    'passenger_name' => $data['passenger_name'] ?? $user->name,
                    'voucher_code' => $data['voucher_code'] ?? null,
                    'discount_amount' => 0,
                    'status' => 'pending',
                    'scheduled_at' => $data['scheduled_at'] ?? null,
                    'scheduled_delivery_time' => $data['scheduled_delivery_time'] ?? null,
                    'estimated_distance_m' => $data['estimated_distance_m'],
                    'estimated_fare' => $fareBreakdown['total'],
                    'fare_breakdown' => $fareBreakdown,
                    'payment_method' => $data['payment_method'] ?? 'cash',
                    'payment_status' => 'pending',
                    'meta' => $meta ?: null,
                ]);

                if (! empty($data['items'])) {
                    foreach ($data['items'] as $item) {
                        $selectedOptions = $item['selected_options'] ?? null;
                        $formattedNotes = ! empty($item['notes'])
                            ? $item['notes']
                            : MenuItemOptionsHelper::formatSelectedOptions(
                                is_array($selectedOptions) ? $selectedOptions : null
                            );

                        $order->lesbuyItems()->create([
                            'menu_item_id' => $item['menu_item_id'] ?? null,
                            'name' => $item['name'],
                            'quantity' => $item['quantity'],
                            'unit' => $item['unit'] ?? null,
                            'notes' => $formattedNotes,
                            'selected_options' => is_array($selectedOptions) ? $selectedOptions : null,
                            'image_url' => $item['image_url'] ?? null,
                            'estimated_price' => $item['estimated_price'] ?? null,
                            'is_checklist_item' => $item['is_checklist_item'] ?? false,
                            'status' => 'pending',
                        ]);
                    }
                }

                if (! empty($data['voucher_code'])) {
                    $voucherResult = $voucherService->applyVoucher($order, $data['voucher_code']);
                    if (! $voucherResult['valid']) {
                        throw new \RuntimeException($voucherResult['error']);
                    }
                    $order->refresh();
                }

                if (($order->payment_method ?? 'cash') === 'wallet') {
                    OrderWalletPaymentService::payWithWallet($order);
                    $order->refresh();
                }

                // Handle scheduled orders - set status to 'scheduled' if delivery time is in future
                if ($order->scheduled_delivery_time?->isFuture() || $order->scheduled_at?->isFuture()) {
                    $order->status = 'scheduled';
                    $order->save();
                }

                return $order;
            });
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }

        $order->load([
            'customer:id,name,email,phone_number,profile_picture,profile_photo_url',
            'service:id,name,code,icon_url',
            'lesbuyItems',
            'payments:id,order_id,amount,status,method',
        ]);

        // Bust the order list cache for this customer
        // cache bust removed

        // Bust cache for all drivers so they can see new pending orders
        // cache bust removed

        // Queue confirmation notification
        SendOrderConfirmationJob::dispatch($order)->onQueue('notifications');

        // Notify nearby drivers about new order
        if ($order->isDispatchableToDrivers()) {
            \App\Jobs\NotifyNearbyDriversNewOrderJob::dispatch($order)->onQueue('notifications');
        }

        // Queue auto-assignment (if enabled)
        if ($this->shouldAutoAssignDriver($order)) {
            \App\Jobs\AutoAssignDriverJob::dispatch($order)->onQueue('driver-assignment');
        }

        return $this->created($order, 'Order created successfully');
    }

    /**
     * @OA\Get(
     *     path="/api/v1/orders/{id}",
     *     summary="Get order by ID",
     *     tags={"Orders"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *
     *     @OA\Response(response=200, description="Order details",
     *
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/Order"))
     *     ),
     *
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse"),
     *     @OA\Response(response=404, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function show(Request $request, Order $order): JsonResponse
    {
        if (! $this->canViewOrder($request->user(), $order)) {
            return $this->error('Forbidden', 403);
        }

        $order->load([
            'customer:id,name,email,phone_number,profile_picture,profile_photo_url',
            'partner:id,name',
            'driverProfile:id,user_id,status,rating,plate_number,vehicle_type,last_latitude,last_longitude',
            'driverProfile.user:id,name,email,phone_number,profile_picture,profile_photo_url',
            'service:id,name,code,icon_url',
            'lesbuyItems:id,order_id,menu_item_id,name,quantity,unit,notes,selected_options,estimated_price,actual_price,image_url',
            'payments:id,order_id,amount,status,method,paid_at',
        ]);

        return $this->success($order);
    }

    /**
     * Duplicate a previous order for quick reorder.
     */
    public function reorder(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if ((int) $order->customer_id !== (int) $user->id) {
            return $this->error('Forbidden', 403);
        }

        if (! in_array($order->status, ['completed', 'cancelled'], true)) {
            return $this->error('Only completed or cancelled orders can be reordered.', 422);
        }

        $order->load(['lesbuyItems', 'service']);

        if (! $order->service || ! $order->service->is_active) {
            return $this->error('This service is currently unavailable.', 422);
        }

        $vehicleType = $order->vehicle_type;
        $estimatedFare = $order->estimated_fare;
        $fareBreakdown = $order->fare_breakdown;

        $isLesride = strtoupper((string) ($order->service?->code ?? '')) === 'LESRIDE';

        if ($isLesride) {
            if ($order->estimated_distance_m < 1 || $order->estimated_distance_m > 30000) {
                return $this->error('This LesRide route can no longer be reordered.', 422);
            }

            if ($order->pickup_lat !== null &&
                $order->pickup_lng !== null &&
                $order->dropoff_lat !== null &&
                $order->dropoff_lng !== null) {
                $straightLineDistanceM = $this->calculateHaversineDistance(
                    (float) $order->pickup_lat,
                    (float) $order->pickup_lng,
                    (float) $order->dropoff_lat,
                    (float) $order->dropoff_lng
                );
                if ($straightLineDistanceM < 10 || $straightLineDistanceM > $order->estimated_distance_m + 250) {
                    return $this->error('This LesRide route can no longer be reordered.', 422);
                }
            }

            $vehicleType = 'tricycle';
            $fareBreakdown = $this->fareCalculator->calculate(
                $order->service,
                $order->estimated_distance_m / 1000,
                0.0,
                (float) ($order->estimated_weight_kg ?? 0)
            );
            $estimatedFare = $fareBreakdown['total'];
        }

        $reorderMeta = array_merge($order->meta ?? [], [
            'reordered_from_order_id' => $order->id,
        ]);
        if ($isLesride) {
            $reorderMeta['vehicle_type'] = 'tricycle';
        }

        $newOrder = DB::transaction(function () use (
            $user,
            $order,
            $vehicleType,
            $estimatedFare,
            $fareBreakdown,
            $reorderMeta
        ) {
            $duplicate = Order::create([
                'customer_id' => $user->id,
                'partner_id' => $order->partner_id,
                'driver_id' => null,
                'service_id' => $order->service_id,
                'pickup_address_id' => $order->pickup_address_id,
                'dropoff_address_id' => $order->dropoff_address_id,
                'pickup_address' => $order->pickup_address,
                'pickup_lat' => $order->pickup_lat,
                'pickup_lng' => $order->pickup_lng,
                'pickup_contact_name' => $order->pickup_contact_name,
                'pickup_contact_phone' => $order->pickup_contact_phone,
                'dropoff_address' => $order->dropoff_address,
                'dropoff_lat' => $order->dropoff_lat,
                'dropoff_lng' => $order->dropoff_lng,
                'dropoff_contact_name' => $order->dropoff_contact_name,
                'dropoff_contact_phone' => $order->dropoff_contact_phone,
                'notes' => $order->notes,
                'item_description' => $order->item_description,
                'estimated_weight_kg' => $order->estimated_weight_kg,
                'vehicle_type' => $vehicleType,
                'passenger_name' => $order->passenger_name,
                'status' => 'pending',
                'scheduled_at' => null,
                'estimated_distance_m' => $order->estimated_distance_m,
                'estimated_fare' => $estimatedFare,
                'fare_breakdown' => $fareBreakdown,
                'payment_method' => $order->payment_method ?? 'cash',
                'payment_status' => 'pending',
                'meta' => $reorderMeta,
            ]);

            foreach ($order->lesbuyItems as $item) {
                $duplicate->lesbuyItems()->create([
                    'menu_item_id' => $item->menu_item_id,
                    'name' => $item->name,
                    'quantity' => $item->quantity,
                    'unit' => $item->unit,
                    'notes' => $item->notes,
                    'selected_options' => $item->selected_options,
                    'image_url' => $item->image_url,
                    'estimated_price' => $item->estimated_price,
                    'is_checklist_item' => $item->is_checklist_item,
                    'status' => 'pending',
                ]);
            }

            return $duplicate;
        });

        $newOrder->load([
            'customer:id,name,email,phone_number,profile_picture,profile_photo_url',
            'partner:id,name',
            'service:id,name,code,icon_url',
            'lesbuyItems',
        ]);

        SendOrderConfirmationJob::dispatch($newOrder)->onQueue('notifications');

        if ($this->shouldAutoAssignDriver($newOrder)) {
            \App\Jobs\AutoAssignDriverJob::dispatch($newOrder)->onQueue('driver-assignment');
        }

        return $this->created($newOrder, 'Order reordered successfully');
    }

    /**
     * @OA\Patch(
     *     path="/api/v1/orders/{id}/status",
     *     summary="Update order status",
     *     tags={"Orders"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *
     *     @OA\RequestBody(required=true,
     *
     *         @OA\JsonContent(
     *
     *             @OA\Property(property="status", type="string", enum={"searching_driver","accepted","driver_arrived_at_pickup","in_progress","picked_up","completed","cancelled"}),
     *             @OA\Property(property="payment_status", type="string", enum={"pending","paid","failed"}),
     *             @OA\Property(property="cancel_reason", type="string", nullable=true),
     *             @OA\Property(property="actual_distance_m", type="integer", nullable=true)
     *         )
     *     ),
     *
     *     @OA\Response(response=200, description="Order updated",
     *
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/Order"))
     *     ),
     *
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse"),
     *     @OA\Response(response=409, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function updateStatus(UpdateOrderStatusRequest $request, Order $order): JsonResponse
    {
        return DB::transaction(function () use ($request, $order) {
            // Match automatic assignment lock order to serialize concurrent accepts.
            if ($request->user()->isDriver()) {
                $request->user()->driverProfile()->lockForUpdate()->first();
            }
            $lockedOrder = Order::whereKey($order->id)->lockForUpdate()->firstOrFail();
            return $this->updateLockedStatus($request, $lockedOrder);
        });
    }

    private function updateLockedStatus(UpdateOrderStatusRequest $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if (! $this->canUpdateOrder($user, $order)) {
            return $this->error('Forbidden', 403);
        }

        $data = $request->validated();
        $previousStatus = strtolower((string) $order->status);

        if (isset($data['status'])) {
            $newStatus = $data['status'];

            if ($newStatus === 'accepted' && $user->isDriver()) {
                if (! $order->isDispatchableToDrivers()) {
                    return $this->error('This order is not available for driver acceptance.', 403);
                }
                $profile = $user->driverProfile;
                if ($profile && ! $profile->supportsVehicleTypeValue($order->vehicle_type)) {
                    return $this->error('This order requires a different vehicle type.', 403);
                }
                if ($profile && $profile->orders()->active()->where('id', '!=', $order->id)->exists()) {
                    return $this->error('Complete your active delivery before accepting another order.', 409);
                }
            }

            if (! $this->isStatusChangeAllowed($user, $order, $newStatus)) {
                return $this->error('Status change not allowed for your role or current order state.', 403);
            }

            if ($newStatus === 'completed' && ! collect($order->proof_images ?? [])
                ->contains(fn ($path) => is_string($path) && trim($path) !== '')) {
                return $this->error('Upload at least one delivery photo before completing.', 422);
            }

            if ($newStatus === 'accepted') {
                if (! $user->isDriver()) {
                    return $this->error('Only drivers can accept orders.', 403);
                }

                // Registration fee + approval required for rider operational access
                try {
                    \App\Services\RegistrationFeeService::assertCanAccessOperationalFeatures($user, 'accepting bookings');
                } catch (\RuntimeException $e) {
                    return $this->error($e->getMessage(), 403);
                }

                $driverProfileId = optional($user->driverProfile)->id;

                if (! $driverProfileId) {
                    return $this->error('Driver profile not found for this user.', 422);
                }

                // Pessimistic lock: Re-fetch order with lock to prevent race condition
                // where two drivers accept simultaneously.
                $lockedOrder = Order::lockForUpdate()->find($order->id);
                if (! $lockedOrder) {
                    return $this->error('Order not found.', 404);
                }

                if (! empty($lockedOrder->driver_id) && (int) $lockedOrder->driver_id !== (int) $driverProfileId) {
                    return $this->error('Order already accepted by another driver.', 409);
                }

                if (! $this->isPaymentReadyForDriver($lockedOrder)) {
                    return $this->error('This order is still awaiting payment.', 403);
                }

                // Use the locked version for the rest of this operation
                $order = $lockedOrder;

                WalletValidationService::ensureWalletExists($user);

                $walletCheck = WalletValidationService::validateBalance($user);
                if (! $walletCheck['has_sufficient_balance']) {
                    return $this->error(
                        WalletValidationService::acceptBlockedMessage($user),
                        422,
                        ['wallet_validation' => $walletCheck]
                    );
                }

                try {
                    OrderDriverWalletService::chargeDriverOnAccept($user, $order);
                } catch (\RuntimeException $e) {
                    $chargeAmount = OrderDriverWalletService::resolveBookingChargeAmount($order);

                    return $this->error($e->getMessage(), 422, [
                        'wallet_validation' => WalletValidationService::validateBalance($user),
                        'required_amount' => $chargeAmount,
                    ]);
                }

                $order->driver_id = $driverProfileId;
                $order->accepted_at = now();

                $driverProfile = $user->driverProfile;
                $this->calculateDriverShare($order, $driverProfile);
            }

            if ($newStatus === 'cancelled' && $order->status !== 'cancelled') {
                try {
                    OrderCancellationService::process($order);
                } catch (\Throwable $e) {
                    // CRITICAL: If refund fails, do NOT mark order as cancelled.
                    // The customer's money must be protected.
                    \Illuminate\Support\Facades\Log::error('Order cancellation FAILED - order NOT cancelled', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString(),
                    ]);

                    return $this->error(
                        'Unable to process cancellation. Please try again or contact support.',
                        500
                    );
                }
            }

            // Enforce registration activation for all rider delivery transitions
            if (in_array($newStatus, ['driver_arrived_at_pickup', 'in_progress', 'picked_up', 'completed'], true) && $user->isDriver()) {
                try {
                    \App\Services\RegistrationFeeService::assertCanAccessOperationalFeatures($user, 'delivery operations');
                } catch (\RuntimeException $e) {
                    return $this->error($e->getMessage(), 403);
                }
            }

            match ($newStatus) {
                'accepted' => $order->accepted_at = $order->accepted_at ?? now(),
                'driver_arrived_at_pickup' => $order->driver_arrived_at_pickup = now(),
                'in_progress' => $order->in_progress_at = now(),
                'picked_up' => $order->picked_up_at = now(),
                'completed' => $this->handleOrderCompletion($order),
                'cancelled' => $order->cancelled_at = now(),
                default => null,
            };

            $order->status = $newStatus;

            // Safety net: accepted orders must always have an assigned driver.
            if ($newStatus === 'accepted' && $user->isDriver() && empty($order->driver_id)) {
                $driverProfileId = optional($user->driverProfile)->id;
                if ($driverProfileId) {
                    $order->driver_id = $driverProfileId;
                    $order->accepted_at = $order->accepted_at ?? now();
                }
            }
        }

        if (isset($data['payment_status'])) {
            if (! $user->isAdmin() && ! $user->isPartnerAdmin()) {
                return $this->error('Only admin/partner_admin can update payment status.', 403);
            }
            $order->payment_status = $data['payment_status'];
        }

        if (array_key_exists('cancel_reason', $data)) {
            $order->cancel_reason = $data['cancel_reason'];
        }

        if (isset($data['actual_distance_m'])) {
            if (! $user->isDriver() && ! $user->isAdmin()) {
                return $this->error('Only driver/admin can set actual distance.', 403);
            }

            if ($user->isDriver()) {
                $driverProfileId = optional($user->driverProfile)->id;
                if (! $driverProfileId || (int) $order->driver_id !== (int) $driverProfileId) {
                    return $this->error('You can only update your own assigned order.', 403);
                }
            }

            $order->actual_distance_m = $data['actual_distance_m'];
            $order->loadMissing('service');

            if ($order->service) {
                $serviceCode = strtoupper((string) ($order->service->code ?? 'LESGO'));
                $distanceKm = $order->actual_distance_m / 1000;
                $orderValue = (float) (($order->meta ?? [])['order_value'] ?? 0);

                if ($serviceCode === 'LESRIDE') {
                    $fareBreakdown = $this->fareCalculator->calculate(
                        $order->service,
                        $distanceKm
                    );
                    $order->actual_fare = $fareBreakdown['total'];
                } else {
                    // Preserve the established actual-fare behavior for all
                    // services outside this LesRide rollout.
                    $order->actual_fare = $this->calculateLegacyActualFare(
                        $serviceCode,
                        $distanceKm,
                        $orderValue
                    );
                }
            }
        }

        $order->save();
        $order->refresh();
        $order->load([
            'customer:id,name,email,phone_number,profile_picture,profile_photo_url',
            'partner:id,name',
            'driverProfile:id,user_id,status,rating,plate_number,vehicle_type',
            'driverProfile.user:id,name,email,phone_number,profile_picture,profile_photo_url',
            'service:id,name,code',
            'pickupAddress:id,address_line1,latitude,longitude',
            'dropoffAddress:id,address_line1,latitude,longitude',
            'payments:id,order_id,amount,status,method,paid_at',
        ]);

        // Bust caches for all parties that can see this order
        // cache bust removed
        // cache bust removed
        if ($order->driver_id) {
            // cache bust removed
        }

        // Broadcast real-time status update with previous status
        $this->realtimeService->broadcastOrderStatusUpdate($order, $previousStatus, [
            'updated_by' => $user->id,
            'updated_by_role' => $user->role,
            'timestamp' => now()->toISOString(),
        ]);

        // Broadcast driver assigned event when order is accepted
        if (isset($data['status']) && $data['status'] === 'accepted' && $order->driver_id) {
            $driver = $user; // The driver who accepted
            $order->load('customer', 'driverProfile.user');

            // Calculate rough ETA based on distance
            $etaMinutes = null;
            if ($order->estimated_distance_m) {
                $distanceKm = $order->estimated_distance_m / 1000;
                $avgSpeedKmh = 30; // Average city speed
                $etaMinutes = ($distanceKm / $avgSpeedKmh) * 60;
            }

            broadcast(new OrderDriverAssigned(
                $order,
                $driver,
                $etaMinutes ? round($etaMinutes) : null
            ));
        }

        // Queue driver-assigned notification when a driver accepts
        if (isset($data['status']) && $data['status'] === 'accepted') {
            NotifyDriverAssignedJob::dispatch($order)->onQueue('notifications');
        }

        return $this->success($order, 'Order status updated successfully');
    }

    // ── Scoping helpers ──────────────────────────────────────────────────────

    private function scopedOrdersQuery($user)
    {
        $query = Order::query();

        if (! $user) {
            return $query->whereRaw('1=0');
        }
        if ($user->isAdmin()) {
            return $query;
        }
        if ($user->isCustomer()) {
            return $query->where('customer_id', $user->id);
        }

        if ($user->isDriver()) {
            $id = optional($user->driverProfile)->id;
            if (! $id) {
                return $query->whereRaw('1=0');
            }

            // Restricted riders (unpaid or not approved) see only own assigned orders, not the pending pool
            $canAccessPool = true;
            try {
                $canAccessPool = \App\Services\RegistrationFeeService::canAccessOperationalFeatures($user);
            } catch (\Throwable $e) {
                $canAccessPool = true; // fallback if table not yet migrated
            }

            if (!$canAccessPool) {
                return $query->where('driver_id', $id);
            }

            // Drivers see:
            // 1. Orders assigned to them (accepted, picked_up, completed, cancelled)
            // 2. All pending/unassigned orders available to accept
            $vehicleTypes = $user->driverProfile->supportedVehicleTypes();
            return $query->where(function ($q) use ($id, $vehicleTypes) {
                $q->where('driver_id', $id)                          // their own orders
                    ->orWhere(function ($q2) use ($vehicleTypes) {
                        $q2->dispatchableToDrivers()
                            ->where(function ($vehicleQuery) use ($vehicleTypes) {
                                $vehicleQuery->whereNull('vehicle_type')
                                    ->orWhere('vehicle_type', '')
                                    ->orWhereIn('vehicle_type', $vehicleTypes);
                            });
                    });
            });
        }

        if ($user->isPartnerAdmin()) {
            $id = optional($user->partner)->id;

            return $id ? $query->where('partner_id', $id) : $query->whereRaw('1=0');
        }

        // Partner staff (cashier, cook, etc.) see same orders as partner admin
        if ($user->role === 'partner_staff') {
            $id = $user->partner_id ?? optional($user->partner)->id;

            return $id ? $query->where('partner_id', $id) : $query->whereRaw('1=0');
        }

        return $query->whereRaw('1=0');
    }

    private function canViewOrder($user, Order $order): bool
    {
        if (! $user) {
            return false;
        }
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isCustomer()) {
            return (int) $order->customer_id === (int) $user->id;
        }
        if ($user->isDriver()) {
            $driverProfileId = optional($user->driverProfile)->id;
            if (! $driverProfileId) {
                return false;
            }

            // Can view if assigned to them OR if order is still pending/unassigned
            return (int) $order->driver_id === (int) $driverProfileId
                || (is_null($order->driver_id) && in_array($order->status, ['pending', 'searching_driver', 'ready_for_pickup']));
        }
        if ($user->isPartnerAdmin()) {
            return optional($user->partner)->id && (int) $order->partner_id === (int) optional($user->partner)->id;
        }

        // Partner staff can view same orders as partner admin
        if ($user->role === 'partner_staff') {
            $partnerId = $user->partner_id ?? optional($user->partner)->id;

            return $partnerId && (int) $order->partner_id === (int) $partnerId;
        }

        return false;
    }

    private function canUpdateOrder($user, Order $order): bool
    {
        if (! $user) {
            return false;
        }
        if ($user->isAdmin()) {
            return true;
        }

        return $this->canViewOrder($user, $order) || $user->isDriver();
    }

    private function isStatusChangeAllowed($user, Order $order, string $newStatus): bool
    {
        $new = strtolower($newStatus);
        $current = strtolower((string) $order->status);

        if (! $user) {
            return false;
        }
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isCustomer()) {
            // Customers cannot cancel after items have been picked up by the rider.
            // This prevents disputes where food/packages are already in transit.
            $nonCancellableStatuses = ['in_progress', 'picked_up', 'completed', 'cancelled'];

            return $new === 'cancelled'
                && ! in_array($current, $nonCancellableStatuses, true)
                && (int) $order->customer_id === (int) $user->id;
        }

        if ($user->isDriver()) {
            $driverId = optional($user->driverProfile)->id;

            if ($new === 'accepted') {
                $canTake = empty($order->driver_id) || (int) $order->driver_id === (int) $driverId;
                $validFrom = in_array($current, ['pending', 'searching_driver', 'ready_for_pickup'], true);
                // Only allow 'active' drivers to accept orders
                $driverStatus = optional($user->driverProfile)->status ?? 'pending';
                $validStatus = $driverStatus === 'active';
                $paymentReady = $this->isPaymentReadyForDriver($order);

                // Debug logging
                \Log::info('Driver attempting to accept order', [
                    'user_id' => $user->id,
                    'driver_id' => $driverId,
                    'order_id' => $order->id,
                    'order_driver_id' => $order->driver_id,
                    'order_status' => $current,
                    'driver_status' => $driverStatus,
                    'canTake' => $canTake,
                    'validFrom' => $validFrom,
                    'validStatus' => $validStatus,
                    'paymentReady' => $paymentReady,
                    'result' => $driverId && $canTake && $validFrom && $validStatus && $paymentReady,
                ]);

                return $driverId && $canTake && $validFrom && $validStatus && $paymentReady;
            }

            $owns = $driverId && (int) $order->driver_id === (int) $driverId;
            if (! $owns) {
                return false;
            }

            return match ($new) {
                'driver_arrived_at_pickup' => in_array($current, ['accepted', 'ready_for_pickup'], true),
                'in_progress' => in_array($current, ['accepted', 'ready_for_pickup', 'driver_arrived_at_pickup'], true),
                'picked_up' => in_array($current, ['accepted', 'ready_for_pickup', 'driver_arrived_at_pickup', 'in_progress'], true),
                'completed' => $current === 'picked_up',
                default => false,
            };
        }

        if ($user->isPartnerAdmin()) {
            $partnerId = optional($user->partner)->id;
            if (! $partnerId || (int) $order->partner_id !== (int) $partnerId) {
                return false;
            }

            // Merchant operational block if not active (cannot manage live order flow)
            if (in_array($new, ['searching_driver', 'ready_for_pickup'], true)) {
                try {
                    \App\Services\RegistrationFeeService::assertCanAccessOperationalFeatures($user, 'merchant order operations');
                } catch (\RuntimeException $e) {
                    return false;
                }
            }

            return match ($new) {
                'searching_driver' => $current === 'pending',
                'ready_for_pickup' => in_array($current, ['searching_driver', 'accepted'], true),
                'cancelled' => in_array($current, ['pending', 'searching_driver', 'ready_for_pickup'], true),
                default => false,
            };
        }

        return false;
    }

    // ── Fare calculation ─────────────────────────────────────────────────────

    private function calculateLegacyActualFare(
        string $serviceCode,
        float $distanceKm,
        float $orderValue = 0.0
    ): float {
        $distanceKm = max(0, min($distanceKm, 30));
        $baseFare = 40.0;
        $firstKm = 3.0;

        $fare = $distanceKm <= $firstKm
            ? $baseFare
            : $baseFare + (($distanceKm - $firstKm) * ($serviceCode === 'LESGO' ? 9.5 : 10.0));

        if (in_array($serviceCode, ['LESBUY', 'LESEAT'], true)) {
            $fare += match (true) {
                $orderValue <= 500 => 15,
                $orderValue <= 1000 => 30,
                default => 45,
            };
        }

        return round($fare, 2);
    }

    private function calculateHaversineDistance(
        float $lat1,
        float $lng1,
        float $lat2,
        float $lng2
    ): float {
        $earthRadius = 6371000;
        $latDelta = deg2rad($lat2 - $lat1);
        $lngDelta = deg2rad($lng2 - $lng1);
        $a = sin($latDelta / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($lngDelta / 2) ** 2;

        return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * Calculate driver share from shipping fee and rider package commission.
     */
    private function calculateDriverShare(Order $order, ?\App\Models\DriverProfile $driverProfile = null): void
    {
        if (! $driverProfile && $order->driver_id) {
            $driverProfile = \App\Models\DriverProfile::find($order->driver_id);
        }

        RiderCommissionService::applySharesToOrder($order, $driverProfile);
    }

    /**
     * Handle order completion - calculate driver share for earnings display
     */
    private function handleOrderCompletion(Order $order): void
    {
        $order->completed_at = now();
        $order->loadMissing('driverProfile');

        // Mark cash orders as paid on completion (rider collected cash from customer)
        $paymentMethod = strtolower((string) ($order->payment_method ?? 'cash'));
        $paymentStatus = strtolower((string) ($order->payment_status ?? 'pending'));

        if ($paymentMethod === 'cash' && $paymentStatus === 'pending') {
            $order->payment_status = 'paid';
        }

        // Adjust driver hold if actual fare is lower than estimated
        // (refund the difference so driver isn't overcharged)
        $this->adjustDriverHoldOnCompletion($order);

        // Always recalculate driver share at completion (actual_fare may have been updated)
        $this->calculateDriverShare($order, $order->driverProfile);

        SendRatingReminderJob::dispatch($order->customer_id, $order->id)
            ->delay(now()->addMinutes(30));
    }

    /**
     * If the actual fare is less than estimated, refund the driver the hold difference.
     * Hold was charged based on estimated_fare; if actual is lower, driver overpaid.
     */
    private function adjustDriverHoldOnCompletion(Order $order): void
    {
        $meta = is_array($order->meta) ? $order->meta : [];
        $chargedAmount = (float) ($meta['driver_wallet_charged_amount'] ?? 0);

        if ($chargedAmount <= 0) {
            return;
        } // No hold was charged
        if (! empty($meta['driver_hold_adjusted'])) {
            return;
        } // Already adjusted

        $actualFare = (float) ($order->actual_fare ?? $order->estimated_fare ?? 0);
        $correctHold = RiderCommissionService::resolveShippingFee($order);

        // Only refund if the original hold was more than what it should be based on actual fare
        $difference = round($chargedAmount - $correctHold, 2);

        if ($difference > 1.0) { // Only refund if difference is meaningful (> ₱1)
            $driver = $order->driverProfile?->user;
            if ($driver) {
                WalletService::credit(
                    $driver,
                    $difference,
                    "Hold adjustment for order #{$order->id} (actual fare lower than estimate)",
                    Order::class,
                    $order->id,
                );

                $meta['driver_hold_adjusted'] = true;
                $meta['driver_hold_adjustment_amount'] = $difference;
                $order->meta = $meta;
            }
        }
    }

    /**
     * Determine if order should use auto-assignment
     */
    private function shouldAutoAssignDriver(Order $order): bool
    {
        if (! $this->isPaymentReadyForDriver($order)) {
            return false;
        }

        // Check if auto-assignment is enabled globally
        $autoAssignEnabled = \App\Models\SecuritySetting::getValue('driver.auto_assignment_enabled', true);

        if (! $autoAssignEnabled) {
            return false;
        }

        // Don't auto-assign scheduled orders (assign closer to scheduled time)
        if ($order->scheduled_at && $order->scheduled_at->isFuture()) {
            return false;
        }

        // Don't auto-assign if order has scheduled delivery time in the future
        if ($order->scheduled_delivery_time &&
            \Carbon\Carbon::parse($order->scheduled_delivery_time)->isFuture()) {
            return false;
        }

        // Don't auto-assign if customer specifically requested manual assignment
        $meta = $order->meta ?? [];
        if (isset($meta['manual_assignment']) && $meta['manual_assignment']) {
            return false;
        }

        return true;
    }

    private function isPaymentReadyForDriver(Order $order): bool
    {
        $method = strtolower((string) ($order->payment_method ?? 'cash'));

        return $method === 'cash' || strtolower((string) $order->payment_status) === 'paid';
    }

    /**
     * @OA\Post(
     *     path="/api/v1/orders/{id}/upload-proof",
     *     summary="Upload proof of delivery/completion images",
     *     tags={"Orders"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *
     *     @OA\RequestBody(required=true,
     *
     *         @OA\MediaType(mediaType="multipart/form-data",
     *
     *             @OA\Schema(
     *
     *                 @OA\Property(property="images[]", type="array", @OA\Items(type="string", format="binary"))
     *             )
     *         )
     *     ),
     *
     *     @OA\Response(response=200, description="Proof images uploaded successfully"),
     *     @OA\Response(response=403, description="Forbidden"),
     *     @OA\Response(response=404, description="Order not found")
     * )
     */
    public function uploadProof(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        // Only driver assigned to the order can upload proof
        if (! $user->isDriver()) {
            return $this->error('Only drivers can upload proof images', 403);
        }

        $driverId = optional($user->driverProfile)->id;
        if (! $driverId || (int) $order->driver_id !== (int) $driverId) {
            return $this->error('You are not assigned to this order', 403);
        }

        // Validate that order is in a state where proof can be uploaded
        if (! in_array($order->status, ['picked_up', 'completed'])) {
            return $this->error('Proof can only be uploaded for picked up or completed orders', 400);
        }

        $request->validate([
            'images' => 'required|array|min:1|max:5',
            'images.*' => 'required|image|mimes:jpeg,jpg,png|max:5120', // 5MB max per image
        ]);

        $uploadedPaths = [];

        try {
            foreach ($request->file('images') as $image) {
                $path = MediaStorageService::storeUploadedFile(
                    $image,
                    "proof_images/{$order->id}"
                );
                $uploadedPaths[] = $path;
            }

            // Update order with proof images
            $existingProofs = $order->proof_images ?? [];
            $allProofs = array_merge($existingProofs, $uploadedPaths);

            $order->update([
                'proof_images' => $allProofs,
                'proof_uploaded_at' => now(),
            ]);

            // Clear cache
            // cache bust removed
            // cache bust removed

            return $this->success([
                'order' => $order->fresh(),
                'uploaded_images' => $uploadedPaths,
                'message' => 'Proof images uploaded successfully',
            ]);

        } catch (\Exception $e) {
            // Clean up uploaded files on error
            foreach ($uploadedPaths as $path) {
                MediaStorageService::deleteIfExists($path);
            }

            return $this->error('Failed to upload proof images: '.$e->getMessage(), 500);
        }
    }

    /**
     * Rider feedback for customer after a completed delivery.
     */
    public function submitFeedback(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();

        if (! $user->isDriver()) {
            return $this->error('Only drivers can submit customer feedback for orders.', 403);
        }

        $driverProfileId = optional($user->driverProfile)->id;
        if (! $driverProfileId || (int) $order->driver_id !== (int) $driverProfileId) {
            return $this->error('You are not assigned to this order.', 403);
        }

        if ($order->status !== 'completed') {
            return $this->error('Feedback is only allowed for completed orders.', 400);
        }

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'target' => 'nullable|in:customer',
        ]);

        $meta = is_array($order->meta) ? $order->meta : [];
        if (! empty($meta['rider_customer_rating'])) {
            return $this->error('You have already rated this customer for this order.', 409);
        }

        $meta['rider_customer_rating'] = (int) $validated['rating'];
        $meta['rider_customer_rating_comment'] = $validated['comment'] ?? null;
        $meta['rider_customer_rated_by'] = $user->id;
        $meta['rider_customer_rated_at'] = now()->toIso8601String();

        $order->update(['meta' => $meta]);

        return $this->success([
            'order_id' => $order->id,
            'rating' => (int) $validated['rating'],
            'comment' => $validated['comment'] ?? null,
        ], 'Customer feedback saved successfully');
    }

    /** Return only option prices and labels that exist on the live menu item. */
    private function resolveCanonicalMenuOptions(array $available, array $selected): ?array
    {
        $canonical = [];
        foreach (['size' => 'sizes', 'flavor' => 'flavors'] as $selectedKey => $menuKey) {
            $choice = $selected[$selectedKey] ?? null;
            if ($choice === null) {
                continue;
            }
            if (!is_array($choice) || !is_string($choice['label'] ?? null)) {
                return null;
            }
            $match = collect($available[$menuKey] ?? [])->first(
                static fn ($option) => is_array($option)
                    && strcasecmp(trim((string) ($option['label'] ?? '')), trim($choice['label'])) === 0
            );
            if (!$match) {
                return null;
            }
            $canonical[$selectedKey] = [
                'label' => (string) $match['label'],
                'price' => round((float) ($match['price'] ?? 0), 2),
            ];
        }

        $addons = $selected['addons'] ?? [];
        if (!is_array($addons)) {
            return null;
        }
        if ($addons !== []) {
            $canonical['addons'] = [];
            foreach ($addons as $addon) {
                if (!is_array($addon) || !is_string($addon['label'] ?? null)) {
                    return null;
                }
                $match = collect($available['addons'] ?? [])->first(
                    static fn ($option) => is_array($option)
                        && strcasecmp(trim((string) ($option['label'] ?? '')), trim($addon['label'])) === 0
                );
                $quantity = filter_var($addon['quantity'] ?? 1, FILTER_VALIDATE_INT);
                if (!$match || $quantity === false || $quantity < 1 || $quantity > 20) {
                    return null;
                }
                $canonical['addons'][] = [
                    'label' => (string) $match['label'],
                    'price' => round((float) ($match['price'] ?? 0), 2),
                    'quantity' => $quantity,
                ];
            }
        }

        return $canonical;
    }
}
