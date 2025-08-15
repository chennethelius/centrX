# CentrX Theme System Documentation

## Overview

The CentrX app now uses a centralized theme system built on Flutter's ThemeData approach. This provides consistency across the entire app and makes it easy to maintain and update the design.

## Files Structure

```
lib/theme/
├── app_theme.dart          # Main theme definitions
└── theme_extensions.dart   # Context extensions for easy access
```

## Key Features

### 🎨 **Color System**
- **Primary Colors**: `primaryBlue`, `primaryCyan`, `lightBlue`, `accentGold`
- **Surface Colors**: `surfaceWhite`, `surfaceBlack`
- **Status Colors**: `successGreen`, `warningOrange`, `errorRed`, etc.
- **Glassmorphism Helpers**: `glassWhite(opacity)`, `glassBlack(opacity)`

### 📝 **Typography Scale**
- **Display**: `displayLarge`, `displayMedium`, `displaySmall`
- **Headlines**: `headlineLarge`, `headlineMedium`, `headlineSmall`
- **Body**: `bodyLarge`, `bodyMedium`, `bodySmall`
- **Labels**: `labelLarge`, `labelMedium`, `labelSmall`

### 📏 **Spacing System**
- `spacingXS` (4px) → `spacingHuge` (32px)
- Consistent spacing across all components

### 🔄 **Border Radius Scale**
- `radiusXS` (4px) → `radiusHuge` (28px)
- Consistent corner rounding

### 🎭 **Gradients & Effects**
- `backgroundGradient`: Main app background
- `glassmorphismGradient()`: Customizable glass effect
- `getShadow()`: Elevation system with small/medium/large levels

## Usage Examples

### Basic Usage with Context Extensions

```dart
import 'package:flutter_auth/theme/theme_extensions.dart';

Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(context.spacingXL),
    decoration: BoxDecoration(
      gradient: context.backgroundGradient,
      borderRadius: BorderRadius.circular(context.radiusXXL),
    ),
    child: Text(
      'Hello World',
      style: context.theme.textTheme.headlineLarge,
    ),
  );
}
```

### Glassmorphism Effect

```dart
Widget glassCard() {
  return Container(
    decoration: BoxDecoration(
      gradient: context.glassmorphismGradient(opacity1: 0.25, opacity2: 0.1),
      borderRadius: BorderRadius.circular(context.radiusXXL),
      border: Border.all(
        color: context.glassWhite(0.3),
        width: 1.5,
      ),
      boxShadow: context.getShadow(level: 'medium'),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(context.radiusXXL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: YourContent(),
      ),
    ),
  );
}
```

### Colors & Typography

```dart
Widget themedButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: context.primaryBlue,
      foregroundColor: Colors.white,
    ),
    child: Text(
      'Button Text',
      style: context.theme.textTheme.labelLarge,
    ),
    onPressed: () {},
  );
}
```

## Migration Strategy

We're gradually migrating the existing codebase to use the theme system. Here's the recommended approach:

### Phase 1: Basic Integration ✅
- [x] Create theme system
- [x] Apply to main.dart
- [x] Update home page header (example)

### Phase 2: Component Migration (In Progress)
- [ ] Update all hard-coded colors to use theme colors
- [ ] Replace magic numbers with spacing/radius constants
- [ ] Update text styles to use theme typography

### Phase 3: Advanced Features (Future)
- [ ] Add Google Fonts integration
- [ ] Implement dark mode support
- [ ] Add theme customization options
- [ ] Create theme-aware animations

## Quick Reference

### Spacing
```dart
context.spacingXS    // 4px
context.spacingS     // 8px
context.spacingM     // 12px
context.spacingL     // 16px
context.spacingXL    // 20px
context.spacingXXL   // 24px
context.spacingHuge  // 32px
```

### Colors
```dart
context.primaryBlue     // #6366F1
context.primaryCyan     // #06B6D4
context.lightBlue       // #7ECBFF
context.accentGold      // #FFD700
```

### Typography
```dart
context.theme.textTheme.displayLarge     // 32px, w800
context.theme.textTheme.headlineLarge    // 22px, w700
context.theme.textTheme.bodyLarge        // 16px, w400
context.theme.textTheme.labelMedium      // 12px, w500
```

### Shadows
```dart
context.getShadow(level: 'small')    // Subtle shadow
context.getShadow(level: 'medium')   // Standard shadow
context.getShadow(level: 'large')    // Prominent shadow
```

## Benefits

1. **Consistency**: All components use the same design tokens
2. **Maintainability**: Update colors/spacing in one place
3. **Scalability**: Easy to add new themes or variations
4. **Developer Experience**: Autocomplete and type safety
5. **Design System**: Clear hierarchy and relationships

## Next Steps

1. Continue migrating existing components
2. Add Google Fonts support
3. Implement dark mode
4. Create component-specific theme extensions
5. Add animation duration constants

## Contributing

When adding new components or updating existing ones:

1. Use theme colors instead of hard-coded values
2. Use spacing constants instead of magic numbers
3. Use typography scale instead of custom TextStyles
4. Follow the glassmorphism pattern for cards/surfaces
5. Test with both light and dark themes (when available)

---

*This theme system provides the foundation for a cohesive, maintainable design system throughout the CentrX app.*
