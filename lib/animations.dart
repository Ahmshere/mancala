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
              scale: _scaleAnimation.value.clamp(0.0, 2.0),
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
            scale: _scaleAnimation.value.clamp(0.0, 2.0),
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
        double progress = _controller.value;
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
                opacity: (1.0 - (progress * 0.5)).clamp(0.0, 1.0),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(rotationX)
                    ..rotateZ(rotationZ),
                  alignment: Alignment.center,
                  child: Container(
                    width: p.size.clamp(0.0, 50.0),
                    height: p.size.clamp(0.0, 50.0),
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

/// УЛУЧШЕННАЯ АНИМАЦИЯ ПОЛЁТА КАМНЯ С ПАРАБОЛИЧЕСКОЙ ТРАЕКТОРИЕЙ И СЛЕДОМ
class FlyingStone extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;
  final int stoneIndex; // Индекс камня для задержки
  final Color? color; // Цвет камня

  const FlyingStone({
    super.key,
    required this.start,
    required this.end,
    required this.onComplete,
    this.stoneIndex = 0,
    this.color,
  });

  @override
  State<FlyingStone> createState() => _FlyingStoneState();
}

class _FlyingStoneState extends State<FlyingStone>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<Offset> _trail = []; // След за камнем
  late Color stoneColor; // Цвет для этого конкретного камня

  @override
  void initState() {
    super.initState();

    // Генерируем случайный цвет для каждого камня
    final random =
        Random(widget.stoneIndex + DateTime.now().millisecondsSinceEpoch);
    stoneColor = widget.color ??
        [
          Colors.amber,
          Colors.orange,
          Colors.deepOrange,
          Colors.orangeAccent,
          Color(0xFFFFB74D), // Светло-оранжевый
          Color(0xFFFF9800), // Оранжевый
          Color(0xFFFFA726), // Янтарный
          Color(0xFFFFAB40), // Акцент
        ][random.nextInt(8)];

    // Задержка между камнями для красивого каскадного эффекта
    int delay = widget.stoneIndex * 80; // 80ms между камнями

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Запускаем анимацию с задержкой
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) widget.onComplete();
        });
      }
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
      animation: _animation,
      builder: (context, child) {
        double t = _animation.value.clamp(0.0, 1.0);

        // Расстояние между точками для расчёта высоты дуги
        double distance = (widget.end - widget.start).distance;

        // Высота дуги зависит от расстояния (чем дальше, тем выше)
        double arcHeight = min(distance * 0.4, 120.0);

        // Вычисляем текущую позицию по параболе
        double dx = ui.lerpDouble(widget.start.dx, widget.end.dx, t)!;
        double dy = ui.lerpDouble(widget.start.dy, widget.end.dy, t)! -
            (sin(pi * t) * arcHeight);

        Offset currentPos = Offset(dx, dy);

        // Добавляем текущую позицию в след (максимум 5 точек)
        if (_trail.length > 5) _trail.removeAt(0);
        _trail.add(currentPos);

        // Размер камня меняется: УМЕНЬШЕН до размера обычных камней (10px)
        double baseSize = 10.0; // Базовый размер как у камней в лунке
        double scale = 1.0;
        if (t < 0.3) {
          scale = ui.lerpDouble(1.0, 1.3, t / 0.3)!;
        } else if (t > 0.7) {
          scale = ui.lerpDouble(1.3, 1.0, (t - 0.7) / 0.3)!;
        } else {
          scale = 1.3;
        }

        double currentSize = baseSize * scale;

        return Stack(
          children: [
            // СЛЕД ЗА КАМНЕМ
            ..._trail.asMap().entries.map((entry) {
              int idx = entry.key;
              Offset pos = entry.value;
              double opacity =
                  (idx / _trail.length) * 0.3; // Градиент прозрачности
              double size =
                  8 * (idx / _trail.length); // Уменьшающийся размер следа

              return Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                child: IgnorePointer(
                  // Игнорируем клики на след
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stoneColor.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: stoneColor.withOpacity(0.2),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            // САМ КАМЕНЬ
            Positioned(
              left: dx - currentSize / 2,
              top: dy - currentSize / 2,
              child: IgnorePointer(
                // Игнорируем клики на летящий камень
                child: Transform.rotate(
                  angle: t * pi * 2, // Вращение камня в полёте
                  child: Container(
                    width: currentSize,
                    height: currentSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          stoneColor,
                          stoneColor.withOpacity(0.7),
                        ],
                        center: const Alignment(-0.3, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                        BoxShadow(
                          color: stoneColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/* Вспомогательный класс для описания свойств каждой частицы конфетти */

/*
Настройки анимации полёта камней:

1. СКОРОСТЬ КАМНЕЙ:
   - Измени duration в FlyingStone (сейчас 600ms)
   - Меньше = быстрее полёт

2. ЗАДЕРЖКА МЕЖДУ КАМНЯМИ:
   - int delay = widget.stoneIndex * 80
   - Больше число = больше пауза между камнями

3. ВЫСОТА ДУГИ:
   - double arcHeight = min(distance * 0.4, 120.0)
   - Увеличь 0.4 для более высоких дуг

4. ДЛИНА СЛЕДА:
   - if (_trail.length > 5) - измени 5 на другое число
   - Больше = длиннее след

5. РАЗМЕР КАМНЕЙ В ПОЛЁТЕ:
   - scale = ui.lerpDouble(1.0, 1.4, ...)
   - Измени 1.4 для другого размера

Хочешь больше камней в конфетти? Измени List.generate(60, ...) на 100.

Хочешь, чтобы конфетти падало медленнее? Увеличь duration в StoneConfetti с 6 до 8 секунд.

Хочешь, чтобы камни в лунках появлялись быстрее? В AnimatedStone уменьши duration с 500 до 200 мс.
*/
