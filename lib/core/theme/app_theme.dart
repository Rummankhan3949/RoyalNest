import 'package:flutter/material.dart';

/// App theme configuration for consistent styling
class AppTheme {
  AppTheme._();

  // Primary Colors
  static const Color royalBlue = Color(0xFF0050FF);
  static const Color lightBlue = Color(0xFFE8F0FF);
  static const Color backgroundColor = Color(0xFFF4F4F8);
  static const Color cardBackground = Colors.white;

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);

  // Text Colors
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color lightTextColor = Color(0xFF9E9E9E);

  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [royalBlue, Color(0xFF0040CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 18.0;
  static const double xlRadius = 24.0;

  // Padding & Margin
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double xlPadding = 32.0;

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
    color: primaryTextColor,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: primaryTextColor,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryTextColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: lightTextColor,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hint,
    String? label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: royalBlue)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: const BorderSide(color: royalBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: const BorderSide(color: errorColor),
      ),
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: royalBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(smallRadius),
    ),
    elevation: 2,
  );

  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: royalBlue,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    side: const BorderSide(color: royalBlue),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(smallRadius),
    ),
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(mediumRadius),
    boxShadow: cardShadow,
  );

  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: royalBlue,
      scaffoldBackgroundColor: backgroundColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: royalBlue,
        primary: royalBlue,
        secondary: royalBlue,
        surface: backgroundColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: secondaryTextColor),
        hintStyle: const TextStyle(color: lightTextColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: const BorderSide(color: royalBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: buttonText,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _RoyalNestPageTransitionsBuilder(),
          TargetPlatform.iOS: _RoyalNestPageTransitionsBuilder(),
          TargetPlatform.linux: _RoyalNestPageTransitionsBuilder(),
          TargetPlatform.macOS: _RoyalNestPageTransitionsBuilder(),
          TargetPlatform.windows: _RoyalNestPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _RoyalNestPageTransitionsBuilder extends PageTransitionsBuilder {
  const _RoyalNestPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0.03, 0.02),
      end: Offset.zero,
    ).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
