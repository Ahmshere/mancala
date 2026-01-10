import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_manager.dart';

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

class _MainMenuState extends State<MainMenu> {
  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          var txt = GameSettings.labels[GameSettings.lang]!;
          return AlertDialog(
            backgroundColor: const Color(0xFF3E2723),
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
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Difficulty.values.map((d) => ChoiceChip(
          label: Text(d.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
          selected: GameSettings.difficulty == d,
          onSelected: (s) => setState(() => GameSettings.difficulty = d),
          selectedColor: Colors.amber.withOpacity(0.3),
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
          gradient: RadialGradient(colors: [Color(0xFF5D4037), Color(0xFF1B100E)], radius: 1.5),
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
                        Text(txt['title']!, style: TextStyle(fontSize: isLandscape ? 45 : 55, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F), letterSpacing: 4)),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _menuBtn(txt['pvp']!, GameMode.pvp, isLandscape),
                            const SizedBox(height: 15),
                            _menuBtn(txt['ai']!, GameMode.ai, isLandscape),
                            const SizedBox(height: 25),
                            _buildDifficultyChips(),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(icon: const Icon(Icons.settings, color: Color(0xFFFFD54F), size: 35), onPressed: _openSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuBtn(String text, GameMode mode, bool isLandscape) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8D6E63), 
        minimumSize: Size(isLandscape ? 200 : 260, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MancalaGame(mode: mode))),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

/* ===================== ИГРОВОЙ ПРОЦЕСС ===================== */

class MancalaGame extends StatefulWidget {
  final GameMode mode;
  const MancalaGame({super.key, required this.mode});
  @override
  State<MancalaGame> createState() => _MancalaGameState();
}

class _MancalaGameState extends State<MancalaGame> {
  List<int> board = List.filled(14, 4);
  bool isP1Turn = true;
  bool animating = false;
  int? lastDrop;

  @override
  void initState() { super.initState(); board[6] = 0; board[13] = 0; }

// рисую камни
Widget _buildStones(int count, bool isKalah) {
  if (GameSettings.visualMode == VisualMode.numbersOnly || count == 0) {
    return const SizedBox();
  }

  // Палитра "стеклянных" камней
  const stoneColors = [
    [Colors.blueGrey, Colors.blueGrey],     // Классический
    [Colors.teal, Colors.tealAccent],       // Зеленоватый
    [Colors.indigo, Colors.lightBlue],      // Голубоватый
    [Colors.brown, Colors.orangeAccent],    // Янтарный
    [Colors.redAccent, Colors.red],         // Красноватый
  ];

  int visibleStones = min(count, 12);
  double radius = isKalah ? 30.0 : 25.0;

  return Stack(
    alignment: Alignment.center,
    children: List.generate(visibleStones, (index) {
      double angle = (2 * pi / visibleStones) * index;
      
      // Выбираем цвет на основе индекса, чтобы он был постоянным для этого камня
      var baseColor = stoneColors[index % stoneColors.length][0];
      var accentColor = stoneColors[index % stoneColors.length][1];

      return Transform.translate(
        offset: Offset(cos(angle) * radius, sin(angle) * radius),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.9), // Яркий блик
                accentColor.withOpacity(0.7),   // Светлый оттенок
                baseColor.withOpacity(0.9),     // Глубокий цвет
              ],
              center: const Alignment(-0.4, -0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 2,
                offset: const Offset(1, 1),
              )
            ],
          ),
        ),
      );
    }),
  );
}

  @override
  Widget build(BuildContext context) {
    var txt = GameSettings.labels[GameSettings.lang]!;
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B18),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(isP1Turn ? txt['p1_turn']! : (widget.mode == GameMode.ai ? txt['ai_turn']! : txt['p2_turn']!),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
            Expanded(child: Center(child: FittedBox(child: _buildBoard()))),
            TextButton.icon(
              onPressed: () => Navigator.pop(context), 
              icon: const Icon(Icons.arrow_back), 
              label: Text(txt['menu']!)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(40), border: Border.all(width: 8, color: const Color(0xFF3E2723))),
      child: Row(
        children: [
          _buildKalah(13, Colors.orangeAccent),
          Column(
            children: [
              Row(children: List.generate(6, (i) => _buildPit(12 - i))),
              const SizedBox(height: 30),
              Row(children: List.generate(6, (i) => _buildPit(i))),
            ],
          ),
          _buildKalah(6, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildPit(int i) {
    bool active = (isP1Turn && i < 6) || (!isP1Turn && widget.mode == GameMode.pvp && i > 6 && i < 13);
    return GestureDetector(
      onTap: () => active && !animating ? _move(i) : null,
      child: Container(
        width: 85, height: 85, margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: lastDrop == i ? Colors.white12 : Colors.black26, 
          shape: BoxShape.circle, 
          border: Border.all(color: active ? Colors.white70 : Colors.black45, width: 2)
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildStones(board[i], false),
            Text("${board[i]}", 
              style: const TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFFFFD54F),
                shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2))]
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKalah(int i, Color color) {
    return Container(
      width: 95, height: 210, margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(45), border: Border.all(color: color.withOpacity(0.5))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStones(board[i], true),
          const SizedBox(height: 10),
          Text("${board[i]}", 
            style: TextStyle(
              fontSize: 40, color: color, fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 10)]
            )
          ),
        ],
      ),
    );
  }

  void _move(int start) async {
    if (board[start] == 0) return;
    setState(() => animating = true);
    int stones = board[start]; board[start] = 0;
    int curr = start;
    while (stones > 0) {
      curr = (curr + 1) % 14;
      if (start < 6 && curr == 13) curr = 0;
      if (start > 6 && curr == 6) curr = 7;
      HapticFeedback.selectionClick();
      setState(() { board[curr]++; lastDrop = curr; stones--; });
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!((start < 6 && curr == 6) || (start > 6 && curr == 13))) {
      isP1Turn = !isP1Turn;
    }
    setState(() => animating = false);
    if (!isP1Turn && widget.mode == GameMode.ai) _aiMove();
  }

  void _aiMove() async {
    await Future.delayed(const Duration(milliseconds: 800));
    for (int i = 7; i < 13; i++) {
      if (board[i] > 0) { _move(i); break; }
    }
  }
}