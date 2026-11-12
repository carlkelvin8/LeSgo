<?php

namespace App\Http\Requests\Concerns;

/**
 * Validation rules for a menu item's `options` JSON, shared by the create and
 * update requests so they cannot drift apart.
 *
 * Laravel drops every array key that has no rule, so each key the apps send
 * must be listed here or it is silently lost. `_inventory` is the stock block
 * written by the merchant app (merchant_item_inventory_utils.dart).
 */
trait MenuItemOptionRules
{
    /**
     * @return array<string, array<int, string>>
     */
    protected function menuItemOptionRules(): array
    {
        $choice = static fn (string $key, int $max): array => [
            "options.$key" => ['nullable', 'array', "max:$max"],
            "options.$key.*.label" => ["required_with:options.$key", 'string', 'max:100'],
            "options.$key.*.price" => ['nullable', 'numeric', 'min:0', 'max:999999.99'],
        ];

        return [
            'options' => ['nullable', 'array'],
            ...$choice('sizes', 20),
            ...$choice('flavors', 20),
            ...$choice('addons', 30),
            'options._inventory' => ['nullable', 'array'],
            'options._inventory.stock' => ['nullable', 'integer', 'min:0', 'max:1000000'],
            'options._inventory.track_stock' => ['nullable', 'boolean'],
            'options._inventory.auto_hide_when_empty' => ['nullable', 'boolean'],
        ];
    }
}
