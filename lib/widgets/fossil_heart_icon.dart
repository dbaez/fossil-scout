import 'package:flutter/material.dart';

/// Icono de corazón con estilo fósil para la animación de like
class FossilHeartIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FossilHeartIcon({
    super.key,
    this.size = 80.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: FossilHeartPainter(color: color),
    );
  }
}

class FossilHeartPainter extends CustomPainter {
  final Color color;

  FossilHeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.7;

    // Dibujar corazón con estilo fósil (con textura y líneas)
    final path = Path();
    
    // Parte superior izquierda del corazón
    path.moveTo(center.dx, center.dy + radius * 0.3);
    path.cubicTo(
      center.dx - radius * 0.3,
      center.dy + radius * 0.1,
      center.dx - radius * 0.6,
      center.dy - radius * 0.2,
      center.dx - radius * 0.4,
      center.dy - radius * 0.5,
    );
    path.cubicTo(
      center.dx - radius * 0.2,
      center.dy - radius * 0.7,
      center.dx,
      center.dy - radius * 0.6,
      center.dx,
      center.dy - radius * 0.4,
    );
    
    // Parte superior derecha del corazón
    path.cubicTo(
      center.dx,
      center.dy - radius * 0.6,
      center.dx + radius * 0.2,
      center.dy - radius * 0.7,
      center.dx + radius * 0.4,
      center.dy - radius * 0.5,
    );
    path.cubicTo(
      center.dx + radius * 0.6,
      center.dy - radius * 0.2,
      center.dx + radius * 0.3,
      center.dy + radius * 0.1,
      center.dx,
      center.dy + radius * 0.3,
    );
    
    path.close();
    
    // Dibujar el corazón principal
    canvas.drawPath(path, paint);
    
    // Agregar líneas de textura fósil (grietas/segmentos)
    final texturePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;

    // Líneas verticales de textura
    for (int i = 0; i < 3; i++) {
      final offset = (i - 1) * radius * 0.2;
      canvas.drawLine(
        Offset(center.dx + offset, center.dy - radius * 0.3),
        Offset(center.dx + offset, center.dy + radius * 0.1),
        texturePaint,
      );
    }
    
    // Líneas horizontales de textura
    for (int i = 0; i < 2; i++) {
      final offset = i * radius * 0.3 - radius * 0.15;
      canvas.drawLine(
        Offset(center.dx - radius * 0.3, center.dy + offset),
        Offset(center.dx + radius * 0.3, center.dy + offset),
        texturePaint,
      );
    }
    
    // Borde exterior con estilo fósil
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
