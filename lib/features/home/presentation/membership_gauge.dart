import 'dart:math';

import 'package:material_ui/material_ui.dart';

/// A ring of rounded segments over the top of a circle, filled from the
/// left for the share of the plan that is left, with [child] in the middle.
class MembershipGauge extends StatelessWidget {
  const MembershipGauge({super.key, required this.share, required this.color, required this.child});

  /// 0 to 1.
  final double share;
  final Color color;
  final Widget child;

  static const segments = 12;
  static const emptyColor = Color(0xFFE6E0D8);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = min(constraints.maxWidth, 340.0);
      final geometry = _GaugeGeometry(width);
      return Center(
        child: SizedBox(
          width: width,
          height: geometry.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, animated, _) => CustomPaint(
                    painter: _GaugePainter(geometry: geometry, share: animated, filled: color),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: geometry.center.dy - geometry.radius * 0.62,
                child: child,
              ),
            ],
          ),
        ),
      );
    },
  );
}

final class _GaugeGeometry {
  _GaugeGeometry(this.width)
    : radius = width * 0.37,
      segmentLength = width * 0.135,
      segmentThickness = width * 0.118;

  final double width;
  final double radius;

  /// Along the radius.
  final double segmentLength;

  /// Across it.
  final double segmentThickness;

  /// From lower left, over the top, to lower right.
  static const startAngle = pi * 160 / 180;
  static const sweep = pi * 220 / 180;

  Offset get center => Offset(width / 2, radius + segmentLength * 0.62);

  double get height => center.dy + radius * sin(pi * 20 / 180) + segmentLength * 0.75;
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.geometry, required this.share, required this.filled});

  final _GaugeGeometry geometry;
  final double share;
  final Color filled;

  @override
  void paint(Canvas canvas, Size size) {
    const count = MembershipGauge.segments;
    final lit = share <= 0 ? 0 : max(1, (share * count).round());
    final segment = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: geometry.segmentThickness, height: geometry.segmentLength),
      Radius.circular(geometry.segmentThickness * 0.32),
    );
    for (var i = 0; i < count; i++) {
      final angle = _GaugeGeometry.startAngle + _GaugeGeometry.sweep * i / (count - 1);
      canvas
        ..save()
        ..translate(
          geometry.center.dx + geometry.radius * cos(angle),
          geometry.center.dy + geometry.radius * sin(angle),
        )
        ..rotate(angle + pi / 2)
        ..drawRRect(segment, Paint()..color = i < lit ? filled : MembershipGauge.emptyColor)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.share != share || old.filled != filled || old.geometry.width != geometry.width;
}
