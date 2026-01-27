import 'package:flutter/material.dart';
import '../models/boundingbox_logic.dart';

class AnnotationPainter extends CustomPainter {
  final List<BoundingBox> boxes;
  final Offset? currentStart;
  final Offset? currentEnd;
  final Color currentBoxColor;

  AnnotationPainter({
    required this.boxes,
    this.currentStart,
    this.currentEnd,
    required this.currentBoxColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    
    for (var box in boxes) {
      _drawBox(canvas, box);
    }

    
    if (currentStart != null && currentEnd != null) {
      _drawBox(
        canvas,
        BoundingBox(
          topLeft: Offset(
            currentStart!.dx < currentEnd!.dx ? currentStart!.dx : currentEnd!.dx,
            currentStart!.dy < currentEnd!.dy ? currentStart!.dy : currentEnd!.dy,
          ),
          bottomRight: Offset(
            currentStart!.dx > currentEnd!.dx ? currentStart!.dx : currentEnd!.dx,
            currentStart!.dy > currentEnd!.dy ? currentStart!.dy : currentEnd!.dy,
          ),
          className: 'preview',
          classId: -1,
          color: currentBoxColor.withValues(alpha: 0.5),
        ),
      );
    }
  }

  void _drawBox(Canvas canvas, BoundingBox box) {
    final paint = Paint()
      ..color = box.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw rectangle
    canvas.drawRect(
      Rect.fromLTRB(
        box.topLeft.dx,
        box.topLeft.dy,
        box.bottomRight.dx,
        box.bottomRight.dy,
      ),
      paint,
    );

    // Draw label background
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${box.className}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelPaint = Paint()
      ..color = box.color
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        box.topLeft.dx,
        box.topLeft.dy - textPainter.height - 4,
        textPainter.width + 4,
        textPainter.height + 2,
      ),
      labelPaint,
    );

    textPainter.paint(canvas, box.topLeft + Offset(2, -textPainter.height - 2));
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.boxes != boxes ||
        oldDelegate.currentStart != currentStart ||
        oldDelegate.currentEnd != currentEnd;
  }
}
