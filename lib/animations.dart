import 'dart:math';
import 'package:flutter/material.dart';

/// Анимированный камень для игры Mancala
/* ==========================================================================
   1. АНИМАЦИЯ КАМНЯ В ЛУНКЕ (AnimatedStone)
   Отвечает за плавное появление и "подпрыгивание" камней при их добавлении.
   ========================================================================== */
class AnimatedStone extends StatefulWidget {
final double angle;  // Угол размещения (для кругового или хаотичного расположения)
  final double radius; // Радиус разброса от центра лунки
  final List<Color> colors; // Список цветов для градиента (светлый и темный)
  final int index;     // Порядковый номер камня (используется для задержки)
  final int delay;     // Задержка перед началом анимации появления (в мс)

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
      duration: const Duration(milliseconds: 400),
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

class _StoneConfettiState extends State<StoneConfetti> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> particles = List.generate(60, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 4)
    )..repeat();
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
            double progress = _controller.value;
            // Рассчитываем падение
            double currentY = ((p.y + progress * p.fallSpeed) % 1.5 - 0.2) * size.height;
            // Вращение как "колесо"
            double rotationZ = progress * p.rotationSpeed;
            // Вращение как "монетка" (перевороты)
            double rotationX = progress * p.spinSpeed;

            return Positioned(
              left: p.x * size.width,
              top: currentY,
              child: Transform(
                // Создаем 3D-эффект
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Перспектива
                  ..rotateX(rotationX)    // Кувырок вперед
                  ..rotateZ(rotationZ),   // Вращение в плоскости
                alignment: Alignment.center,
                child: Container(
                  width: p.size, 
                  height: p.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.color,
                    gradient: RadialGradient(
                      colors: [p.color.withOpacity(0.7), p.color],
                      center: const Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26, 
                        blurRadius: 2, 
                        offset: Offset(cos(rotationZ), sin(rotationZ))
                      )
                    ],
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
  double x = Random().nextDouble();
  double y = Random().nextDouble() * -1; // Разбрасываем начальную высоту
  double size = 8.0 + Random().nextDouble() * 6.0; // Разный размер камней
  
  double rotationSpeed = (Random().nextDouble() - 0.5) * 10; // Вращение вокруг центра
  double spinSpeed = Random().nextDouble() * 12; // Скорость "кувырков"
  double fallSpeed = 1.0 + Random().nextDouble() * 1.5; // Скорость падения
  
  Color color = [
    Colors.tealAccent, 
    Colors.orangeAccent, 
    Colors.redAccent, 
    Colors.blueAccent, 
    Colors.amberAccent,
    Colors.purpleAccent,
  ][Random().nextInt(6)];
}

/* Вспомогательный класс для описания свойств каждой частицы конфетти */

/*
Хочешь больше камней в конфетти? Измени List.generate(60, ...) на 100.

Хочешь, чтобы конфетти падало медленнее? Увеличь duration в StoneConfetti с 4 до 6 секунд.

Хочешь, чтобы камни в лунках появлялись быстрее? В AnimatedStone уменьши duration с 500 до 200 мс.

Хочешь изменить "хаотичность" падения? В классе ConfettiParticle поиграй со значением fallSpeed. Чем больше разброс между числами, тем более неравномерным будет дождь.
*/