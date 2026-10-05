# Hero Banner Image Setup Guide 🎨

## Current Status
The hero banner carousel now supports **custom images** with **dark purple overlay** for better text visibility.

## Image Slides Configuration

### Slide 1: Welcome Banner
- **Path**: `assets/images/homepage/customer_welcome_hero.png`
- **Title**: "Ready to Order?"
- **Subtitle**: "Book your ride now"
- **Shows**: User greeting (Hello, Carl!)

### Slide 2: Tricycle/Ride Banner  
- **Path**: `assets/images/homepage/tricycle_hero.png`
- **Title**: "Best Prices"
- **Subtitle**: "Affordable rates for everyone"

### Slide 3: Food Delivery Banner 🍔🛵
- **Path**: `assets/images/homepage/food_delivery_hero.png`
- **Title**: "Fast Food Delivery"
- **Subtitle**: "Get your favorites delivered quickly"
- **Content**: Burger, fries, milktea, chicken with purple rider on motorcycle

## To Add Your Image:

### Step 1: Save the Image
Save your food delivery image as:
```
FRONTEND/assets/images/homepage/food_delivery_hero.png
```

**Recommended Specs:**
- Format: PNG or JPG
- Resolution: 1080x660px (or 16:9.6 ratio)
- File size: < 500KB for performance
- Quality: High (the image will be covered with purple overlay)

### Step 2: Image Already Configured! ✅
The carousel is already set up to use:
- `food_delivery_hero.png` as Slide 3
- Dark purple overlay for branding
- White text for visibility
- Auto-scroll every 4 seconds

## Dark Purple Overlay Details

### Gradient Colors:
- **Top**: `Color(0xFF5F2D82)` at 70% opacity
- **Bottom**: `Color(0xFF3D1A52)` at 80% opacity

### Effect:
- Darkens the image for text readability
- Maintains brand color (purple)
- Creates depth and premium feel
- Text pops with white color + shadow

## Text Styling

### Greeting Text (Slide 1 only):
- Color: **White**
- Size: 22px
- Weight: Bold
- Shadow: Black 30% opacity

### Title Text (All slides):
- Color: **White**
- Size: 16px
- Weight: Bold
- Shadow: Black 30% opacity

### Subtitle Text (All slides):
- Color: **White 95% opacity**
- Size: 12px
- Weight: Regular
- Shadow: Black 30% opacity

## Visual Result

**Before dark overlay:**
```
[Bright Image] + [Dark Text] = Hard to read ❌
```

**After dark purple overlay:**
```
[Image] + [Dark Purple Overlay] + [White Text] = Perfect contrast ✅
```

## Carousel Behavior

- **Auto-scroll**: Every 4 seconds
- **Transition**: 600ms smooth slide
- **Indicators**: Purple dots at bottom
- **User control**: Can swipe manually
- **Infinite loop**: Cycles continuously

## File Location

Update carousel slides at:
```
FRONTEND/lib/presentation/widgets/home/home_hero_section.dart
```

Lines 23-43:
```dart
final List<Map<String, dynamic>> _slides = [
  {
    'background': 'assets/images/homepage/customer_welcome_hero.png',
    'backgroundType': 'image',
    'title': 'Ready to Order?',
    'subtitle': 'Book your ride now',
  },
  // ... more slides
];
```

## Adding More Slides

To add another slide:

```dart
{
  'background': 'assets/images/homepage/your_image.png',
  'backgroundType': 'image', // 'svg' or 'image'
  'title': 'Your Title',
  'subtitle': 'Your subtitle',
},
```

**Note**: Carousel will automatically adjust to new slide count!

## Image Best Practices

### DO:
✅ Use high-quality images (PNG preferred)
✅ Keep aspect ratio 16:9.6 (1080x660px)
✅ Optimize file size (compress to <500KB)
✅ Use vibrant, colorful images
✅ Test on different screen sizes

### DON'T:
❌ Use very dark images (overlay makes them darker)
❌ Use images with small text (will be unreadable)
❌ Exceed 1MB file size (slows loading)
❌ Use portrait orientation
❌ Forget to add to pubspec.yaml

## pubspec.yaml Assets

Make sure images are declared:

```yaml
flutter:
  assets:
    - assets/images/homepage/
    - assets/images/homepage/customer_welcome_hero.png
    - assets/images/homepage/tricycle_hero.png
    - assets/images/homepage/food_delivery_hero.png
```

Or use wildcard:
```yaml
flutter:
  assets:
    - assets/images/homepage/
```

## Testing

1. Save image to correct path
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run --dart-define-from-file=secrets.json`
5. Check carousel auto-scrolls
6. Verify dark purple overlay visible
7. Confirm white text readable

## Troubleshooting

**Image not showing:**
- Check file path spelling
- Verify asset declared in pubspec.yaml
- Run `flutter clean` and rebuild

**Overlay too dark:**
- Reduce opacity in `hero_banner.dart`:
  ```dart
  Color(0xFF5F2D82).withOpacity(0.5), // Lower = lighter
  ```

**Text hard to read:**
- Image might be too busy
- Increase overlay opacity
- Use simpler background image

---

**Status**: ✅ Ready to use
**Image needed**: `food_delivery_hero.png` (1080x660px)
**Result**: Modern carousel with purple brand overlay! 🎉
