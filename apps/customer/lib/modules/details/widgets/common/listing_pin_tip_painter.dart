// lib/features/listing/widgets/common/listing_pin_tip_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ListingPinTipPainter extends CustomPainter {
  final Color color;
  const ListingPinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ListingPinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}
