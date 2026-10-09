import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/glass_style.dart';

/// Screen background. Plain surface colour in Material mode; soft colour
/// glows behind the frosted panels in glass mode, optionally drifting.
class AuroraBackground extends StatefulWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  // The glow drifts slowly, so ~20 fps looks identical to 60 fps while
  // sparing the blurred panels above it from re-filtering every frame.
  late final _ThrottledAnimation _throttled = _ThrottledAnimation(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final glass = GlassStyle.of(context);
    // Respect the system "remove animations" accessibility setting.
    final animate = glass.enabled &&
        glass.animatedBackground &&
        !MediaQuery.of(context).disableAnimations;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _throttled.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = GlassStyle.of(context);

    // Same tree shape in both modes so toggling glass keeps page state.
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        RepaintBoundary(
          child: glass.enabled
              ? CustomPaint(
                  painter: _AuroraPainter(
                    animation: _throttled,
                    scheme: scheme,
                    intensity: glass.intensity,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        widget.child,
      ],
    );
  }
}

class _ThrottledAnimation extends ChangeNotifier implements ValueListenable<double> {
  static const _interval = Duration(milliseconds: 50);

  final AnimationController _source;
  Duration _lastNotified = Duration.zero;

  _ThrottledAnimation(this._source) {
    _source.addListener(_onTick);
  }

  void _onTick() {
    final elapsed = _source.lastElapsedDuration ?? Duration.zero;
    if (elapsed < _lastNotified || elapsed - _lastNotified >= _interval) {
      _lastNotified = elapsed;
      notifyListeners();
    }
  }

  @override
  double get value => _source.value;

  @override
  void dispose() {
    _source.removeListener(_onTick);
    super.dispose();
  }
}

class _AuroraPainter extends CustomPainter {
  final ValueListenable<double> animation;
  final ColorScheme scheme;
  final double intensity;

  _AuroraPainter({
    required this.animation,
    required this.scheme,
    required this.intensity,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = scheme.brightness == Brightness.dark;
    final strength = 0.4 + 0.6 * intensity;
    // Dark mode glows with the bright accent tones; light mode uses the
    // pastel container tones so the background stays airy, not muddy.
    final orbs = isDark
        ? [
            (scheme.primary, 0.32),
            (scheme.secondary, 0.26),
            (scheme.tertiary, 0.22),
          ]
        : [
            (scheme.primaryContainer, 0.85),
            (scheme.secondaryContainer, 0.75),
            (scheme.tertiaryContainer, 0.65),
          ];

    final progress = animation.value;
    final shortest = math.min(size.width, size.height);
    final centers = [
      Offset(
        size.width * 0.3 + math.sin(progress * 2 * math.pi) * size.width * 0.15,
        size.height * 0.25 + math.cos(progress * 2 * math.pi) * size.height * 0.1,
      ),
      Offset(
        size.width * 0.7 + math.cos((progress + 0.33) * 2 * math.pi) * size.width * 0.2,
        size.height * 0.65 + math.sin((progress + 0.33) * 2 * math.pi) * size.height * 0.15,
      ),
      Offset(
        size.width * 0.45 + math.sin((progress + 0.66) * 2 * math.pi) * size.width * 0.25,
        size.height * 0.85 + math.cos((progress + 0.66) * 2 * math.pi) * size.height * 0.1,
      ),
    ];
    final radii = [shortest * 0.65, shortest * 0.6, shortest * 0.7];

    for (var i = 0; i < orbs.length; i++) {
      final (color, opacity) = orbs[i];
      final rect = Rect.fromCircle(center: centers[i], radius: radii[i]);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity * strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawCircle(centers[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.scheme != scheme || oldDelegate.intensity != intensity;
}
