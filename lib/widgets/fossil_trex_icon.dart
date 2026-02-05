import 'package:flutter/material.dart';

/// Icono de cabeza de tiranosaurio con estilo fósil para la animación de like
class FossilTrexIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FossilTrexIcon({
    super.key,
    this.size = 80.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: FossilTrexPainter(color: color),
    );
  }
}

class FossilTrexPainter extends CustomPainter {
  final Color color;

  FossilTrexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Color del cráneo (blanco/beige claro como hueso envejecido)
    final skullPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Contorno negro grueso (estilo cartoon/vectorial)
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Color gris oscuro para ojos, nariz y dientes
    final darkPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200.0;

    // Path del cráneo (vista lateral, mirando hacia la derecha)
    // Forma más simple y estilizada como en la imagen
    final skullPath = Path();
    
    // Punto de inicio: punta del hocico (parte delantera inferior)
    skullPath.moveTo(center.dx - 70 * scale, center.dy + 5 * scale);
    
    // Hocico inferior (curva hacia arriba)
    skullPath.quadraticBezierTo(
      center.dx - 65 * scale, center.dy - 5 * scale,
      center.dx - 55 * scale, center.dy - 15 * scale,
    );
    
    // Parte delantera del hocico (subiendo)
    skullPath.quadraticBezierTo(
      center.dx - 50 * scale, center.dy - 25 * scale,
      center.dx - 45 * scale, center.dy - 30 * scale,
    );
    
    // Parte superior del cráneo (curva hacia atrás)
    skullPath.quadraticBezierTo(
      center.dx - 30 * scale, center.dy - 42 * scale,
      center.dx - 10 * scale, center.dy - 48 * scale,
    );
    
    skullPath.quadraticBezierTo(
      center.dx + 10 * scale, center.dy - 50 * scale,
      center.dx + 30 * scale, center.dy - 45 * scale,
    );
    
    // Parte posterior del cráneo (curva hacia abajo)
    skullPath.quadraticBezierTo(
      center.dx + 50 * scale, center.dy - 35 * scale,
      center.dx + 60 * scale, center.dy - 20 * scale,
    );
    
    // Parte posterior inferior (bajando)
    skullPath.quadraticBezierTo(
      center.dx + 58 * scale, center.dy - 5 * scale,
      center.dx + 50 * scale, center.dy + 10 * scale,
    );
    
    // Mandíbula inferior (curva hacia adelante)
    skullPath.quadraticBezierTo(
      center.dx + 40 * scale, center.dy + 25 * scale,
      center.dx + 25 * scale, center.dy + 32 * scale,
    );
    
    skullPath.quadraticBezierTo(
      center.dx + 5 * scale, center.dy + 35 * scale,
      center.dx - 15 * scale, center.dy + 32 * scale,
    );
    
    // Parte delantera de la mandíbula (subiendo hacia el hocico)
    skullPath.quadraticBezierTo(
      center.dx - 35 * scale, center.dy + 28 * scale,
      center.dx - 55 * scale, center.dy + 18 * scale,
    );
    
    skullPath.quadraticBezierTo(
      center.dx - 65 * scale, center.dy + 10 * scale,
      center.dx - 70 * scale, center.dy + 5 * scale,
    );
    
    skullPath.close();
    
    // Dibujar el cráneo principal
    canvas.drawPath(skullPath, skullPaint);
    
    // Dibujar contorno negro grueso
    canvas.drawPath(skullPath, strokePaint);
    
    // Dibujar dos órbitas oculares grandes y ovaladas (características del T-Rex)
    final eyePaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    
    final eyeStrokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03;
    
    // Órbita ocular 1 (más grande, en la parte superior)
    final eye1Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + 15 * scale, center.dy - 20 * scale),
        width: 28 * scale,
        height: 22 * scale,
      ),
      Radius.circular(11 * scale),
    );
    canvas.drawRRect(eye1Rect, eyePaint);
    canvas.drawRRect(eye1Rect, eyeStrokePaint);
    
    // Órbita ocular 2 (más pequeña, ligeramente más abajo)
    final eye2Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + 25 * scale, center.dy - 10 * scale),
        width: 22 * scale,
        height: 18 * scale,
      ),
      Radius.circular(9 * scale),
    );
    canvas.drawRRect(eye2Rect, eyePaint);
    canvas.drawRRect(eye2Rect, eyeStrokePaint);
    
    // Dibujar la nariz (pequeña abertura ovalada en el frente del hocico)
    final nostrilRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - 50 * scale, center.dy - 20 * scale),
        width: 12 * scale,
        height: 8 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(nostrilRect, eyePaint);
    canvas.drawRRect(nostrilRect, eyeStrokePaint);
    
    // Dibujar dientes triangulares (numerosos y puntiagudos)
    final toothPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    
    final toothStrokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015;
    
    // Dientes superiores (más grandes, curvados hacia abajo)
    for (int i = 0; i < 8; i++) {
      final offset = (i - 3.5) * 15 * scale;
      final toothPath = Path();
      toothPath.moveTo(center.dx + offset, center.dy - 8 * scale);
      toothPath.lineTo(center.dx + offset - 3.5 * scale, center.dy + 8 * scale);
      toothPath.lineTo(center.dx + offset + 3.5 * scale, center.dy + 8 * scale);
      toothPath.close();
      canvas.drawPath(toothPath, toothPaint);
      canvas.drawPath(toothPath, toothStrokePaint);
    }
    
    // Dientes inferiores (más pequeños, curvados hacia arriba)
    for (int i = 0; i < 8; i++) {
      final offset = (i - 3.5) * 15 * scale;
      final toothPath = Path();
      toothPath.moveTo(center.dx + offset, center.dy + 22 * scale);
      toothPath.lineTo(center.dx + offset - 2.5 * scale, center.dy + 10 * scale);
      toothPath.lineTo(center.dx + offset + 2.5 * scale, center.dy + 10 * scale);
      toothPath.close();
      canvas.drawPath(toothPath, toothPaint);
      canvas.drawPath(toothPath, toothStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
