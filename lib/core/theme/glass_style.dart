import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// User-controlled frosted glass appearance, carried on the theme so every
/// surface (cards, nav bar, sheets, background) reads the same values.
///
/// All tints are derived from the active [ColorScheme], so the glass follows
/// the selected preset in both dark and light mode.
class GlassStyle extends ThemeExtension<GlassStyle> {
  final bool enabled;

  /// 0.0 = barely frosted, 1.0 = full glass.
  final double intensity;
  final bool animatedBackground;

  const GlassStyle({
    required this.enabled,
    required this.intensity,
    required this.animatedBackground,
  });

  static const disabled = GlassStyle(
    enabled: false,
    intensity: 0,
    animatedBackground: false,
  );

  static GlassStyle of(BuildContext context) =>
      Theme.of(context).extension<GlassStyle>() ?? disabled;

  double get blurSigma => 8 + 22 * intensity;

  /// Frosted fill. Light mode stays more opaque so content keeps contrast.
  Color fill(ColorScheme scheme, {Color? tint}) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = tint ??
        (isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLowest);
    final alpha = isDark ? 0.75 - 0.45 * intensity : 0.85 - 0.30 * intensity;
    return base.withValues(alpha: alpha);
  }

  /// Highlight blended into the top-left corner of a frosted panel.
  Color sheen(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return Colors.white.withValues(
      alpha: isDark ? 0.04 + 0.08 * intensity : 0.25 + 0.35 * intensity,
    );
  }

  Color border(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.06 + 0.12 * intensity)
        : scheme.outlineVariant.withValues(alpha: 0.6 + 0.3 * intensity);
  }

  /// Opacity of the frost grain texture drawn over panels.
  double get grainOpacity => 0.02 + 0.04 * intensity;

  BoxDecoration decoration(
    ColorScheme scheme,
    BorderRadius radius, {
    Color? tint,
  }) {
    final base = fill(scheme, tint: tint);
    return BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.alphaBlend(sheen(scheme), base), base],
      ),
      border: Border.all(color: border(scheme)),
    );
  }

  @override
  GlassStyle copyWith({
    bool? enabled,
    double? intensity,
    bool? animatedBackground,
  }) {
    return GlassStyle(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      animatedBackground: animatedBackground ?? this.animatedBackground,
    );
  }

  @override
  GlassStyle lerp(covariant GlassStyle? other, double t) {
    if (other == null) return this;
    return GlassStyle(
      enabled: t < 0.5 ? enabled : other.enabled,
      intensity: lerpDouble(intensity, other.intensity, t) ?? other.intensity,
      animatedBackground: t < 0.5 ? animatedBackground : other.animatedBackground,
    );
  }
}
