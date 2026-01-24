import 'dart:math';
import 'package:flutter/material.dart';

// на будущее!
class Star {
  double x, y, size, speed;
  Star(
      {required this.x,
      required this.y,
      required this.size,
      required this.speed});

  // Статический метод для создания списка случайных звезд
  static List<Star> generate(int count) {
    final random = Random();
    return List.generate(count, (index) {
      return Star(
        x: random.nextDouble() * 2000, // С запасом под любые экраны
        y: random.nextDouble() * 2000,
        size: random.nextDouble() * 2.0 + 0.5, // Размер от 0.5 до 2.5
        speed: random.nextDouble() * 0.5 +
            0.1, // Разная скорость для эффекта глубины
      );
    });
  }
}

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarFieldPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем каждую звезду
    for (var star in stars) {
      final paint = Paint()
        ..color = Colors.white
            .withOpacity(0.3 + (star.speed * 0.5)); // Быстрые звезды чуть ярче
      MaskFilter.blur(BlurStyle.normal, 0.5);
      // Рассчитываем позицию с учетом анимации (зацикливание через % size.height)
      double xPos = star.x % size.width;
      double yPos = (star.y + animationValue * star.speed) % size.height;

      canvas.drawCircle(Offset(xPos, yPos), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
