import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme.dart';

/// Subtle dot grid with a soft lime glow, used behind the home and intro screens.
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key, required this.child, this.glowCenter = const Alignment(0, -.1)});

  final Widget child;
  final Alignment glowCenter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(glowCenter),
      isComplex: true,
      // Keeps animations in the content (power button) from repainting the grid every frame.
      child: RepaintBoundary(child: child),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.glowCenter);

  final Alignment glowCenter;

  static const _spacing = 22.0;
  static const _radius = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: glowCenter,
          radius: .8,
          colors: [SpriteNetColors.lime.withValues(alpha: .07), Colors.transparent],
        ).createShader(rect),
    );

    // Dots fade out towards the edges so the grid never competes with the content.
    final center = glowCenter.alongSize(size);
    final maxDistance = size.longestSide * .75;
    final paint = Paint();
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        final fade = 1 - ((Offset(x, y) - center).distance / maxDistance).clamp(0.0, 1.0);
        paint.color = Colors.white.withValues(alpha: .02 + .05 * fade);
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.glowCenter != glowCenter;
}
