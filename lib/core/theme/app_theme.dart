import 'package:flutter/material.dart';
import 'theme_presets.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return generateTheme(AppThemePresets.presets[0], true);
  }

  static ThemeData get lightTheme {
    return generateTheme(AppThemePresets.presets[0], false);
  }

  static ThemeData generateTheme(AppThemePreset preset, bool isDark) {
    final primaryColor = preset.primary;
    final secondaryColor = preset.secondary;
    final accentColor = preset.accent;
    final surfaceColor = isDark ? preset.backgroundDark : preset.backgroundLight;
    final cardColor = isDark ? preset.cardDark : preset.cardLight;

    // Lighter surfaces for elevated containers (M3 containers)
    final double cardBrightnessOffset = isDark ? 0.05 : -0.04;
    Color adjustColorBrightness(Color base, double factor) {
      final hsv = HSVColor.fromColor(base);
      final double newV = (hsv.value + factor).clamp(0.0, 1.0);
      return hsv.withValue(newV).toColor();
    }
    
    final containerHigh = adjustColorBrightness(cardColor, cardBrightnessOffset);
    final containerHighest = adjustColorBrightness(cardColor, cardBrightnessOffset * 2);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primaryColor,
            primaryContainer: primaryColor.withValues(alpha: 0.25),
            secondary: secondaryColor,
            secondaryContainer: secondaryColor.withValues(alpha: 0.15),
            tertiary: accentColor,
            tertiaryContainer: accentColor.withValues(alpha: 0.2),
            surface: surfaceColor,
            surfaceContainer: cardColor,
            surfaceContainerHigh: containerHigh,
            surfaceContainerHighest: containerHighest,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: const Color(0xFFE5E1E4),
            onSurfaceVariant: const Color(0xFFCAC3D8),
            outline: const Color(0xFF948EA1),
            outlineVariant: const Color(0xFF494455),
          )
        : ColorScheme.light(
            primary: primaryColor,
            primaryContainer: primaryColor.withValues(alpha: 0.15),
            secondary: secondaryColor,
            secondaryContainer: secondaryColor.withValues(alpha: 0.1),
            tertiary: accentColor,
            tertiaryContainer: accentColor.withValues(alpha: 0.15),
            surface: surfaceColor,
            surfaceContainer: cardColor,
            surfaceContainerHigh: containerHigh,
            surfaceContainerHighest: containerHighest,
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
      primaryColor: primaryColor,
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
        activeTrackColor: primaryColor,
        inactiveTrackColor: colorScheme.outlineVariant,
        thumbColor: primaryColor,
        trackHeight: 4.0,
      ),
    );
  }
}

