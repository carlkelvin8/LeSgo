# Payment Method Selector - UI Locations 📍

## Visual Guide: Where Payment Selector Appears

### 1. LesBuy (Shopping/Errands) 🛒

**Screen**: `store_cart_screen.dart`

```
┌─────────────────────────────────────┐
│  Checkout                      [X]  │
├─────────────────────────────────────┤
│                                     │
│  📍 Delivery Address                │
│  Brgy 6, Claveria, Cagayan    [>]  │
│                                     │
│  🏪 Store Name                      │
│  ├─ Product 1         x2    ₱100   │
│  ├─ Product 2         x1    ₱50    │
│  └─ [+ Add more items]             │
│                                     │
│  💳 Payment Method  ← NEW!          │
│  ┌─────────────────────────────┐   │
│  │ 💵 Cash on Delivery    (•)  │   │
│  │ Pay with cash when order    │   │
│  │ arrives                     │   │
│  └─────────────────────────────┘   │
│                                     │
│  🎟️ Voucher                         │
│  [Apply voucher code]          [>] │
│                                     │
│  📊 Order Summary                   │
│  Subtotal:              ₱150.00    │
│  Delivery:              ₱50.00     │
│  Total:                 ₱200.00    │
│                                     │
│  [      Checkout      ]            │
└─────────────────────────────────────┘
```

### 2. LesEat (Food Delivery) 🍔

**Screen**: `leseat_checkout_screen.dart`

```
┌─────────────────────────────────────┐
│  Checkout                      [X]  │
├─────────────────────────────────────┤
│                                     │
│  📍 Delivery Address                │
│  Brgy 6, Claveria, Cagayan    [>]  │
│                                     │
│  🍽️ Restaurant Name                 │
│  ├─ Burger Meal       x2    ₱200   │
│  ├─ Fries             x1    ₱50    │
│  └─ [+ Add more items]             │
│                                     │
│  💳 Payment Method  ← NEW!          │
│  ┌─────────────────────────────┐   │
│  │ 💵 Cash on Delivery    (•)  │   │
│  │ Pay with cash when order    │   │
│  │ arrives                     │   │
│  └─────────────────────────────┘   │
│                                     │
│  🎟️ Voucher                         │
│  [Apply voucher code]          [>] │
│                                     │
│  📊 Order Summary                   │
│  Subtotal:              ₱250.00    │
│  Delivery:              ₱50.00     │
│  Total:                 ₱300.00    │
│                                     │
│  [      Checkout      ]            │
└─────────────────────────────────────┘
```

### 3. LesRide (Motorcycle/Car Ride) 🏍️

**Screen**: `lesride_screen.dart` (Details Panel)

```
┌─────────────────────────────────────┐
│         [Google Maps View]          │
│                                     │
│         🏍️ → 📍                     │
│                                     │
├─────────────────────────────────────┤
│  📍 Pickup Location                 │
│  Current Location             [>]  │
│                                     │
│  📍 Destination                     │
│  Select destination           [>]  │
│                                     │
│  💳 Payment Method  ← UPDATED!      │
│  ┌─────────────────────────────┐   │
│  │ 💵 Cash on Delivery    (•)  │   │
│  │ Pay with cash when you      │   │
│  │ arrive                      │   │
│  └─────────────────────────────┘   │
│                                     │
│  📊 Fare Estimate                   │
│  Distance: 5.2 km                  │
│  Duration: 15 mins                 │
│  Fare: ₱120.00                     │
│                                     │
│  [      Book Ride      ]           │
└─────────────────────────────────────┘
```

### 4. LesGo (General Delivery) 📦

**Screen**: `lesgo_screen.dart` (Details Panel)

```
┌─────────────────────────────────────┐
│         [Google Maps View]          │
│                                     │
│         📦 → 📍                     │
│                                     │
├─────────────────────────────────────┤
│  📍 Pickup Location                 │
│  Current Location             [>]  │
│                                     │
│  📍 Destination                     │
│  Select destination           [>]  │
│                                     │
│  📦 Item Details                    │
│  Description: [____________]       │
│  Weight: [____________]            │
│                                     │
│  💳 Payment Method  ← UPDATED!      │
│  ┌─────────────────────────────┐   │
│  │ 💵 Cash on Delivery    (•)  │   │
│  │ Pay with cash when          │   │
│  │ delivered                   │   │
│  └─────────────────────────────┘   │
│                                     │
│  📊 Delivery Estimate               │
│  Distance: 3.8 km                  │
│  Duration: 12 mins                 │
│  Fee: ₱100.00                      │
│                                     │
│  [      Book Delivery      ]       │
└─────────────────────────────────────┘
```

## Payment Method Selector Component

### Default View (COD Only)

```
┌─────────────────────────────────────┐
│  💳 Payment Method                  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💵  Cash on Delivery   (•)  │   │
│  │     Pay with cash when      │   │
│  │     order arrives           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Future View (All Methods Enabled)

```
┌─────────────────────────────────────┐
│  💳 Payment Method                  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💵  Cash on Delivery   (•)  │   │
│  │     Pay with cash when      │   │
│  │     order arrives           │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💰  LesPay Wallet      ( )  │   │
│  │     Balance: ₱1,500.00      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📱  GCash              ( )  │   │
│  │     Pay with GCash e-wallet │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📱  PayMaya            ( )  │   │
│  │     Pay with PayMaya        │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💳  Credit/Debit Card  ( )  │   │
│  │     Pay with card           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Design Specifications

### Colors
- **Primary**: `#5F2D82` (Purple)
- **Selected Background**: `#5F2D82` with 5% opacity
- **Border (Selected)**: `#5F2D82` (2px)
- **Border (Unselected)**: `#E0E0E0` (1px)
- **Icon Background**: Icon color with 10% opacity

### Icons
- 💵 Cash: `Icons.money` (Green)
- 💰 Wallet: `Icons.account_balance_wallet` (Purple)
- 📱 GCash: `Icons.phone_android` (Blue)
- 📱 PayMaya: `Icons.phone_android` (Green)
- 💳 Card: `Icons.credit_card` (Orange)

### Spacing
- Container padding: 16px
- Between options: 12px
- Icon padding: 8px
- Icon size: 24px
- Title font: 14px (Bold)
- Subtitle font: 12px (Regular)

### States
- **Enabled**: Full color, clickable
- **Disabled**: Gray color, not clickable
- **Selected**: Purple border, purple background tint, filled radio button
- **Unselected**: Gray border, white background, empty radio button

## Integration Points

### LesBuy & LesEat
- **Location**: Between order items and voucher section
- **Behavior**: Disabled when cart is empty
- **Spacing**: 16px margin top and bottom

### LesRide & LesGo
- **Location**: In details panel, after location selection
- **Behavior**: Always enabled
- **Spacing**: Part of the scrollable details panel

## User Experience

1. **Default Selection**: COD is pre-selected
2. **Single Selection**: Only one payment method can be selected at a time
3. **Visual Feedback**: Selected option has purple border and background tint
4. **Disabled State**: When cart is empty (LesBuy/LesEat only)
5. **Tap Anywhere**: User can tap anywhere on the option card to select

## Accessibility

- ✅ Radio buttons for screen readers
- ✅ Clear labels and descriptions
- ✅ High contrast colors
- ✅ Large tap targets (full card is tappable)
- ✅ Disabled state clearly indicated

---

**Status**: ✅ Implemented and integrated across all services
**Design**: ✅ Consistent with existing app design
**Responsive**: ✅ Works on all screen sizes
