import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Анимированный камень для игры Mancala
/* ==========================================================================
   1. АНИМАЦИЯ КАМНЯ В ЛУНКЕ (AnimatedStone)
   Отвечает за плавное появление и "подпрыгивание" камней при их добавлении.
   ========================================================================== */
class AnimatedStone extends StatefulWidget {
  final double
      angle; // Угол размещения (для кругового или хаотичного расположения)
  final double radius; // Радиус разброса от центра лунки
  final List<Color> colors; // Список цветов для градиента (светлый и темный)
  final int index; // Порядковый номер камня (используется для задержки)
  final int delay; // Задержка перед началом анимации появления (в мс)

  const AnimatedStone({
    super.key,
    required this.angle,
    required this.radius,
    required this.colors,
    required this.index,
    this.delay = 0,
  });

  @override
  State<AnimatedStone> createState() => _AnimatedStoneState();
}

class _AnimatedStoneState extends State<AnimatedStone>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

// Настройка контроллера: 500 мс на появление одного камня
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
// Эффект "упругого" появления (Scale): камень увеличивается с 0 до 1 с отскоком
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Задержка для каскадной анимации
    // Запуск анимации с индивидуальной задержкой, чтобы камни падали по очереди
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            cos(widget.angle) * widget.radius,
            sin(widget.angle) * widget.radius,
          ),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      widget.colors[1],
                      widget.colors[0],
                    ],
                    center: const Alignment(-0.4, -0.4),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Анимация перемещения камня между лунками
class StoneTransferAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Color color;
  final VoidCallback? onComplete;

  const StoneTransferAnimation({
    super.key,
    required this.start,
    required this.end,
    required this.color,
    this.onComplete,
  });

  @override
  State<StoneTransferAnimation> createState() => _StoneTransferAnimationState();
}

class _StoneTransferAnimationState extends State<StoneTransferAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (widget.onComplete != null) widget.onComplete!();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Анимация пульсации для активных лунок
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PulseAnimation({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }

// Конфетюги
/* ==========================================================================
   2. ЭФФЕКТ КОНФЕТТИ (StoneConfetti)
   Создает дождь из вращающихся разноцветных камней при победе.
   ========================================================================== */
}

class StoneConfetti extends StatefulWidget {
  const StoneConfetti({super.key});
  @override
  State<StoneConfetti> createState() => _StoneConfettiState();
}

class _StoneConfettiState extends State<StoneConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> particles = List.generate(60, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return Stack(
          children: particles.map((p) {
            // ОБНОВЛЯЕМ логику частицы на каждом кадре
            p.update();

            double rotationZ = _controller.value * p.rotationSpeed;
            double rotationX = _controller.value * p.spinSpeed;

            return Positioned(
              left: p.x * size.width,
              top: p.y * size.height,
              child: Opacity(
                opacity: p.opacity.clamp(0, 1),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(rotationX)
                    ..rotateZ(rotationZ),
                  alignment: Alignment.center,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color,
                      boxShadow: [
                        BoxShadow(
                          color: p.color.withOpacity(0.5),
                          blurRadius: 10, // Свечение (glow)
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  late double x, y;
  late double vx, vy;
  late double size;
  late double spiralSpeed;
  late double opacity;
  late Color color;
  late double rotationSpeed;
  late double spinSpeed;

  _Particle() {
    reset();
  }

  void reset() {
    // Начинаем из центра экрана (0.5 - это середина в относительных координатах)
    x = 0.5;
    y = 0.4; // Чуть выше центра, за диалогом

    // Выбираем случайный угол для разлета
    double angle = Random().nextDouble() * 2 * pi;
    double speed = 0.002 + Random().nextDouble() * 0.005;

    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    // Скорость закручивания в спираль
    spiralSpeed = (Random().nextDouble() - 0.5) * 0.07;

    size = 4.0 + Random().nextDouble() * 6.0;
    opacity = 1.0;

    rotationSpeed = (Random().nextDouble() - 0.5) * 10;
    spinSpeed = Random().nextDouble() * 12;

    color = [
      Colors.tealAccent,
      Colors.orangeAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.deepPurpleAccent,
      Colors.cyanAccent,
      Colors.amber,
      Colors.indigoAccent,
    ][Random().nextInt(8)];
  }

  // Метод для обновления позиции (вызовем его в билдере)
  void update() {
    // Магия спирали: немного поворачиваем вектор скорости
    double oldVx = vx;
    vx = vx * cos(spiralSpeed) - vy * sin(spiralSpeed);
    vy = oldVx * sin(spiralSpeed) + vy * cos(spiralSpeed);

    x += vx;
    y += vy;
    opacity -= 0.0015; // Частицы медленно гаснут

    if (opacity <= 0 || x < -0.2 || x > 1.2 || y > 1.2) {
      reset();
    }
  }
}

class FlyingStone extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const FlyingStone(
      {super.key,
      required this.start,
      required this.end,
      required this.onComplete});

  @override
  State<FlyingStone> createState() => _FlyingStoneState();
}

class _FlyingStoneState extends State<FlyingStone>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double t = _animation.value;
        // Вычисляем траекторию дуги (парабола)
        // x — линейно, y — с выгибом вверх
        double dx = ui.lerpDouble(widget.start.dx, widget.end.dx, t)!;
        double dy = ui.lerpDouble(widget.start.dy, widget.end.dy, t)! -
            (sin(pi * t) * 150);
        return Positioned(
          left: dx,
          top: dy,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amberAccent,
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        );
      },
    );
  }
}
/* Вспомогательный класс для описания свойств каждой частицы конфетти */

/*
Хочешь больше камней в конфетти? Измени List.generate(60, ...) на 100.

Хочешь, чтобы конфетти падало медленнее? Увеличь duration в StoneConfetti с 4 до 6 секунд.

Хочешь, чтобы камни в лунках появлялись быстрее? В AnimatedStone уменьши duration с 500 до 200 мс.

Хочешь изменить "хаотичность" падения? В классе ConfettiParticle поиграй со значением fallSpeed. Чем больше разброс между числами, тем более неравномерным будет дождь.
*/
