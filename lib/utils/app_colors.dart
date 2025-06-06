import 'package:flutter/material.dart';

/// Centralized color palette for the math skills game
/// Bright and playful colors designed for kids aged 6-10
/// Flat design style with no gradients or shadows
class AppColors {
  // Base colors from the palette
  static const Color background = Color(0xFFE8EAF6); // soft bluish-grey
  static const Color primary = Color(0xFFFF69B4);    // bright pink
  static const Color secondary = Color(0xFFFFD700);  // strong yellow
  static const Color accent1 = Color(0xFF00FFFF);    // cyan
  static const Color accent2 = Color(0xFFBA55D3);    // purple
  static const Color shape1 = Color(0xFF90EE90);     // light green
  static const Color shape2 = Color(0xFFFF6347);     // red-orange
  static const Color text = Color(0xFF222222);       // dark grey

  // Semantic color assignments for UI components
  static const Color gameBackground = background;
  static const Color mainButton = primary;
  static const Color secondaryButton = secondary;
  static const Color accentButton = accent1;
  static const Color cardBackground = Colors.white;
  static const Color successColor = shape1;
  static const Color errorColor = shape2;
  static const Color warningColor = secondary;
  static const Color infoColor = accent1;

  // Number tile colors (alternating for variety)
  static const List<Color> numberTileColors = [
    primary,     // bright pink
    secondary,   // yellow
    accent1,     // cyan
    accent2,     // purple
    shape1,      // light green
    shape2,      // red-orange
  ];

  // Ring colors for the game
  static const Color outerRing = accent2;     // purple
  static const Color innerRing = accent1;     // cyan
  static const Color ringHighlight = secondary; // yellow

  // Star rating colors
  static const Color starFilled = secondary;   // yellow
  static const Color starEmpty = Color(0xFFE0E0E0); // light grey

  // Navigation and UI
  static const Color navBarBackground = Colors.white;
  static const Color navBarSelected = primary;
  static const Color navBarUnselected = Color(0xFFBDBDBD);

  // Helper method to get number tile color by index
  static Color getNumberTileColor(int index) {
    return numberTileColors[index % numberTileColors.length];
  }

  // Helper method to get contrasting text color
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? text : Colors.white;
  }

  // Disabled state colors
  static Color get disabledColor => text.withValues(alpha: 0.3);
  static Color get disabledBackground => background.withValues(alpha: 0.5);
}

/// Button styles that follow the design guidelines
class AppButtonStyles {
  static const double borderRadius = 16.0;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets largePadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    padding: padding,
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.text,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    padding: padding,
  );

  static ButtonStyle accentButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent1,
    foregroundColor: AppColors.text,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    padding: padding,
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    padding: padding,
  );
}

/// Card and container styles
class AppContainerStyles {
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const EdgeInsets padding = EdgeInsets.all(16);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);

  static BoxDecoration gameCard = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
  );

  static BoxDecoration numberTile = BoxDecoration(
    borderRadius: BorderRadius.circular(smallBorderRadius),
    border: Border.all(color: Colors.white, width: 2),
  );

  static BoxDecoration ringContainer = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppColors.accent1.withValues(alpha: 0.3), width: 2),
  );
}