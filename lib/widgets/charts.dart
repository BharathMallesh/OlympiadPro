import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Tiny inline trend sparkline.
class Sparkline extends StatelessWidget {
  const Sparkline(this.points,
      {super.key, this.color = AppColors.primary, this.height = 32, this.width = 90});
  final List<double> points;
  final Color color;
  final double height;
  final double width;
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, height),
        painter: _SparkPainter(points, color),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color);
  final List<double> points;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxV = points.reduce(math.max);
    final minV = points.reduce(math.min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;
    final dx = size.width / (points.length - 1);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - ((points[i] - minV) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Smooth area chart for score trends.
class AreaChart extends StatelessWidget {
  const AreaChart(this.points,
      {super.key, this.color = AppColors.primary, this.height = 180});
  final List<double> points;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _AreaPainter(points, color)),
      );
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.points, this.color);
  final List<double> points;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    // gridlines
    final grid = Paint()..color = AppColors.outline..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.length < 2) return;
    final maxV = points.reduce(math.max);
    final minV = points.reduce(math.min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;
    final dx = size.width / (points.length - 1);
    Offset at(int i) => Offset(
        dx * i, size.height - ((points[i] - minV) / range) * size.height * 0.85 - 8);

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = at(i - 1), p1 = at(i);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      line.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      line.lineTo(p1.dx, p1.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Donut / time-distribution chart.
class DonutChart extends StatelessWidget {
  const DonutChart(this.segments, {super.key, this.size = 150, this.center});
  final List<(double, Color)> segments; // (fraction, color)
  final double size;
  final Widget? center;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size.square(size), painter: _DonutPainter(segments)),
          ?center,
        ]),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);
  final List<(double, Color)> segments;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.16;
    var start = -math.pi / 2;
    for (final (frac, color) in segments) {
      final sweep = frac * 2 * math.pi;
      canvas.drawArc(
        rect.deflate(stroke / 2),
        start,
        sweep - 0.05,
        false,
        Paint()
          ..color = color
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Radar / subject-mastery polygon.
class RadarChart extends StatelessWidget {
  const RadarChart(this.values, this.labels,
      {super.key, this.size = 220, this.color = AppColors.primary});
  final List<double> values; // 0..1
  final List<String> labels;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RadarPainter(values, labels, color)),
      );
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.values, this.labels, this.color);
  final List<double> values;
  final List<String> labels;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 * 0.7;
    final n = values.length;
    final grid = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 3; ring++) {
      final p = Path();
      for (var i = 0; i <= n; i++) {
        final a = -math.pi / 2 + 2 * math.pi * (i % n) / n;
        final r = radius * ring / 3;
        final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(p, grid);
    }
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      canvas.drawLine(center,
          center + Offset(math.cos(a) * radius, math.sin(a) * radius), grid);
    }

    final shape = Path();
    for (var i = 0; i <= n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * (i % n) / n;
      final r = radius * values[i % n];
      final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? shape.moveTo(pt.dx, pt.dy) : shape.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(shape, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawPath(
        shape,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final pt = center + Offset(math.cos(a) * (radius + 16), math.sin(a) * (radius + 16));
      tp.text = TextSpan(
          text: labels[i],
          style: const TextStyle(color: AppColors.muted, fontSize: 10));
      tp.layout();
      tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
