import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class FileTypeChart extends StatefulWidget {
  final List<MapEntry<String, int>> data;

  const FileTypeChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<FileTypeChart> createState() => _FileTypeChartState();
}

class _FileTypeChartState extends State<FileTypeChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: PieChartPainter(context, widget.data, _animation.value),
            );
          },
        );
      },
    );
  }
}

class PieChartPainter extends CustomPainter {
  final BuildContext context;
  final List<MapEntry<String, int>> data;
  final double animationValue;

  PieChartPainter(this.context, this.data, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<int>(0, (sum, item) => sum + item.value);

    // Define the circle's properties
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.80;

    // Add a subtle shadow for 3D effect
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.2), 6, true);

    // Draw an inner circle to give depth (3D effect)
    final innerCircle = Paint()
      ..color = Theme.of(this.context).cardColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.95, innerCircle);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Colors for the chart segments - more vibrant and varied
    final List<Color> colors = [
      const Color(0xFF5E35B1), // deep purple
      const Color(0xFF1E88E5), // blue
      const Color(0xFF43A047), // green
      const Color(0xFFFFB300), // amber
      const Color(0xFFE53935), // red
      const Color(0xFF00ACC1), // cyan
      const Color(0xFFEC407A), // pink
      const Color(0xFFFF7043), // deep orange
      const Color(0xFF3949AB), // indigo
      const Color(0xFF8D6E63), // brown
    ];

    // Draw segments
    double startAngle = 0;
    final legendItems = <LegendItem>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi * animationValue;
      final color = colors[i % colors.length];

      // Draw the pie segment
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw segment border with slightly thicker white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      // Add 3D effect with shadow
      if (sweepAngle > 0.2) {
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawArc(
          Rect.fromCircle(center: center.translate(1, 2), radius: radius),
          startAngle,
          sweepAngle,
          true,
          shadowPaint,
        );
      }

      // Calculate angle for the label
      final labelAngle = startAngle + sweepAngle / 2;

      // Save for legend
      legendItems.add(
        LegendItem(
          color: color,
          label: item.key.isEmpty ? 'No extension' : '.${item.key}',
          value: item.value,
          percent: (item.value / total * 100).toStringAsFixed(1) + '%',
        ),
      );

      startAngle += sweepAngle;
    }

    // Draw the legend
    _drawLegend(canvas, size, legendItems);
  }

  void _drawLegend(Canvas canvas, Size size, List<LegendItem> items) {
    final textStyle = TextStyle(
      color: Theme.of(this.context).colorScheme.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final valueStyle = TextStyle(
      color: Theme.of(this.context).colorScheme.onSurface.withOpacity(0.7),
      fontSize: 11,
    );

    final legendWidth = size.width * 0.9;
    final itemHeight = 25.0;
    final startY = size.height - (items.length * itemHeight) - 20;

    // Draw legend background
    final bgRect = Rect.fromLTWH(
      5,
      startY - 10,
      size.width - 10,
      (items.length * itemHeight) + 20,
    );

    final rrect = RRect.fromRectAndRadius(
      bgRect,
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = Theme.of(this.context).cardColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, bgPaint);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final y = startY + (i * itemHeight);

      // Draw color box with rounded corners
      final boxPaint = Paint()..color = item.color;
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(15, y, 15, 15),
        const Radius.circular(3),
      );
      canvas.drawRRect(boxRect, boxPaint);

      // Draw label
      final labelSpan = TextSpan(text: item.label, style: textStyle);
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(40, y));

      // Draw value and percentage
      final valueSpan = TextSpan(
        text: '${item.value} (${item.percent})',
        style: valueStyle,
      );
      final valuePainter = TextPainter(
        text: valueSpan,
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(
        canvas,
        Offset(legendWidth - valuePainter.width - 10, y),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data;
  }
}

class LegendItem {
  final Color color;
  final String label;
  final int value;
  final String percent;

  LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });
}
