import 'package:flutter/material.dart';

/// Icono personalizado que combina una brújula con un ammonites
class FossilCompassIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FossilCompassIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: FossilCompassPainter(color: color),
      ),
    );
  }
}

class FossilCompassPainter extends CustomPainter {
  final Color color;

  FossilCompassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;

    // Dibujar el ammonites (espiral) en el centro
    _drawAmmonites(canvas, center, radius * 0.6, paint, fillPaint);

    // Dibujar la brújula alrededor
    _drawCompass(canvas, center, radius, paint);
  }

  void _drawAmmonites(Canvas canvas, Offset center, double radius, Paint paint, Paint fillPaint) {
    // Dibujar espiral de ammonites (espiral logarítmica)
    final path = Path();
    final turns = 2.5;
    final segments = 80;
    
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = t * turns * 2 * 3.14159;
      // Espiral logarítmica que crece desde el centro
      final spiralRadius = radius * 0.15 * (1 + t * 4);
      
      final x = center.dx + spiralRadius * (1 + t * 0.3) * (i % 2 == 0 ? 1 : -1) * 0.6;
      final y = center.dy + spiralRadius * (1 + t * 0.3) * (i % 2 == 0 ? 1 : -1) * 0.6;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Dibujar las cámaras del ammonites (líneas radiales)
    final dividerPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth * 0.4;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * 3.14159;
      final startRadius = radius * 0.2;
      final endRadius = radius * 0.7;
      
      final startX = center.dx + startRadius * (1 + 0.2 * (i / 8)) * (i % 2 == 0 ? 1 : -1) * 0.5;
      final startY = center.dy + startRadius * (1 + 0.2 * (i / 8)) * (i % 2 == 0 ? 1 : -1) * 0.5;
      final endX = center.dx + endRadius * (1 + 0.3 * (i / 8)) * (i % 2 == 0 ? 1 : -1) * 0.6;
      final endY = center.dy + endRadius * (1 + 0.3 * (i / 8)) * (i % 2 == 0 ? 1 : -1) * 0.6;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        dividerPaint,
      );
    }
    
    // Dibujar centro del ammonites (cámara inicial)
    canvas.drawCircle(center, radius * 0.12, fillPaint);
    canvas.drawCircle(center, radius * 0.12, paint);
  }

  void _drawCompass(Canvas canvas, Offset center, double radius, Paint paint) {
    // Círculo exterior de la brújula
    canvas.drawCircle(center, radius, paint);
    
    // Círculo interior
    canvas.drawCircle(center, radius * 0.7, paint);
    
    // Dibujar los puntos cardinales
    final cardinalSize = radius * 0.15;
    final cardinalPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Norte (arriba)
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.85),
      cardinalSize,
      cardinalPaint,
    );
    
    // Sur (abajo)
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.85),
      cardinalSize * 0.7,
      cardinalPaint,
    );
    
    // Este (derecha)
    canvas.drawCircle(
      Offset(center.dx + radius * 0.85, center.dy),
      cardinalSize * 0.7,
      cardinalPaint,
    );
    
    // Oeste (izquierda)
    canvas.drawCircle(
      Offset(center.dx - radius * 0.85, center.dy),
      cardinalSize * 0.7,
      cardinalPaint,
    );
    
    // Líneas de dirección
    final linePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth * 0.5;
    
    // Línea vertical (N-S)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.6),
      Offset(center.dx, center.dy + radius * 0.6),
      linePaint,
    );
    
    // Línea horizontal (E-W)
    canvas.drawLine(
      Offset(center.dx - radius * 0.6, center.dy),
      Offset(center.dx + radius * 0.6, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
