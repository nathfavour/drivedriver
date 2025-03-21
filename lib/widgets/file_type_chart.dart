import 'package:flutter/material.dart';
import 'dart:math' as math;

class FileTypeChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;

  const FileTypeChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: PieChartPainter(data),
        );
      },
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<int>(0, (sum, item) => sum + item.value);

    // Define the circle's properties
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Colors for the chart segments
    final List<Color> colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.amber.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.orange.shade400,
      Colors.indigo.shade400,
      Colors.brown.shade400,
    ];

    // Draw segments
    double startAngle = 0;
    final legendItems = <LegendItem>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi;
      final color = colors[i % colors.length];

      // Draw the pie segment
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw segment border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

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
      color: Colors.black87,
      fontSize: 12,
    );
    final valueStyle = TextStyle(
      color: Colors.black54,
      fontSize: 10,
    );

    final legendWidth = size.width * 0.9;
    final itemHeight = 25.0;
    final startY = size.height - (items.length * itemHeight) - 20;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final y = startY + (i * itemHeight);

      // Draw color box
      final boxPaint = Paint()..color = item.color;
      final boxRect = Rect.fromLTWH(10, y, 15, 15);
      canvas.drawRect(boxRect, boxPaint);

      // Draw label
      final labelSpan = TextSpan(text: item.label, style: textStyle);
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(35, y));

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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
