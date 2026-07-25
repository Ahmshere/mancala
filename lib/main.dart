import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animations.dart';
import 'audio_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'stats_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_manager.dart';
// import 'space_background.dart';
import 'dart:io';

// my_email: prudnikov.michael@aol.com
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🆕 РАЗРЕШАЕМ ВСЕ ОРИЕНТАЦИИ (для главного меню)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await AudioManager().init();
  await AdMobManager().initialize();

  runApp(const MancalaApp());
}

class MancalaApp extends StatelessWidget {
  const MancalaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainMenu(),
    );
  }
}
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
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
        final scale = 1.0 + (_controller.value * 0.2);
        return Transform.scale(
          scale: scale,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
            shadows: [
              Shadow(
                color: widget.color.withOpacity(0.8),
                blurRadius: 20 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// 🆕 ВИДЖЕТ АНИМИРОВАННОГО СЧЁТА
class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final int delay;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Левая часть (Label)
            Flexible( // 🆕 Вместо Expanded
              flex: 2,
              child: Text(
                '$label:',
                style: TextStyle(fontSize: 16, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            // Правая часть (Score)
            TweenAnimationBuilder<int>(
              duration: const Duration(milliseconds: 800),
              tween: IntTween(begin: 0, end: score),
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
/* ===================== ГЛАВНОЕ МЕНЮ ===================== */

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  double _parallaxX = 0;
  double _parallaxY = 0;
  StreamSubscription? _accelSubscription;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _titleController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _titleController,
          curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _titleController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)),
    );

    _titleController.forward();
    _accelSubscription = accelerometerEvents.listen((event) {
      setState(() {
        _parallaxX = event.x * 2; // Чувствительность
        _parallaxY = event.y * 2;
      });
    });
    // фоновая музыка
    if (GameSettings.isMusicOn) {
      AudioManager().playMusic();
    }
  }

  @override
  void dispose() {
    _accelSubscription?.cancel(); // Обязательно закрываем!
    _titleController.dispose();
    super.dispose();
  }

  void _openRules() {
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.amber),
            const SizedBox(width: 10),
            Text(txt['rules']!, style: const TextStyle(color: Colors.amber)),
          ],
        ),
        content: SizedBox(
          height: 400, // Фиксированная высота для появления скролла
          width: double.maxFinite,
          child: Scrollbar(
            thumbVisibility: true, // Всегда показывать полосу прокрутки
            thickness: 6,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(txt['rules_text']!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, height: 1.5)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(txt['close']!,
                style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    final Map<String, String> txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en] ??
        {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF3E2723),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Text(
              txt['settings'] ?? 'Settings',
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              // Добавили скролл, если настроек станет много
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- СЕКЦИЯ ЯЗЫКА ---
                  Text(txt['language'] ?? 'Language',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _langButton(Language.ru, '🇷🇺', setDialogState),
                      _langButton(Language.en, '🇺🇸', setDialogState),
                      _langButton(Language.de, '🇩🇪', setDialogState),
                    ],
                  ),

                  const Divider(color: Colors.white24, height: 30),

                  // --- БЛОК МУЗЫКИ ---
                  _buildSettingRow(
                    icon: GameSettings.isMusicOn
                        ? Icons.music_note
                        : Icons.music_off,
                    label: txt['music'] ?? 'Music',
                    value: GameSettings.isMusicOn,
                    onChanged: (val) {
                      setDialogState(() => GameSettings.isMusicOn = val);
                      val
                          ? AudioManager().playMusic()
                          : AudioManager().stopMusic();
                    },
                  ),
                  if (GameSettings.isMusicOn)
                    _buildVolumeSlider(
                      value: GameSettings.musicVolume,
                      onChanged: (val) {
                        setDialogState(() => GameSettings.musicVolume = val);
                        AudioManager().updateMusicVolume();
                      },
                    ),

                  const SizedBox(height: 15),

                  // --- БЛОК ЗВУКОВ ---
                  _buildSettingRow(
                    icon: GameSettings.isSoundOn
                        ? Icons.volume_up
                        : Icons.volume_off,
                    label: txt['sound'] ?? 'Sounds',
                    value: GameSettings.isSoundOn,
                    onChanged: (val) {
                      setDialogState(() => GameSettings.isSoundOn = val);
                    },
                  ),
                  if (GameSettings.isSoundOn)
                    _buildVolumeSlider(
                      value: GameSettings.sfxVolume,
                      onChanged: (val) {
                        setDialogState(() => GameSettings.sfxVolume = val);
                      },
                    ),
                  _buildSupportSection(txt),
                ],
              ),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(
                            () {}); // Обновляем главный экран, чтобы язык сменился везде
                  },
                  child: Text(txt['close'] ?? 'Close',
                      style:
                      const TextStyle(color: Colors.amber, fontSize: 18)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchCoffeeURL() async {
    final Uri url = Uri.parse('https://buymeacoffee.com/thegradtouralone');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildSupportSection(Map<String, String> txt) {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black38, Colors.brown.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // Иконки, отражающие твою суть
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, color: Colors.amber, size: 20),
              SizedBox(width: 15),
              Icon(Icons.music_note, color: Colors.amber, size: 24),
              SizedBox(width: 15),
              Icon(Icons.directions_car, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            txt['support_title'] ?? '',
            style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            txt['support_text'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4, // Межстрочный интервал для читаемости
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _launchCoffeeURL,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFDD00),
              foregroundColor: Colors.black,
              elevation: 5,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.coffee_rounded),
            label: const Text('Support my journey',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

// Вспомогательный виджет для кнопки выбора языка
  Widget _langButton(
      Language language, String flag, StateSetter setDialogState) {
    // Сравниваем ИМЯ энэма со строкой кода
    bool isSelected = GameSettings.lang == language;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          GameSettings.lang = language;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
          isSelected ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.amber : Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(flag, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

// Вспомогательный виджет для строк настроек
  Widget _buildSettingRow(
      {required IconData icon,
        required String label,
        required bool value,
        required Function(bool) onChanged}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 15),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 16))),
        Switch(
          value: value,
          activeColor: Colors.amber,
          onChanged: onChanged,
        ),
      ],
    );
  }

// Вспомогательный виджет для слайдера
  Widget _buildVolumeSlider(
      {required double value, required Function(double) onChanged}) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.amber,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.amberAccent,
        overlayColor: Colors.amber.withOpacity(0.2),
      ),
      child: Slider(
        value: value,
        min: 0.0,
        max: 1.0,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDifficultyChips() {
    // 1. Сначала получаем текущий словарь переводов (как в начале build)
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.black45, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Difficulty.values
            .map((d) => ChoiceChip(
          // 2. ЗАМЕНЯЕМ ЭТУ СТРОКУ:
          label: Text(txt[d.name] ?? d.name.toUpperCase(),
              style: const TextStyle(fontSize: 12)),

          selected: GameSettings.difficulty == d,
          onSelected: (s) =>
              setState(() => GameSettings.difficulty = d),
          selectedColor: Colors.amber.withOpacity(0.4),
          backgroundColor: Colors.transparent,
        ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String langName = GameSettings.lang.name;
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;
    return Scaffold(
      body: Stack(
        // Используем Stack для слоев
        children: [
          // СЛОЙ 1: Фон с параллаксом
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            // Смещаем фон чуть-чуть в зависимости от наклона
            left: -15 + _parallaxX,
            top: -15 - _parallaxY,
            right: -15 - _parallaxX,
            bottom: -15 + _parallaxY,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              // Затемнение фона
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                bool isLandscape = orientation == Orientation.landscape;
                return Center(
                  child: Flex(
                    direction: isLandscape ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Твое анимированное название (MANCALA)
                      AnimatedBuilder(
                        animation: _titleController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Stack(
                                    children: [
                                      Text(
                                        txt['title'] ?? 'MANCALA',
                                        style: GoogleFonts.cinzel(
                                          textStyle: TextStyle(
                                            fontSize: isLandscape ? 50 : 65,
                                            fontWeight: FontWeight.bold,
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = 8
                                              ..color = Colors.amber
                                                  .withOpacity(
                                                  _glowAnimation.value *
                                                      0.5)
                                              ..maskFilter = MaskFilter.blur(
                                                  BlurStyle.normal,
                                                  15 +
                                                      (_glowAnimation.value *
                                                          10)), // Размытие расширяется
                                            letterSpacing: 8,
                                          ),
                                        ),
                                      ),
                                      Stack(
                                        children: [
                                          // Внешнее "дышащее" свечение (контур вокруг букв)
                                          Text(
                                            txt['title'] ?? 'MANCALA',
                                            style: GoogleFonts.cinzel(
                                              textStyle: TextStyle(
                                                fontSize: isLandscape ? 50 : 65,
                                                letterSpacing: 8,
                                                foreground: Paint()
                                                  ..style = PaintingStyle.stroke
                                                  ..strokeWidth = 12
                                                  ..color = Color.lerp(
                                                      Colors.orange,
                                                      Colors.amber,
                                                      _glowAnimation.value)!
                                                      .withOpacity(0.3 *
                                                      _glowAnimation.value)
                                                  ..maskFilter =
                                                  MaskFilter.blur(
                                                      BlurStyle.normal,
                                                      15 *
                                                          _glowAnimation
                                                              .value +
                                                          5),
                                              ),
                                            ),
                                          ),
                                          // Основной текст
                                          Text(
                                            txt['title'] ?? 'MANCALA',
                                            style: GoogleFonts.cinzel(
                                              textStyle: TextStyle(
                                                fontSize: isLandscape ? 50 : 65,
                                                fontWeight: FontWeight.normal,
                                                color: const Color(0xFFFFD54F),
                                                letterSpacing: 8,
                                                shadows: [
                                                  // Тень пульсирует и меняет оттенок от черного к медному
                                                  Shadow(
                                                    color: Color.lerp(
                                                        Colors.black,
                                                        Colors.deepOrange,
                                                        _glowAnimation
                                                            .value)!
                                                        .withOpacity(0.8),
                                                    blurRadius: 12 +
                                                        (10 *
                                                            _glowAnimation
                                                                .value),
                                                    offset: Offset(
                                                        0,
                                                        4 +
                                                            2 *
                                                                _glowAnimation
                                                                    .value),
                                                  ),
                                                  // Легкий внутренний блик
                                                  Shadow(
                                                    color: Colors.white
                                                        .withOpacity(0.2 *
                                                        _glowAnimation
                                                            .value),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Твои кнопки PVP и VS CPU
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _menuBtn(
                              txt['pvp'] ?? 'PVP', GameMode.pvp, isLandscape),
                          const SizedBox(height: 15),
                          _menuBtn(
                              txt['ai'] ?? 'VS CPU', GameMode.ai, isLandscape),
                          const SizedBox(height: 30),
                          _buildDifficultyChips(),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Кнопки управления (Правила, Настройки, Версия)
          Positioned(
              top: 50,
              left: 25,
              child: IconButton(
                  icon: const Icon(Icons.help_outline,
                      color: Color(0xFFFFD54F), size: 40),
                  onPressed: _openRules)),
          Positioned(
              top: 50,
              right: 25,
              child: IconButton(
                  icon: const Icon(Icons.settings,
                      color: Color(0xFFFFD54F), size: 40),
                  onPressed: _openSettings)),
          Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                  child: Text("version: ${GameSettings.appVersion}",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12)))),
          Positioned(
            top: 50,
            right: 85, // Сдвигаем левее от шестеренки
            child: IconButton(
              icon: const Icon(Icons.bar_chart,
                  color: Color(0xFFFFD54F), size: 40),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const StatsScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBtn(String text, GameMode mode, bool isLandscape) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8D6E63).withOpacity(0.9),
          minimumSize: Size(isLandscape ? 220 : 280, 60),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white24))),
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => MancalaGame(mode: mode))),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

/* ===================== ИГРОВОЙ ЭКРАН ===================== */

class MancalaGame extends StatefulWidget {
  final GameMode mode;
  const MancalaGame({super.key, required this.mode});
  @override
  State<MancalaGame> createState() => _MancalaGameState();
}

// Основа
class _MancalaGameState extends State<MancalaGame>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // СЧЕТЧИК ИГР (static чтобы сохранялся между играми)
  static int _gamesCompleted = 0;
  List<int> board = List.filled(14, 4);
  // late List<Star> _stars;
  // late AnimationController _starController;
  bool isP1Turn = true;
  bool animating = false;
  int? lastDrop;
  late AnimationController _stoneAnimController;
  bool isAiThinking = false;
  int? aiHighlightIndex; // Индекс лунки, которую "рассматривает" ИИ
  int? aiSelectedPit; // Новая переменная для акцента на стартовой лунке
  DateTime? startTime;
  List<int>? _lastBoardState; // Состояние доски до хода
  bool? _lastTurnState; // Чей был ход
  bool _canUndo = false; // Можно ли сейчас отменить ход
  late AnimationController _magicRotationController;
  final List<GlobalKey> pitKeys = List.generate(14, (index) => GlobalKey());
  List<Widget> captureAnimations = []; // Здесь будут храниться летящие камни
  int?
  _activeMovePit; // Лунка, из которой сейчас летят камни (скрываем визуально)
  Set<int> _capturingPits = {}; // Лунки, чьи камни сейчас летят при захвате (скрываем визуально)
  // _incomingPits removed — was causing number ghost/overlap bug
  Map<int, bool> _shakeTriggers = {}; // Триггеры дрожания для каждой лунки

  //метод для вычисления экранных координат и запуска FlyingStone
  void _animateCapture(int fromIndex, int toIndex) {
    if (pitKeys[fromIndex].currentContext == null ||
        pitKeys[toIndex].currentContext == null) {
      print("ОШИБКА: Лунка $fromIndex или $toIndex не видна на экране!");
      return;
    }

    final RenderBox boxFrom =
    pitKeys[fromIndex].currentContext!.findRenderObject() as RenderBox;
    final RenderBox boxTo =
    pitKeys[toIndex].currentContext!.findRenderObject() as RenderBox;

    final Offset startPos = boxFrom
        .localToGlobal(Offset(boxFrom.size.width / 2, boxFrom.size.height / 2));
    final Offset endPos = boxTo
        .localToGlobal(Offset(boxTo.size.width / 2, boxTo.size.height / 2));

    print("СТАРТ ПОЛЕТА: из $fromIndex в $toIndex ($startPos -> $endPos)");

    late Widget flying;
    flying = FlyingStone(
      start: startPos,
      end: endPos,
      onComplete: () {
        print("ПОЛЕТ ЗАВЕРШЕН");
        if (mounted) {
          setState(() {
            captureAnimations.remove(flying);
          });
        }
      },
    );

    setState(() {
      captureAnimations.add(flying);
    });
  }

  // Новый метод для анимации полёта камня при обычном ходе
  void _animateStoneFlight(int fromIndex, int toIndex, int stoneIndex) {
    if (pitKeys[fromIndex].currentContext == null ||
        pitKeys[toIndex].currentContext == null) {
      return;
    }

    final RenderBox boxFrom =
    pitKeys[fromIndex].currentContext!.findRenderObject() as RenderBox;
    final RenderBox boxTo =
    pitKeys[toIndex].currentContext!.findRenderObject() as RenderBox;

    final Offset startPos = boxFrom
        .localToGlobal(Offset(boxFrom.size.width / 2, boxFrom.size.height / 2));
    final Offset endPos = boxTo
        .localToGlobal(Offset(boxTo.size.width / 2, boxTo.size.height / 2));

    final stoneKey = GlobalKey();

    final flying = FlyingStone(
      key: stoneKey,
      start: startPos,
      end: endPos,
      stoneIndex: stoneIndex,
      onComplete: () {
        // Только убираем летящий камень — board обновляется батчем в _move
        if (mounted) {
          setState(() {
            captureAnimations.removeWhere((w) => w.key == stoneKey);
          });
        }
      },
    );

    setState(() {
      captureAnimations.add(flying);
    });
  }

// save statistic
// Изменяем название и добавляем аргументы p1 и p2
  void _saveFinalStatsManual(int finalP1, int finalP2) async {
    if (startTime == null) return;
    final prefs = await SharedPreferences.getInstance();
    final duration = DateTime.now().difference(startTime!);

    final durationStr =
        "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";

    final record = GameRecord(
      date: dateStr,
      mode: widget.mode == GameMode.ai ? "VS CPU" : "PVP",
      score: "$finalP1 : $finalP2", // Используем ПЕРЕДАННЫЕ значения
      duration: durationStr,
      difficulty: widget.mode == GameMode.ai
          ? GameSettings.difficulty.name.toUpperCase()
          : "",
    );

    List<String> history = prefs.getStringList('game_history') ?? [];
    history.insert(0, json.encode(record.toJson()));
    await prefs.setStringList('game_history', history);
  }

  void _saveFinalStats() async {
    if (startTime == null) return;
    final prefs = await SharedPreferences.getInstance();
    final duration = DateTime.now().difference(startTime!);

    final durationStr =
        "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";

    final record = GameRecord(
      date: dateStr,
      mode: widget.mode == GameMode.ai ? "VS CPU" : "PVP",
      score: "${board[6]} : ${board[13]}",
      duration: durationStr,
      difficulty: widget.mode == GameMode.ai
          ? GameSettings.difficulty.name.toUpperCase()
          : "", // Сохраняем сложность только для игры с ИИ
    );

    List<String> history = prefs.getStringList('game_history') ?? [];
    history.insert(0, json.encode(record.toJson()));
    await prefs.setStringList('game_history', history);
  }

  void _confirmExit() {
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(txt['exit_confirm_title'] ?? "Exit?",
            style: const TextStyle(color: Colors.amber)),
        content: Text(txt['exit_confirm_desc'] ?? "Progress will be lost.",
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(txt['close']!,
                  style: const TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем этот диалог
                Navigator.pop(context); // Возвращаемся в Главное меню
              },
              child: Text(txt['menu']!,
                  style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 🆕 ПРИНУДИТЕЛЬНО БЛОКИРУЕМ ЛАНДШАФТ СРАЗУ ПРИ СТАРТЕ ИГРЫ
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // _stars = Star.generate(50);
    /*_starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Скорость общего потока
    )..repeat();
    */
    WidgetsBinding.instance.addObserver(this);
    board[6] = 0;
    board[13] = 0;
    _stoneAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    startTime = DateTime.now();

    _magicRotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    ); //..repeat();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.removeObserver(this);
    // _starController.dispose();
    _stoneAnimController.dispose();
    _magicRotationController.dispose();
    super.dispose();
  }

  // Проверка окончания игры
  bool _checkGameOver() {
    bool p1Empty = board.sublist(0, 6).every((v) => v == 0);
    bool p2Empty = board.sublist(7, 13).every((v) => v == 0);
    return p1Empty || p2Empty;
  }

  void _showGameOverDialog() {
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;

    int p1Score = board[6];
    int p2Score = board[13];
    _saveFinalStatsManual(p1Score, p2Score);

    for (int i = 0; i < 14; i++) {
      if (i != 6 && i != 13) board[i] = 0;
    }

    setState(() {});

    String winner;
    IconData winIcon;
    Color winColor;

    if (p1Score > p2Score) {
      AudioManager().playSfx(AudioManager.winSound);
      winner = txt['p1_wins']!;
      winIcon = Icons.emoji_events; // 🏆
      winColor = Colors.amber;
    } else if (p2Score > p1Score) {
      AudioManager().playSfx(AudioManager.loseSound);
      winner = widget.mode == GameMode.ai ? txt['ai_wins']! : txt['p2_wins']!;
      winIcon = Icons.computer; // 🤖
      winColor = Colors.deepOrange;
    } else {
      AudioManager().playSfx(AudioManager.winSound);
      winner = txt['draw']!;
      winIcon = Icons.handshake; // 🤝
      winColor = Colors.blueAccent;
    }

    _magicRotationController.repeat();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          // 1. Конфетти
          IgnorePointer(
            child: Center(
              child: const StoneConfetti(),
            ),
          ),

          // 2. Диалог с WOW анимацией
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Transform.rotate(
                  angle: (1 - value) * 0.3, // Поворот при появлении
                  child: child,
                ),
              );
            },
            child: AlertDialog(
              backgroundColor: const Color(0xFF3E2723).withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: winColor, width: 3),
              ),
              title: _PulsingIcon(
                icon: winIcon,
                color: winColor,
                size: 48,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Анимированный текст победителя
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.bounceOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      winner,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: winColor,
                        shadows: [
                          Shadow(
                            color: winColor.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, //  Максимум 2 строки
                      overflow: TextOverflow.ellipsis, //  Троеточие если не влезает
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Счёт
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Column(
                      children: [
                        _ScoreRow(
                          label: txt['p1']!,
                          score: p1Score,
                          color: Colors.greenAccent,
                          delay: 300,
                        ),
                        _ScoreRow(
                          label: widget.mode == GameMode.ai
                              ? (txt['ai_short'] ?? txt['ai']!)
                              : txt['p2']!,
                          score: p2Score,
                          color: Colors.orangeAccent,
                          delay: 500,
                        ),
                      ],
                    ),
                  ),
                ], // ⬅️ ЗАКРЫВАЮЩАЯ СКОБКА для children Column
              ), // ⬅️ ЗАКРЫВАЮЩАЯ СКОБКА для content
              actions: [ // ⬅️ ЗДЕСЬ actions НА ПРАВИЛЬНОМ УРОВНЕ!
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _gamesCompleted++;

                    if (_gamesCompleted % 2 == 0) {
                      AdMobManager().showInterstitialAd(onAdClosed: () {
                        if (mounted) {
                          setState(() {
                            board = List.filled(14, 4);
                            board[6] = 0;
                            board[13] = 0;
                            isP1Turn = true;
                            startTime = DateTime.now();
                          });
                        }
                      });
                    } else {
                      if (mounted) {
                        setState(() {
                          board = List.filled(14, 4);
                          board[6] = 0;
                          board[13] = 0;
                          isP1Turn = true;
                          startTime = DateTime.now();
                        });
                      }
                    }
                  },
                  child: Text(txt['play_again']!,
                      style: const TextStyle(color: Colors.amber, fontSize: 16)),
                ),
                TextButton(
                  onPressed: () {
                    _gamesCompleted++;

                    if (_gamesCompleted % 2 == 0) {
                      AdMobManager().showInterstitialAd(onAdClosed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      });
                    } else {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(txt['menu']!,
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ),
              ],
            ), // ⬅️ ЗАКРЫВАЮЩАЯ СКОБКА для AlertDialog
          ), // ⬅️ ЗАКРЫВАЮЩАЯ СКОБКА для child TweenAnimationBuilder
        ],
      ),
    );}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Приложение свернуто — выключаем всю музыку
      AudioManager().stopMusic();
    } else if (state == AppLifecycleState.resumed) {
      // Вернулись в игру — включаем, только если она была включена в настройках
      if (GameSettings.isMusicOn) {
        AudioManager().playMusic();
      }
    }
  }

  // КРУГОВОЕ РАСПРЕДЕЛЕНИЕ КАМНЕЙ С АНИМАЦИЕЙ
  Widget _buildStones(int count, bool isKalah, int pitIndex) {
    if (GameSettings.visualMode == VisualMode.numbersOnly || count == 0)
      return const SizedBox();

    const stoneColors = [
      [Colors.teal, Colors.tealAccent],
      [Colors.indigo, Colors.lightBlue],
      [Colors.brown, Colors.orangeAccent],
      [Colors.redAccent, Colors.red],
      [Colors.blueGrey, Colors.white70],
    ];

    //  int visibleStones = min(count, 12);
    // В обычных лунках максимум 12 камней, в Калахах — до 25 (чтобы не тормозило)
    int visibleStones = isKalah ? min(count, 25) : min(count, 12);
    // Увеличиваем радиус разброса, чтобы камни не слипались
    double maxRadius = isKalah ? 40.0 : 32.0;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(visibleStones, (index) {
        // Используем Random с фиксированным зерном (seed) ТОЛЬКО на основе индекса,
        // чтобы камни в конкретной лунке лежали всегда в одних и тех же местах
        // ВАЖНО: не добавляем count, иначе позиции будут меняться при добавлении камней!
        final rnd = Random(index * 100);

        // Хаотичное смещение от центра
        // minRadius=10 — центр свободен для цифры
        double minRadius = isKalah ? 0.0 : 10.0;
        double randomRadius = minRadius + sqrt(rnd.nextDouble()) * (maxRadius - minRadius);
        double randomAngle = rnd.nextDouble() * 2 * pi;

        var colors = stoneColors[index % stoneColors.length];

        return Transform.translate(
          key: ValueKey('stone_${pitIndex}_$index'),
          offset: Offset(
              cos(randomAngle) * randomRadius, sin(randomAngle) * randomRadius),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white, colors[1], colors[0]],
                center: const Alignment(-0.4, -0.4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(1.5, 1.5))
              ],
            ),
          ),
        );
      }),
    );
  }

  void _openRules() {
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.amber),
            const SizedBox(width: 10),
            Text(txt['rules']!, style: const TextStyle(color: Colors.amber)),
          ],
        ),
        content: SizedBox(
          height: 400, // Высота для появления скроллбара
          width: double.maxFinite,
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(txt['rules_text']!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, height: 1.5)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(txt['close']!,
                style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        // Оборачиваем все в Stack, чтобы анимации были ПОВЕРХ доски
        body: Stack(
          children: [
            // СЛОЙ 1: Твой текущий интерфейс игры
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  colorFilter:
                  ColorFilter.mode(Colors.black87, BlendMode.darken),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: SafeArea(
                  child: Stack(
                    // Внутренний Stack для кнопки помощи
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          AnimatedOpacity(
                            opacity: isAiThinking ? 0.5 : 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              isP1Turn
                                  ? txt['p1_turn']!
                                  : (widget.mode == GameMode.ai
                                  ? txt['ai_turn']!
                                  : txt['p2_turn']!),
                              style: GoogleFonts.cinzel(
                                // Можно добавить шрифт здесь
                                textStyle: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFD54F),
                                    shadows: [
                                      if (isAiThinking)
                                        const Shadow(
                                            color: Colors.amberAccent,
                                            blurRadius: 20),
                                    ]),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: _buildBoard(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: const Icon(Icons.help_outline,
                              color: Colors.amber, size: 35),
                          onPressed: _openRules,
                        ),

                      ),
                      // кнопка вкл/выкл фон музыки
                      // Кнопки управления (Музыка + Отмена хода)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Определяем ориентацию
                            final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                            final buttonSize = isPortrait ? 24.0 : 28.0; // Меньше в портрете

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Кнопка музыки
                                  IconButton(
                                    icon: Icon(
                                      GameSettings.isMusicOn
                                          ? Icons.music_note
                                          : Icons.music_off,
                                      color: Colors.amber,
                                      size: buttonSize, // 🆕 Адаптивный размер
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        GameSettings.isMusicOn = !GameSettings.isMusicOn;
                                        if (GameSettings.isMusicOn) {
                                          AudioManager().playMusic();
                                        } else {
                                          AudioManager().stopMusic();
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 6), // 🆕 Уменьшили отступ

                                  // Кнопка ОТМЕНЫ хода
                                  if (_canUndo &&
                                      !animating &&
                                      !isAiThinking &&
                                      aiSelectedPit == null)
                                    IconButton(
                                      icon: Icon(Icons.undo,
                                          color: Colors.amber,
                                          size: buttonSize), // 🆕 Адаптивный размер
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _undoMove,
                                    ),

                                  const SizedBox(width: 6), // 🆕 Уменьшили отступ

                                  // Кнопка подсказки
                                  if (widget.mode == GameMode.ai &&
                                      isP1Turn &&
                                      !animating &&
                                      AdMobManager().isRewardedAdReady)
                                    IconButton(
                                      icon: Icon(Icons.lightbulb_outline,
                                          color: Colors.amber,
                                          size: buttonSize), // 🆕 Адаптивный размер
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Hint (watch ad)',
                                      onPressed: () {
                                        AdMobManager().showRewardedAd(
                                          onRewardEarned: (earned) {
                                            if (earned && mounted) {
                                              _showAIHint();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),),

            ...captureAnimations,
          ],
        ),
      ),
    );
  }


  // ИЩИ ЭТОТ МЕТОД В КОНЦЕ ФАЙЛА
  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(width: 8, color: const Color(0xFF3E2723)),
        image: const DecorationImage(
          image: AssetImage('assets/images/wood_board.jpg'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Это создаст эффект "вдавленности" центральной части доски
      // foregroundDecoration удалён — затемнял крайние лунки поверх цифр
      child: Row(
        children: [
          _buildKalah(13, Colors.orangeAccent),
          Column(
            children: [
              Row(children: List.generate(6, (i) => _buildPit(12 - i))),
              const SizedBox(height: 40),
              Row(children: List.generate(6, (i) => _buildPit(i))),
            ],
          ),
          _buildKalah(6, Colors.greenAccent),
        ],
      ),
    );
  }

  void _showAIHint() {
    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;

    // Используем ту же логику, что и AI
    int bestMove = -1;
    int bestValue = -20000;
    int depth = GameSettings.difficulty == Difficulty.easy ? 2 :
    (GameSettings.difficulty == Difficulty.medium ? 4 : 6);

    for (int i = 0; i < 6; i++) {
      if (board[i] > 0) {
        var result = _simulateMoveDetailed(board, i);
        int moveValue = _minimax(
            result.board, depth, result.extraTurn, -20000, 20000);

        if (moveValue > bestValue) {
          bestValue = moveValue;
          bestMove = i;
        }
      }
    }

    if (bestMove != -1) {
      // Подсвечиваем лучший ход на 3 секунды
      setState(() => aiSelectedPit = bestMove);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF3E2723).withOpacity(0.95),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 10),
              Text('AI Hint',
                  style: const TextStyle(color: Colors.amber)),
            ],
          ),
          content: Text(
            'Try moving from pit ${bestMove + 1}!\n\n'
                'This is the strongest move AI would make.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() => aiSelectedPit = null);
                  }
                });
              },
              child: const Text('Got it!',
                  style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      );
    }
  }
  /*
  В методе _buildPit(int i):
    Размер лунки: width: 65, height: 65 (в контейнере внутри метода).
    Размер числа камней: fontSize: 18 (в Text(board[i].toString())).
    Радиус скругления: borderRadius: BorderRadius.circular(35)
  */
  Widget _buildPit(int i) {
    bool isHighlighted = aiSelectedPit == i;
    bool active = (isP1Turn && i < 6 && board[i] > 0) ||
        (!isP1Turn &&
            widget.mode == GameMode.pvp &&
            i > 6 &&
            i < 13 &&
            board[i] > 0);

    return ShakeAnimation(
      key: pitKeys[i],
      trigger: _shakeTriggers[i] ?? false,
      onComplete: () {
        if (mounted) {
          setState(() {
            _shakeTriggers[i] = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () => active && !animating && !isAiThinking ? _move(i) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 90,
          height: 90,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B100E).withOpacity(0.85),
            boxShadow: [
              // 1. ПОДСВЕТКА ЛУНКИ
              BoxShadow(
                color: active
                    ? (i < 6
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.deepOrange.withOpacity(0.5))
                    : (i < 6
                    ? Colors.amber.withOpacity(0)
                    : Colors.deepOrange.withOpacity(0)),
                // ДОБАВИЛИ .clamp(0.0, 50.0) — теперь радиус не будет отрицательным!
                blurRadius: (active ? 15.0 : 0.0).clamp(0.0, 50.0),
                spreadRadius: (active ? 2.0 : 0.0).clamp(0.0, 20.0),
              ),
              // 2. БЛИК ГЛУБИНЫ
              BoxShadow(
                color: Colors.white.withOpacity(0.12),
                offset: const Offset(1, 2),
                blurRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.2)
              ],
            ),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Скрываем камни, если это стартовая лунка текущего хода
                // или если камни из этой лунки сейчас улетают при захвате
                if (i != _activeMovePit && !_capturingPits.contains(i))
                  _buildStones(board[i], false, i),
                if (GameSettings.visualMode != VisualMode.stonesOnly)
                  PulseAnimation(
                    key: ValueKey('pulse_${i}_$isHighlighted'),
                    enabled: isHighlighted,
                    child: Text(
                      '${board[i]}',
                      style: GoogleFonts.cinzel(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: isHighlighted ? 44 : 30,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset( 2,  2)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(-2, -2)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset( 2, -2)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(-2,  2)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset( 3,  0)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(-3,  0)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset( 0,  3)),
                            const Shadow(color: Colors.black, blurRadius: 3, offset: Offset( 0, -3)),
                            const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 0)),
                            Shadow(
                              color: isHighlighted
                                  ? Colors.white.withOpacity(0.9)
                                  : (active
                                  ? (i < 6 ? Colors.amber : Colors.orange)
                                  : Colors.transparent),
                              blurRadius: isHighlighted ? 25.0 : (active ? 14.0 : 0.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKalah(int i, Color color) {
    return Container(
      key: pitKeys[i],
      width: 100,
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withOpacity(0.6), width: 3)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStones(board[i], true, i),
          const SizedBox(height: 15),
          Text("${board[i]}",
              style: TextStyle(
                  fontSize: 45,
                  color: color,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 10)
                  ])),
        ],
      ),
    );
  }

  void _move(int start) async {
    if (board[start] == 0 || animating) return;
    setState(() => animating = true);

    // СОХРАНЯЕМ ДЛЯ ОТМЕНЫ
//_lastBoardState = List.from(board);
//_lastTurnState = isP1Turn;
//_canUndo = true;
// Если это ход игрока, запоминаем состояние ДО начала хода
    if (widget.mode == GameMode.pvp || isP1Turn) {
      _lastBoardState = List.from(board);
      _lastTurnState = isP1Turn;
      _canUndo = true;
    }
    int stones = board[start];
    // НЕ обнуляем сразу! board[start] = 0 будет после запуска анимаций
    int curr = start;

    // Устанавливаем флаг, чтобы скрыть камни визуально в этой лунке
    setState(() {
      _activeMovePit = start;
    });

    // Запускаем звук для стартовой лунки
    HapticFeedback.lightImpact();

    // 1. РАСКЛАДЫВАЕМ КАМНИ С АНИМАЦИЕЙ ПОЛЁТА
    int stoneIndex = 0;
    List<int> targetPits = []; // Сохраняем целевые лунки для камней

    while (stones > 0) {
      curr = (curr + 1) % 14;
      // Пропуск чужого Калаха
      if (start < 6 && curr == 13) curr = 0;
      if (start > 6 && curr == 6) curr = 7;

      targetPits.add(curr);

      // Запускаем анимацию полёта камня
      _animateStoneFlight(start, curr, stoneIndex);

      stoneIndex++;
      stones--;
    }

    // Скрываем камни визуально в стартовой лунке на время полёта
    setState(() {
      board[start] = 0;
      _activeMovePit = null;
    });

    // Ждём завершения всех анимаций полёта
    int totalDelay = (stoneIndex - 1) * 500 + 800 + 300;
    await Future.delayed(Duration(milliseconds: totalDelay));

    // Атомарно: обновляем board и убираем все летящие камни в одном setState.
    // Между исчезновением летящего камня и появлением числа нет ни одного кадра.
    if (mounted) {
      setState(() {
        for (int pit in targetPits) {
          board[pit]++;
          lastDrop = pit;
        }
        captureAnimations.clear();
      });
    }

    // Звук приземления камней
    if (GameSettings.isSoundOn) {
      HapticFeedback.mediumImpact();
      // Можно добавить звуковой эффект через AudioManager
      // AudioManager().playStoneLanding();
    }

    // Даём время на финальную анимацию появления камней в лунке
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. ЛОГИКА ЗАХВАТА
    // ЛОГИКА ЗАХВАТА
    if (curr != 6 && curr != 13 && board[curr] == 1) {
      bool p1Owns = start < 6 && curr < 6;
      bool p2Owns = start > 6 && curr > 6 && curr < 13;

      if (p1Owns || p2Owns) {
        int opposite = 12 - curr;
        if (board[opposite] > 0) {
          int kalah = p1Owns ? 6 : 13;

          // 0. Скрываем камни в обеих лунках на время полёта, чтобы не было
          // визуального задвоения (старые камни + летящие поверх них)
          setState(() {
            _capturingPits = {opposite, curr};
          });

          // 1. Сначала запускаем визуальный полет
          _animateCapture(opposite, kalah); // Камни врага
          _animateCapture(curr, kalah); // Ваш последний камень

          HapticFeedback.mediumImpact();

          // 2. ЖДЕМ завершения анимации (в FlyingStone стоит duration 800ms)
          await Future.delayed(const Duration(milliseconds: 850));

          // 3. ТОЛЬКО ТЕПЕРЬ обновляем цифры на доске и снова показываем лунки
          setState(() {
            board[kalah] += board[opposite] + board[curr];
            board[opposite] = 0;
            board[curr] = 0;
            _capturingPits = {};
          });
        }
      }
    }

    // 3. ПРОВЕРКА ОКОНЧАНИЯ ИГРЫ
    if (_checkGameOver()) {
      // Собираем оставшиеся камни в Калахи (с анимацией полёта, а не мгновенным исчезновением)
      List<int> remainingP1 = [for (int i = 0; i < 6; i++) if (board[i] > 0) i];
      List<int> remainingP2 = [for (int i = 7; i < 13; i++) if (board[i] > 0) i];

      if (remainingP1.isNotEmpty || remainingP2.isNotEmpty) {
        setState(() {
          _capturingPits = {...remainingP1, ...remainingP2};
        });

        for (int i in remainingP1) {
          _animateCapture(i, 6);
        }
        for (int i in remainingP2) {
          _animateCapture(i, 13);
        }

        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 850));
      }

      setState(() {
        for (int i = 0; i < 6; i++) {
          board[6] += board[i];
          board[i] = 0;
        }
        for (int i = 7; i < 13; i++) {
          board[13] += board[i];
          board[i] = 0;
        }
        _capturingPits = {};
        animating = false;
      });

      // СОХРАНЯЕМ СТАТИСТИКУ (с учетом уровня сложности)
      // _saveFinalStats();

      await Future.delayed(const Duration(milliseconds: 500));
      _showGameOverDialog();
      return;
    }

    // 4. ПЕРЕДАЧА ХОДА (если не попали в свой Калах)
    if (!((start < 6 && curr == 6) || (start > 6 && curr == 13))) {
      isP1Turn = !isP1Turn;
    }

    // Финальная очистка флагов
    setState(() {
      animating = false;
      // НЕ очищаем captureAnimations! Каждая анимация удалится сама через onComplete
    });

    // Если ход ИИ
// Блок в конце метода _move
    if (!isP1Turn && widget.mode == GameMode.ai) {
      // 1. Сразу блокируем кнопку отмены
      setState(() => isAiThinking = true);

      await Future.delayed(const Duration(milliseconds: 800));

      // ТУТ ВАША ЛОГИКА ИЗ ФАЙЛА:
      int bestEval = -10000;
      int aiMove = -1;
      int depth = GameSettings.difficulty == Difficulty.easy
          ? 2
          : (GameSettings.difficulty == Difficulty.medium ? 4 : 6);

      for (int i = 7; i < 13; i++) {
        if (board[i] == 0) continue;
        var result = _simulateMoveDetailed(board, i);
        int eval =
        _minimax(result.board, depth - 1, result.extraTurn, -10000, 10000);
        if (eval > bestEval) {
          bestEval = eval;
          aiMove = i;
        }
      }

      // 2. Расчет окончен, снимаем блокировку
      setState(() => isAiThinking = false);

      if (aiMove != -1) {
        // _move(aiMove);
        // Внутри метода _move, в блоке, где ходит ИИ:
        if (!isP1Turn && widget.mode == GameMode.ai && !animating) {
          // setState(() => isAiThinking = true);

          // Ждем немного перед началом раздумий
          // await Future.delayed(const Duration(milliseconds: 600));

          _aiMove();
/*
          if (aiMove != -1) {
            // 1. Включаем подсветку (число станет белым и большим)
            setState(() {
              aiSelectedPit = aiMove;
              isAiThinking = false;
            });

            // 2. Ждем, пока игрок увидит, какую лунку выбрал ИИ
            await Future.delayed(const Duration(milliseconds: 800));

            // 3. Сбрасываем подсветку и запускаем движение камней
            setState(() {
              aiSelectedPit = null;
            });

            _move(aiMove);
             // Рекурсивный вызов для выполнения хода
          }*/
        }
      }
    }
  }

// отмена хода
  void _undoMove() {
    if (!_canUndo || _lastBoardState == null) return;

    setState(() {
      board = List.from(_lastBoardState!);
      isP1Turn = _lastTurnState!;

      _canUndo = false;
      animating = false; // ПРИНУДИТЕЛЬНО останавливаем анимации
      isAiThinking = false; // ПРИНУДИТЕЛЬНО останавливаем думы ИИ
      captureAnimations
          .clear(); // Очищаем старые анимации захвата, если они были
    });

    HapticFeedback.lightImpact(); // Добавим тактильный отклик
  }

  void _aiMove() async {
    if (!isAiThinking && !animating) {
      setState(() => isAiThinking = true);
      await Future.delayed(const Duration(milliseconds: 1000));

      int bestEval = -1000000;
      List<int> bestMoves = []; // Создаем список для хранения равноценных ходов

      // Настройка глубины в зависимости от выбранной сложности
      int depth = 4;
      if (GameSettings.difficulty == Difficulty.medium) depth = 5;
      if (GameSettings.difficulty == Difficulty.hard) depth = 8;

      // Проверяем все возможные ходы ИИ (лунки 7-12)
      for (int i = 7; i < 13; i++) {
        if (board[i] > 0) {
          var result = _simulateMoveDetailed(board, i);
          int eval = _minimax(
              result.board, depth, result.extraTurn, -1000000, 1000000);

          if (eval > bestEval) {
            bestEval = eval;
            bestMoves = [i]; // Нашли ход лучше — начинаем список заново
          } else if (eval == bestEval) {
            bestMoves.add(i); // Ход такой же крутой — добавляем в варианты
          }
        }
      }

      // Если нашли хотя бы один ход
      if (bestMoves.isNotEmpty) {
        // ВЫБИРАЕМ СЛУЧАЙНЫЙ ИЗ ЛУЧШИХ
        int finalMove = bestMoves[Random().nextInt(bestMoves.length)];
        _move(finalMove);
      }

      if (mounted) setState(() => isAiThinking = false);
    }
  }


// сложность ии
// Используем Record (новое в Dart), чтобы вернуть два значения сразу
  ({List<int> board, bool extraTurn}) _simulateMoveDetailed(
      List<int> b, int start) {
    List<int> newBoard = List.from(b);
    int stones = newBoard[start];
    newBoard[start] = 0;
    int curr = start;

    while (stones > 0) {
      curr = (curr + 1) % 14;
      // Пропуск чужой Калахи
      if (start < 6 && curr == 13) curr = 0;
      if (start > 6 && curr == 6) curr = 7;

      newBoard[curr]++;
      stones--;
    }

    bool extraTurn = (start < 6 && curr == 6) || (start > 6 && curr == 13);

    // Захват (Capture)
    if (!extraTurn && newBoard[curr] == 1) {
      bool ownSide = start < 6 ? curr < 6 : (curr > 6 && curr < 13);
      if (ownSide) {
        int opposite = 12 - curr;
        if (newBoard[opposite] > 0) {
          int kalah = start < 6 ? 6 : 13;
          newBoard[kalah] += newBoard[opposite] + 1;
          newBoard[opposite] = 0;
          newBoard[curr] = 0;
        }
      }
    }

    // Мы НЕ переносим остатки камней.
    // Но ИИ должен знать, что игра закончится, если чья-то сторона пуста.
    return (board: newBoard, extraTurn: extraTurn);
  }

  int _evaluatePosition(List<int> b) {
    // 1. Разница в Калахах
    int score = (b[13] - b[6]) * 50;

    // 2. БОНУС за доп. ходы
    for (int i = 7; i < 13; i++) {
      if (b[i] > 0 && (i + b[i]) % 14 == 13) {
        // Поднимаем с 40 до 150-200.
        // Теперь это ценнее, чем разница в 3-4 камня.
        score += 220;
      }
    }
/*
    // 3. Безопасность камней (близость к дому)
    for (int i = 7; i < 13; i++) {
      score += (b[i] * (i - 6));
    }
*/
// 3. Защита: штрафуем за пустые лунки на своей стороне (риск захвата)
    for (int i = 7; i < 13; i++) {
      if (b[i] == 0 && b[12 - i] > 0) {
        score -= 100; // ИИ будет стараться закрывать дыры
      }
    }

    // 4. Захват: поощряем возможность захватить камни врага
    for (int i = 7; i < 13; i++) {
      if (b[i] == 0 && b[12 - i] > 0) {
        // Если мы можем следующим ходом попасть сюда - это круто
        // (но это уже считает сам минимакс через дерево ходов)
      }
    }
    /* // 4. ЗАХВАТЫ
    for (int i = 0; i < 6; i++) {
      if (b[i] == 0 && b[12 - i] > 0) score -= (b[12 - i] * 15);
      if (b[12 - i] == 0 && b[i] > 0) score += (b[i] * 12);
    }*/

    return score;
  }

  // Алгоритм Minimax с Альфа-Бето отсечением
// Оптимизированный Minimax с Alpha-Beta отсечением
  int _minimax(List<int> currentBoard, int depth, bool isMaximizing, int alpha,
      int beta) {
    if (depth == 0 || _isTerminal(currentBoard)) {
      return _evaluatePosition(currentBoard);
    }

    if (isMaximizing) {
      int maxEval = -10000;
      // Проверяем ходы ИИ (справа налево обычно эффективнее для отсечения)
      for (int i = 12; i >= 7; i--) {
        if (currentBoard[i] == 0) continue;

        var result = _simulateMoveDetailed(currentBoard, i);
        // Если доп. ход, глубина уменьшается медленнее (или не уменьшается)
        int eval = _minimax(
            result.board,
            result.extraTurn
                ? depth
                : depth - 1, // если тормозит то возвращаем depth - 1,
            //result.extraTurn ? depth - 1 : depth - 1,
            result.extraTurn,
            alpha,
            beta);

        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // Вот оно, отсечение!
      }
      return maxEval;
    } else {
      int minEval = 10000;
      for (int i = 0; i < 6; i++) {
        if (currentBoard[i] == 0) continue;

        var result = _simulateMoveDetailed(currentBoard, i);
        int eval = _minimax(
            result.board,
            result.extraTurn ? depth - 1 : depth - 1,
            !result.extraTurn,
            alpha,
            beta);

        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break; // И здесь отсечение!
      }
      return minEval;
    }
  }

  List<int> _simulateMove(List<int> b, int start) {
    List<int> newBoard = List.from(b);
    int stones = newBoard[start];
    newBoard[start] = 0;
    int curr = start;

    while (stones > 0) {
      curr = (curr + 1) % 14;
      // Правила пропуска чужих Калахов
      if (start < 6 && curr == 13) curr = 0;
      if (start > 6 && curr == 6) curr = 7;
      newBoard[curr]++;
      stones--;
    }

    // Логика захвата в симуляции
    if (curr != 6 && curr != 13 && newBoard[curr] == 1) {
      bool ownSide = start < 6 ? curr < 6 : (curr > 6 && curr < 13);
      if (ownSide) {
        int opposite = 12 - curr;
        if (newBoard[opposite] > 0) {
          int kalah = start < 6 ? 6 : 13;
          newBoard[kalah] += newBoard[opposite] + 1;
          newBoard[opposite] = 0;
          newBoard[curr] = 0;
        }
      }
    }
    return newBoard;
  }

  bool _isTerminal(List<int> b) {
    return b.sublist(0, 6).every((v) => v == 0) ||
        b.sublist(7, 13).every((v) => v == 0);
  }
}