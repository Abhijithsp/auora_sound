import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return generateTheme(const Color(0xFF7C4DFF), true);
  }

  static ThemeData get lightTheme {
    return generateTheme(const Color(0xFF7C4DFF), false);
  }

  static ThemeData generateTheme(Color accentColor, bool isDark) {
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: accentColor,
            primaryContainer: accentColor.withValues(alpha: 0.3),
            secondary: accentColor.withValues(alpha: 0.7),
            secondaryContainer: accentColor.withValues(alpha: 0.2),
            tertiary: const Color(0xFFFF4B7D),
            tertiaryContainer: const Color(0xFFFF4D7E),
            surface: const Color(0xFF131315),
            surfaceContainer: const Color(0xFF201F21),
            surfaceContainerHigh: const Color(0xFF2A2A2C),
            surfaceContainerHighest: const Color(0xFF353437),
            onPrimary: isDark ? Colors.black : Colors.white,
            onSecondary: isDark ? Colors.black : Colors.white,
            onSurface: const Color(0xFFE5E1E4),
            onSurfaceVariant: const Color(0xFFCAC3D8),
            outline: const Color(0xFF948EA1),
            outlineVariant: const Color(0xFF494455),
          )
        : ColorScheme.light(
            primary: accentColor,
            primaryContainer: accentColor.withValues(alpha: 0.2),
            secondary: accentColor.withValues(alpha: 0.7),
            secondaryContainer: accentColor.withValues(alpha: 0.1),
            tertiary: const Color(0xFFFF4B7D),
            tertiaryContainer: const Color(0xFFFF4D7E),
            surface: const Color(0xFFF5F5F7),
            surfaceContainer: const Color(0xFFEAEAEF),
            surfaceContainerHigh: const Color(0xFFDFDFE5),
            surfaceContainerHighest: const Color(0xFFD4D4DC),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF1C1B1F),
            onSurfaceVariant: const Color(0xFF49454F),
            outline: const Color(0xFF79747E),
            outlineVariant: const Color(0xFFCAC4D0),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent, // Allow glowing/scaffold background to show through
      primaryColor: accentColor,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          fontFamily: 'Inter',
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: colorScheme.outlineVariant,
        thumbColor: accentColor,
        trackHeight: 4.0,
      ),
    );
  }
}
