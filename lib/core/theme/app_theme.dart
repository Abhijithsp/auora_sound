import 'package:flutter/material.dart';
import 'glass_style.dart';
import 'theme_presets.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return generateTheme(AppThemePresets.presets[0], true);
  }

  static ThemeData get lightTheme {
    return generateTheme(AppThemePresets.presets[0], false);
  }

  /// Picks how the tonal palette is derived from the preset's seed colour.
  /// Coloured presets get a vibrant scheme; the greyscale ones stay neutral.
  static DynamicSchemeVariant _variantFor(AppThemePreset preset) {
    switch (preset.name) {
      case 'Ink Wash':
        return DynamicSchemeVariant.monochrome;
      case 'Monochrome Slate':
        return DynamicSchemeVariant.neutral;
      default:
        return DynamicSchemeVariant.vibrant;
    }
  }

  static ThemeData generateTheme(
    AppThemePreset preset,
    bool isDark, {
    GlassStyle glass = GlassStyle.disabled,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: preset.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      dynamicSchemeVariant: _variantFor(preset),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      extensions: [glass],
      scaffoldBackgroundColor: colorScheme.surface,
      primaryColor: colorScheme.primary,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        // Transparent in glass mode so the aurora shows behind the bar.
        backgroundColor: glass.enabled ? Colors.transparent : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        tileHeight: 56,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.secondaryContainer,
        thumbColor: colorScheme.primary,
        trackHeight: 6.0,
      ),
    );
  }
}
