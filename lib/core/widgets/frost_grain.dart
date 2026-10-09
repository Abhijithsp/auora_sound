import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints a fine, tiled noise texture that gives glass panels a frosted grain.
///
/// The 96x96 tile is generated once and shared, so each panel costs a single
/// shader-filled rect.
class FrostGrainPainter extends CustomPainter {
  final double opacity;

  FrostGrainPainter({required this.opacity});

  static ui.Image? _tile;

  static ui.Image get _grainTile {
    return _tile ??= () {
      const size = 96;
      final random = math.Random(7);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final light = <Offset>[];
      final dark = <Offset>[];
      for (var i = 0; i < size * size ~/ 3; i++) {
        final point = Offset(
          random.nextInt(size).toDouble(),
          random.nextInt(size).toDouble(),
        );
        (random.nextBool() ? light : dark).add(point);
      }
      canvas.drawPoints(
        ui.PointMode.points,
        light,
        Paint()..color = Colors.white,
      );
      canvas.drawPoints(
        ui.PointMode.points,
        dark,
        Paint()..color = Colors.black,
      );
      return recorder.endRecording().toImageSync(size, size);
    }();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..shader = ImageShader(
        _grainTile,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..color = Colors.white.withValues(alpha: opacity);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant FrostGrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
