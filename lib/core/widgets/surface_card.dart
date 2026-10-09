import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/glass_style.dart';
import 'frost_grain.dart';

/// Card, tile or panel surface. Solid Material 3 tonal colour by default,
/// frosted glass when the user enables it in settings.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final AlignmentGeometry? alignment;

  /// Defaults to the theme's `surfaceContainerHigh`; tints the glass in
  /// glass mode.
  final Color? color;

  /// Live backdrop blur. Expensive, so only for a few large floating
  /// surfaces (nav bar, mini player, sheets) — never for list items.
  final bool blur;

  const SurfaceCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.alignment,
    this.color,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = GlassStyle.of(context);
    final radius = borderRadius ?? BorderRadius.circular(24);
    final content = padding == null ? child : Padding(padding: padding!, child: child);

    Widget surface;
    if (!glass.enabled) {
      surface = Material(
        color: color ?? scheme.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    } else {
      surface = DecoratedBox(
        decoration: glass.decoration(scheme, radius, tint: color),
        child: CustomPaint(
          foregroundPainter: FrostGrainPainter(opacity: glass.grainOpacity),
          child: Material(type: MaterialType.transparency, child: content),
        ),
      );
      if (blur) {
        surface = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
          child: surface,
        );
      }
      surface = ClipRRect(borderRadius: radius, child: surface);
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      child: surface,
    );
  }
}
