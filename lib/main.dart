import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animations.dart'; // Новый файл для анимаций

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)),
    );

    _titleController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _openRules() {
    var txt = GameSettings.labels[GameSettings.lang]!;
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
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
      ),
    ),
  ),
),
    
        
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(txt['close']!, style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      
    );
    
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          var txt = GameSettings.labels[GameSettings.lang]!;
          return AlertDialog(
            backgroundColor: const Color(0xFF3E2723).withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(txt['settings']!, style: const TextStyle(color: Colors.amber)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<Language>(
                  value: GameSettings.lang,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF4E342E),
                  items: Language.values.map((l) => DropdownMenuItem(value: l, child: Text(l.name.toUpperCase()))).toList(),
                  onChanged: (v) { 
                    setState(() => GameSettings.lang = v!); 
                    setDialogState(() {}); 
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: Text(GameSettings.visualMode == VisualMode.numbersOnly ? txt['vis_1']! : txt['vis_2']!),
                  value: GameSettings.visualMode == VisualMode.stonesAndNumbers,
                  activeColor: Colors.amber,
                  onChanged: (v) {
                    setState(() => GameSettings.visualMode = v ? VisualMode.stonesAndNumbers : VisualMode.numbersOnly);
                    setDialogState(() {});
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildDifficultyChips() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Difficulty.values.map((d) => ChoiceChip(
          label: Text(d.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
          selected: GameSettings.difficulty == d,
          onSelected: (s) => setState(() => GameSettings.difficulty = d),
          selectedColor: Colors.amber.withOpacity(0.4),
          backgroundColor: Colors.transparent,
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var txt = GameSettings.labels[GameSettings.lang]!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  bool isLandscape = orientation == Orientation.landscape;
                  return Center(
                    child: Flex(
                      direction: isLandscape ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // АНИМИРОВАННОЕ НАЗВАНИЕ
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Stack(
                                      children: [
                                        // Магическое свечение
                                        Text(
                                          txt['title']!,
                                          style: GoogleFonts.cinzel(
                                            textStyle: TextStyle(
                                              fontSize: isLandscape ? 50 : 65,
                                              fontWeight: FontWeight.normal,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = 8
                                                ..color = Colors.amber.withOpacity(_glowAnimation.value * 0.5)
                                                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
                                              letterSpacing: 8,
                                            ),
                                          ),
                                        ),
                                        // Основной текст
                                        Text(
                                          txt['title']!,
                                          style: GoogleFonts.cinzel(
                                            textStyle: TextStyle(
                                              fontSize: isLandscape ? 50 : 65,
                                              fontWeight: FontWeight.normal,
                                              color: const Color(0xFFFFD54F),
                                              letterSpacing: 8,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.8),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 5),
                                                ),
                                                const Shadow(
                                                  color: Colors.orangeAccent,
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _menuBtn(txt['pvp']!, GameMode.pvp, isLandscape),
                            const SizedBox(height: 15),
                            _menuBtn(txt['ai']!, GameMode.ai, isLandscape),
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
            // Кнопка правил
            Positioned(
              top: 50,
              left: 25,
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Color(0xFFFFD54F), size: 40),
                onPressed: _openRules,
              ),
            ),
            // Кнопка настроек
            Positioned(
              top: 50,
              right: 25,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFFFFD54F), size: 40),
                onPressed: _openSettings,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "version: ${GameSettings.appVersion}", 
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuBtn(String text, GameMode mode, bool isLandscape) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8D6E63).withOpacity(0.9), 
        minimumSize: Size(isLandscape ? 220 : 280, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24))
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MancalaGame(mode: mode))),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

class _MancalaGameState extends State<MancalaGame> with TickerProviderStateMixin {
  List<int> board = List.filled(14, 4);
  bool isP1Turn = true;
  bool animating = false;
  int? lastDrop;
  late AnimationController _stoneAnimController;
void _confirmExit() {
    var txt = GameSettings.labels[GameSettings.lang]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(txt['exit_confirm_title'] ?? "Exit?", style: const TextStyle(color: Colors.amber)),
        content: Text(txt['exit_confirm_desc'] ?? "Progress will be lost.", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(txt['close']!, style: const TextStyle(color: Colors.white70))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем этот диалог
              Navigator.pop(context); // Возвращаемся в Главное меню
            }, 
            child: Text(txt['menu']!, style: const TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
  @override
  void initState() { 
    super.initState(); 
    board[6] = 0; 
    board[13] = 0;
    _stoneAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _stoneAnimController.dispose();
    super.dispose();
  }

  // Проверка окончания игры
  bool _checkGameOver() {
    bool p1Empty = board.sublist(0, 6).every((v) => v == 0);
    bool p2Empty = board.sublist(7, 13).every((v) => v == 0);
    return p1Empty || p2Empty;
  }
void _showGameOverDialog() {
    var txt = GameSettings.labels[GameSettings.lang]!;
    
    // Берем только то, что уже лежит в Калахах
    int p1Score = board[6];
    int p2Score = board[13];
    
    // Очищаем лунки визуально для красоты, но НЕ прибавляем их к счету
    for (int i = 0; i < 14; i++) {
      if (i != 6 && i != 13) board[i] = 0;
    }
    
    setState(() {}); // Обновляем доску, чтобы она стала пустой

    // Определяем победителя на основе текущих Калахов
    String winner;
    if (p1Score > p2Score) {
      winner = txt['p1_wins']!;
    } else if (p2Score > p1Score) {
      winner = widget.mode == GameMode.ai ? txt['ai_wins']! : txt['p2_wins']!;
    } else {
      winner = txt['draw']!;
    }
    
    // ... далее код вызова самого Dialog
 showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => Stack(
    children: [
      // 1. Слой конфетти (будет летать на заднем фоне за диалогом и по всему экрану)
      const IgnorePointer(
        child: StoneConfetti(),
      ),
      
      // 2. Слой самого диалога
      AlertDialog(
        backgroundColor: const Color(0xFF3E2723).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 10),
            Text(txt['game_over']!, style: const TextStyle(color: Colors.amber)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(winner, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text('${txt['p1']}: $p1Score', 
              style: const TextStyle(fontSize: 18, color: Colors.greenAccent)),
            // Используем ai_short или ai_label, как мы исправляли ранее
            Text('${widget.mode == GameMode.ai ? (txt['ai_short'] ?? txt['ai']) : txt['p2']}: $p2Score', 
              style: const TextStyle(fontSize: 18, color: Colors.orangeAccent)),
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
            child: Text(txt['play_again']!, style: const TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрыть диалог
              Navigator.pop(context); // Выйти в меню
            },
            child: Text(txt['menu']!, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    ],
  ),

    );
  }

  // КРУГОВОЕ РАСПРЕДЕЛЕНИЕ КАМНЕЙ С АНИМАЦИЕЙ
 Widget _buildStones(int count, bool isKalah) {
    if (GameSettings.visualMode == VisualMode.numbersOnly || count == 0) return const SizedBox();

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
        // Используем Random с фиксированным зерном (seed), 
        // чтобы камни в конкретной лунке лежали всегда в одних и тех же местах
        // final rnd = Random(index * 100); 
        final rnd = Random(index * 100 + count);
        
        // Хаотичное смещение от центра
        //double randomRadius = rnd.nextDouble() * maxRadius;
        //double randomAngle = rnd.nextDouble() * 2 * pi;
        double randomRadius = sqrt(rnd.nextDouble()) * maxRadius; 
        double randomAngle = rnd.nextDouble() * 2 * pi;
        
        var colors = stoneColors[index % stoneColors.length];

        return Transform.translate(
          offset: Offset(
            cos(randomAngle) * randomRadius, 
            sin(randomAngle) * randomRadius
          ),
          child: Container(
            width: 12,  // Увеличили на 2 пикселя (было 10)
            height: 12, // Увеличили на 2 пикселя
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
                  offset: const Offset(1.5, 1.5)
                )
              ],
            ),
          ),
        );
      }),
    );
  }

void _openRules() {
    var txt = GameSettings.labels[GameSettings.lang]!;
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
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(txt['close']!, style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
 @override
  Widget build(BuildContext context) {
    var txt = GameSettings.labels[GameSettings.lang]!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(); // Вызываем подтверждение выхода
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: SafeArea(
              child: Stack( // Используем Stack для наложения кнопки помощи
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        isP1Turn ? txt['p1_turn']! : (widget.mode == GameMode.ai ? txt['ai_turn']! : txt['p2_turn']!),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))
                      ),
                      Expanded(child: Center(child: FittedBox(child: _buildBoard()))),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextButton.icon(
                          onPressed: _confirmExit, // Теперь вызываем подтверждение
                          icon: const Icon(Icons.exit_to_app, color: Colors.white70), 
                          label: Text(txt['menu']!, style: const TextStyle(color: Colors.white70))
                        ),
                      ),
                    ],
                  ),
                  // САМА КНОПКА ИНСТРУКЦИИ
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.amber, size: 35),
                      onPressed: _openRules, // Открывает правила со скроллбаром
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037).withOpacity(0.8), 
        borderRadius: BorderRadius.circular(50), 
        border: Border.all(width: 10, color: const Color(0xFF3E2723)),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)]
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

  Widget _buildPit(int i) {
    bool active = (isP1Turn && i < 6 && board[i] > 0) || 
                  (!isP1Turn && widget.mode == GameMode.pvp && i > 6 && i < 13 && board[i] > 0);
    
    return GestureDetector(
      onTap: () => active && !animating ? _move(i) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90, height: 90, margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: lastDrop == i ? Colors.white10 : Colors.black38, 
          shape: BoxShape.circle, 
          border: Border.all(
            color: active ? Colors.amber : Colors.black45, 
            width: active ? 4 : 3
          ),
          boxShadow: active 
            ? [const BoxShadow(color: Colors.amber, blurRadius: 8, spreadRadius: 1)]
            : [const BoxShadow(color: Colors.black26, blurRadius: 4)]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildStones(board[i], false),
            Text("${board[i]}", 
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F),
              shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2))])),
          ],
        ),
      ),
    );
  }

  Widget _buildKalah(int i, Color color) {
    return Container(
      width: 100, height: 240, margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.black45, 
        borderRadius: BorderRadius.circular(50), 
        border: Border.all(color: color.withOpacity(0.6), width: 3)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStones(board[i], true),
          const SizedBox(height: 15),
          Text("${board[i]}", 
            style: TextStyle(fontSize: 45, color: color, fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 10)])),
        ],
      ),
    );
  }

  void _move(int start) async {
    if (board[start] == 0 || animating) return;
    setState(() => animating = true);
    
    int stones = board[start]; 
    board[start] = 0;
    int curr = start;
    
    while (stones > 0) {
      curr = (curr + 1) % 14;
      if (start < 6 && curr == 13) curr = 0;
      if (start > 6 && curr == 6) curr = 7;
      
      HapticFeedback.lightImpact();
      _stoneAnimController.forward(from: 0);
      
      setState(() { 
        board[curr]++; 
        lastDrop = curr; 
        stones--; 
      });
      
      await Future.delayed(const Duration(milliseconds: 180));
    }
       
    // ЛОГИКА ЗАХВАТА:
    // 1. Последний камень упал в лунку игрока (0-5 для P1, 7-12 для P2)
    // 2. В этой лунке до этого было 0 камней (теперь стал 1)
    // 3. В противоположной лунке есть камни
    if (curr != 6 && curr != 13 && board[curr] == 1) {
      bool p1Owns = start < 6 && curr < 6;
      bool p2Owns = start > 6 && curr > 6 && curr < 13;

      if (p1Owns || p2Owns) {
        int opposite = 12 - curr;
        if (board[opposite] > 0) {
          // Забираем всё в Калаху текущего игрока
          int kalah = p1Owns ? 6 : 13;
          board[kalah] += board[opposite] + board[curr];
          board[opposite] = 0;
          board[curr] = 0;
          HapticFeedback.mediumImpact(); // Сильный виброотклик при захвате
        }
      }
    }

    
    
    // Проверка окончания игры
    if (_checkGameOver()) {
      setState(() => animating = false);
      await Future.delayed(const Duration(milliseconds: 500));
      _showGameOverDialog();
      return;
    }
    
    if (!((start < 6 && curr == 6) || (start > 6 && curr == 13))) {
      isP1Turn = !isP1Turn;
    }
    
    setState(() => animating = false);
    
    if (!isP1Turn && widget.mode == GameMode.ai) {
      _aiMove();
    }
  }

  void _aiMove() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Проверяем, есть ли ходы
    bool hasMove = false;
    for (int i = 7; i < 13; i++) {
      if (board[i] > 0) {
        hasMove = true;
        _move(i);
        break;
      }
    }
    
    // Если ходов нет, игра окончена
    if (!hasMove && !animating) {
      await Future.delayed(const Duration(milliseconds: 500));
      _showGameOverDialog();
    }
  }
}