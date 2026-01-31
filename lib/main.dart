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

// import 'space_background.dart';

// my_email: prudnikov.michael@aol.com
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await AudioManager().init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.black45, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Difficulty.values
            .map((d) => ChoiceChip(
                  label: Text(d.name.toUpperCase(),
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

    late Widget flying;
    flying = FlyingStone(
      start: startPos,
      end: endPos,
      stoneIndex: stoneIndex, // Передаём индекс для задержки
      onComplete: () {
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
    void saveGame(GameRecord newRecord) async {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('game_history') ?? [];
      history.insert(0, json.encode(newRecord.toJson())); // Добавляем в начало
      await prefs.setStringList('game_history', history);
    }

    var txt = GameSettings.labels[GameSettings.lang] ??
        GameSettings.labels[Language.en]!;

    // Берем только то, что уже лежит в Калахах
    int p1Score = board[6];
    int p2Score = board[13];
    _saveFinalStatsManual(p1Score, p2Score);
    // _saveFinalStatsManual(p1Score, p2Score);
    // Очищаем лунки визуально для красоты, но НЕ прибавляем их к счету
    for (int i = 0; i < 14; i++) {
      if (i != 6 && i != 13) board[i] = 0;
    }

    setState(() {}); // Обновляем доску, чтобы она стала пустой

    // Определяем победителя на основе текущих Калахов
    String winner;
    if (p1Score > p2Score) {
      AudioManager().playSfx(AudioManager.winSound);
      winner = txt['p1_wins']!;
    } else if (p2Score > p1Score) {
      AudioManager().playSfx(AudioManager.loseSound);
      winner = widget.mode == GameMode.ai ? txt['ai_wins']! : txt['p2_wins']!;
    } else {
      AudioManager().playSfx(AudioManager.winSound);
      winner = txt['draw']!;
    }
    _magicRotationController.repeat();
    // ... далее код вызова самого Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          // 1. Слой "Магического вихря"
          IgnorePointer(
            child: Center(
              child: const StoneConfetti(),
            ),
          ),

          // 2. Слой самого диалога
          AlertDialog(
            backgroundColor: const Color(0xFF3E2723).withOpacity(0.95),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 10),
                Text(txt['game_over']!,
                    style: const TextStyle(color: Colors.amber)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  winner,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text('${txt['p1']}: $p1Score',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.greenAccent)),
                // Используем ai_short или ai_label, как мы исправляли ранее
                Text(
                    '${widget.mode == GameMode.ai ? (txt['ai_short'] ?? txt['ai']) : txt['p2']}: $p2Score',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.orangeAccent)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    board = List.filled(14, 4);
                    board[6] = 0;
                    board[13] = 0;
                    isP1Turn = true;
                  });
                },
                child: Text(txt['play_again']!,
                    style: const TextStyle(color: Colors.amber)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Закрыть диалог
                  Navigator.pop(context); // Выйти в меню
                },
                child: Text(txt['menu']!,
                    style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
  Widget _buildStones(int count, bool isKalah) {
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
        double randomRadius = sqrt(rnd.nextDouble()) * maxRadius;
        double randomAngle = rnd.nextDouble() * 2 * pi;

        var colors = stoneColors[index % stoneColors.length];

        return Transform.translate(
          offset: Offset(
              cos(randomAngle) * randomRadius, sin(randomAngle) * randomRadius),
          child: Container(
            width: 16, // Увеличили на 2 пикселя (было 10) Размер камней
            height: 16, // Увеличили на 2 пикселя
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
                        child: Row(
                          children: [
                            // Твоя кнопка музыки
                            IconButton(
                              icon: Icon(
                                GameSettings.isMusicOn
                                    ? Icons.music_note
                                    : Icons.music_off,
                                color: Colors.amber,
                                size: 35,
                              ),
                              onPressed: () {
                                setState(() {
                                  GameSettings.isMusicOn =
                                      !GameSettings.isMusicOn;
                                  if (GameSettings.isMusicOn) {
                                    AudioManager().playMusic();
                                  } else {
                                    AudioManager().stopMusic();
                                  }
                                });
                              },
                            ),
                            const SizedBox(
                                width:
                                    10), // Небольшой отступ между музыкой и отменой

                            // Кнопка ОТМЕНЫ хода (появляется только когда есть что отменять)
                            if (_canUndo &&
                                !animating &&
                                !isAiThinking &&
                                aiSelectedPit == null)
                              IconButton(
                                icon: const Icon(Icons.undo,
                                    color: Colors.amber, size: 35),
                                onPressed: _undoMove,
                              ),
                            /*  if (_canUndo && !animating && !isAiThinking) 
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.amber, size: 35),
          tooltip: 'Undo',
          onPressed: _undoMove,
        ),*/
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // СЛОЙ 2: АНИМАЦИИ ПОЛЕТА КАМНЕЙ
            // Этот список разворачивается поверх всей доски
            ...captureAnimations,

            // СЛОЙ 3: КОНФЕТТИ (Появляется только в конце)
            // Мы его уже прописывали в _showGameOverDialog, но можно продублировать и здесь,
            // если хочешь управлять им через переменную состояния.
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
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        gradient: RadialGradient(
          radius: 1.5,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.4), // Тень по краям внутри доски
          ],
        ),
      ),
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
      trigger: _shakeTriggers[i] ?? false,
      onComplete: () {
        if (mounted) {
          setState(() {
            _shakeTriggers[i] = false;
          });
        }
      },
      child: GestureDetector(
        key: pitKeys[i],
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
                if (i != _activeMovePit) _buildStones(board[i], false),
                if (GameSettings.visualMode != VisualMode.stonesOnly)
                  PulseAnimation(
                    enabled: isHighlighted,
                    child: AnimatedDefaultTextStyle(
                      // ЗАМЕНА: Используем стандартный Curves.linear или Curves.easeInOut
                      // Они никогда не выдают отрицательных значений в процессе анимации
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: GoogleFonts.cinzel(
                        textStyle: TextStyle(
                          color: isHighlighted
                              ? Colors.white
                              : (i < 6
                                  ? Colors.amber[100]
                                  : Colors.orange[100]),
                          fontSize: isHighlighted ? 44 : 28,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            // 1. Стабильная тень
                            const Shadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                            // 2. Магическая тень (Защищенная)
                            Shadow(
                              color: isHighlighted
                                  ? Colors.white
                                  : (active
                                      ? (i < 6 ? Colors.amber : Colors.orange)
                                      : (i < 6
                                          ? Colors.amber.withOpacity(0)
                                          : Colors.orange.withOpacity(0))),
                              // Убираем сложные вычисления радиуса, оставляем простые double
                              blurRadius:
                                  isHighlighted ? 25.0 : (active ? 12.0 : 0.0),
                            ),
                          ],
                        ),
                      ),
                      child: Text('${board[i]}'),
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
          _buildStones(board[i], true),
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

    // Обнуляем стартовую лунку СРАЗУ после запуска всех анимаций
    setState(() {
      board[start] = 0;
      _activeMovePit = null; // Сбрасываем флаг
    });

    // Ждём завершения всех анимаций полёта
    // Время = базовая задержка + время на последний камень + анимация
    int totalDelay = (stoneIndex - 1) * 100 +
        800 +
        200; // 100ms задержка между камнями + 800ms полёт + 200ms буфер
    await Future.delayed(Duration(milliseconds: totalDelay));

    // Обновляем доску после завершения всех анимаций
    setState(() {
      for (int pit in targetPits) {
        board[pit]++;
        lastDrop = pit;
        // Запускаем дрожание для каждой лунки, в которую упал камень
        _shakeTriggers[pit] = true;
      }
      // Принудительно очищаем все анимации на всякий случай
      captureAnimations.clear();
    });

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

          // 1. Сначала запускаем визуальный полет
          _animateCapture(opposite, kalah); // Камни врага
          _animateCapture(curr, kalah); // Ваш последний камень

          HapticFeedback.mediumImpact();

          // 2. ЖДЕМ завершения анимации (в FlyingStone стоит duration 800ms)
          await Future.delayed(const Duration(milliseconds: 850));

          // 3. ТОЛЬКО ТЕПЕРЬ обновляем цифры на доске
          setState(() {
            board[kalah] += board[opposite] + board[curr];
            board[opposite] = 0;
            board[curr] = 0;
          });
        }
      }
    }

    // 3. ПРОВЕРКА ОКОНЧАНИЯ ИГРЫ
    if (_checkGameOver()) {
      // Собираем оставшиеся камни в Калахи
      setState(() {
        /* for (int i = 0; i < 6; i++) {
        board[6] += board[i];
        board[i] = 0;
      }
      for (int i = 7; i < 13; i++) {
        board[13] += board[i];
        board[i] = 0;
      }
      */
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

    setState(() => animating = false);

    // Если ход ИИ
// Блок в конце метода _move
    if (!isP1Turn && widget.mode == GameMode.ai) {
      // 1. Сразу блокируем кнопку отмены
      setState(() => isAiThinking = true);

      await Future.delayed(const Duration(milliseconds: 800));

      // ТУТ ВАША ЛОГИКА ИЗ ФАЙЛА:
      int bestEval = -10000;
      int aiMove = -1;
      int depth = GameSettings.difficulty == 'Easy'
          ? 2
          : (GameSettings.difficulty == 'Medium' ? 4 : 6);

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

// Основная функция хода ИИ
  void _aiMove() async {
    if (!mounted || isP1Turn || animating) return;

    setState(() {
      isAiThinking = true;
      aiSelectedPit = null;
    });

    int maxDepth;
    switch (GameSettings.difficulty) {
      case Difficulty.easy:
        maxDepth = 1;
        break;
      case Difficulty.medium:
        maxDepth = 4;
        break;
      case Difficulty.hard:
        maxDepth = 8;
        break;
      default:
        maxDepth = 2;
    }

    // Имитация раздумий (пока мигает текст сверху)
    await Future.delayed(const Duration(milliseconds: 1000));

    int bestMove = -1;
    int bestValue = -20000;
    List<int> currentBoard = List.from(board);

    for (int i = 7; i < 13; i++) {
      if (currentBoard[i] > 0) {
        var result = _simulateMoveDetailed(currentBoard, i);
        int moveValue =
            _minimax(result.board, maxDepth, result.extraTurn, -20000, 20000);

        if (moveValue > bestValue) {
          bestValue = moveValue;
          bestMove = i;
        }
      }
    }

    if (bestMove != -1 && mounted) {
      // ИИ выбрал лунку
      setState(() {
        isAiThinking = false;
        aiSelectedPit =
            bestMove; // В этот момент AnimatedDefaultTextStyle в buildPit сработает!
      });

      // Даем игроку время увидеть увеличенную цифру и белое свечение
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      // Убираем подсветку ПЕРЕД началом движения камней
      setState(() {
        aiSelectedPit = null;
      });

      _move(bestMove); // Запускаем анимацию разлета камней

      // Ждем завершения хода, чтобы убрать подсветку последней лунки (желтый ободок)
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        setState(() {
          lastDrop = -1;
        });
      }
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

/*
int _evaluatePosition(List<int> b) {
  // 1. Базовый счет (разница в Калахах) - вес 15
  int score = (b[13] - b[6]) * 15;

  // 2. Удержание камней на своей стороне - вес 2
  // Это мешает игре закончиться слишком рано, если ИИ выигрывает по позиции
  int aiSide = 0;
  int playerSide = 0;
  for (int i = 7; i < 13; i++) aiSide += b[i];
  for (int i = 0; i < 6; i++) playerSide += b[i];
  score += (aiSide - playerSide) * 2;

  // 3. БОНУС ЗА БЛИЗОСТЬ К ПОБЕДЕ
  // Если у ИИ уже больше половины всех камней ( > 24), он должен играть максимально агрессивно
  if (b[13] > 24) score += 100;

  // 4. ОХОТА ЗА ЗАХВАТОМ (Capture)
  // Проверяем, может ли ИИ в один ход сделать захват
  for (int i = 7; i < 13; i++) {
    if (b[i] == 0) {
      int opposite = 12 - i;
      if (b[opposite] > 0) {
        score += (b[opposite] * 5); // Очень высокий приоритет захвата
      }
    }
  }

  // 5. ЗАЩИТА (Anti-Capture)
  // ИИ должен бояться оставлять свои полные лунки напротив твоих пустых
  for (int i = 0; i < 6; i++) {
    if (b[i] == 0) {
      int opposite = 12 - i;
      if (b[opposite] > 0) {
        score -= (b[opposite] * 6); // Штраф еще выше, чем бонус за захват
      }
    }
  }

  return score;
}
*/
// Функция оценки (душа уровня Hard)
  int _evaluatePosition(List<int> b) {
    // Добавляем элемент случайности в зависимости от сложности
    int randomness = 0;
    if (GameSettings.difficulty == Difficulty.easy) {
      // Ошибка от -50 до +50 (всего диапазон 101 число)
      randomness = Random().nextInt(80) - 5; // Ошибка до 50 очков
    } else if (GameSettings.difficulty == Difficulty.medium) {
      // Ошибка от -20 до +20 (всего диапазон 41 число)
      randomness = Random().nextInt(30) - 2;
    }
    // 1. Разница в Калахах (основной вес)
    int score = (b[13] - b[6]) * 40 +
        randomness; /* Чтобы он стал «глупее», в твоем методе _evaluatePosition просто поменяй множитель в первой строке: int score = (b[13] - b[6]) * 10; (вместо 100). Тогда он будет меньше дорожить камнями в Калахе.*/

    // 2. БОНУС за возможность сделать доп. ход прямо сейчас
    // ИИ должен "обожать" цепочки ходов
    for (int i = 7; i < 13; i++) {
      if (b[i] > 0 && (i + b[i]) % 14 == 13) {
        score += 40; // Даем высокий приоритет доп. ходам
      }
    }

    // 3. БОНУС за близость к своей Калахе
    // Чем ближе камни к дому, тем они безопаснее
    for (int i = 7; i < 13; i++) {
      score += (b[i] * (i - 6));
    }

    // 4. ЗАХВАТЫ (Охота и Защита)
    for (int i = 0; i < 6; i++) {
      // Если у игрока пустая лунка и напротив есть камни ИИ
      if (b[i] == 0 && b[12 - i] > 0) {
        score -= (b[12 - i] * 15); // Штраф: ИИ рискует потерять камни
      }
      // Если у ИИ пустая лунка и напротив есть камни игрока
      if (b[12 - i] == 0 && b[i] > 0) {
        score += (b[i] * 12); // Бонус: ИИ может захватить
      }
    }

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
            result.extraTurn ? depth - 1 : depth - 1,
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
