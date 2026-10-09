import 'package:flutter/material.dart';

/// Solid Material 3 tonal surface used for cards, tiles and panels.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final AlignmentGeometry? alignment;

  /// Defaults to the theme's `surfaceContainerHigh`.
  final Color? color;

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}
