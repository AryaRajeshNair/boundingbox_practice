import 'package:flutter/material.dart';

class BoundingBox {
  final Offset topLeft;
  final Offset bottomRight;
  final String className;
  final int classId;
  final Color color;

  BoundingBox({
    required this.topLeft,
    required this.bottomRight,
    required this.className,
    required this.classId,
    required this.color,
  });

  
  YoloAnnotation toYolo(double imageWidth, double imageHeight) {
    final x1 = topLeft.dx;
    final y1 = topLeft.dy;
    final x2 = bottomRight.dx;
    final y2 = bottomRight.dy;

    final centerX = ((x1 + x2) / 2) / imageWidth;
    final centerY = ((y1 + y2) / 2) / imageHeight;
    final width = (x2 - x1) / imageWidth;
    final height = (y2 - y1) / imageHeight;

    return YoloAnnotation(
      classId: classId,
      centerX: centerX,
      centerY: centerY,
      width: width,
      height: height,
    );
  }
}

class YoloAnnotation {
  final int classId;
  final double centerX;
  final double centerY;
  final double width;
  final double height;

  YoloAnnotation({
    required this.classId,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
  });

  @override
  String toString() {
    return '$classId ${centerX.toStringAsFixed(6)} ${centerY.toStringAsFixed(6)} ${width.toStringAsFixed(6)} ${height.toStringAsFixed(6)}';
  }
}

class ObjectClass {
  final int id;
  final String name;
  final Color color;

  ObjectClass({
    required this.id,
    required this.name,
    required this.color,
  });
}
