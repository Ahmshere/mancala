import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Фиксируем ориентации для комфортной игры
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
                        Text(txt['title']!, 
                          style: TextStyle(
                            fontSize: isLandscape ? 50 : 60, 
                            fontWeight: FontWeight.bold, 
                            color: const Color(0xFFFFD54F), 
                            letterSpacing: 6,
                            shadows: const [Shadow(color: Colors.black, blurRadius: 15)]
                          )
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
            Positioned(
              top: 50,
              right: 25,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFFFFD54F), size: 40),
                onPressed: _openSettings,
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

class _MancalaGameState extends State<MancalaGame> {
  List<int> board = List.filled(14, 4);
  bool isP1Turn = true;
  bool animating = false;
  int? lastDrop;

  @override
  void initState() { super.initState(); board[6] = 0; board[13] = 0; }

  // КРУГОВОЕ РАСПРЕДЕЛЕНИЕ КАМНЕЙ
  Widget _buildStones(int count, bool isKalah) {
    if (GameSettings.visualMode == VisualMode.numbersOnly || count == 0) return const SizedBox();

    const stoneColors = [
      [Colors.teal, Colors.tealAccent],
      [Colors.indigo, Colors.lightBlue],
      [Colors.brown, Colors.orangeAccent],
      [Colors.redAccent, Colors.red],
      [Colors.blueGrey, Colors.white70],
    ];

    int visibleStones = min(count, 12);
    double radius = isKalah ? 35.0 : 28.0;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(visibleStones, (index) {
        double angle = (2 * pi / visibleStones) * index;
        var colors = stoneColors[index % stoneColors.length];

        return Transform.translate(
          offset: Offset(cos(angle) * radius, sin(angle) * radius),
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white, colors[1], colors[0]],
                center: const Alignment(-0.4, -0.4),
              ),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
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
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(isP1Turn ? txt['p1_turn']! : (widget.mode == GameMode.ai ? txt['ai_turn']! : txt['p2_turn']!),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
                Expanded(child: Center(child: FittedBox(child: _buildBoard()))),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.exit_to_app, color: Colors.white70), 
                    label: Text(txt['menu']!, style: const TextStyle(color: Colors.white70))
                  ),
                ),
              ],
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
    bool active = (isP1Turn && i < 6) || (!isP1Turn && widget.mode == GameMode.pvp && i > 6 && i < 13);
    return GestureDetector(
      onTap: () => active && !animating ? _move(i) : null,
      child: Container(
        width: 90, height: 90, margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: lastDrop == i ? Colors.white10 : Colors.black38, 
          shape: BoxShape.circle, 
          border: Border.all(color: active ? Colors.amber : Colors.black45, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
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
    if (board[start] == 0) return;
    setState(() => animating = true);
    int stones = board[start]; board[start] = 0;
    int curr = start;
    while (stones > 0) {
      curr = (curr + 1) % 14;
      if (start < 6 && curr == 13) curr = 0;
      if (start > 6 && curr == 6) curr = 7;
      HapticFeedback.lightImpact(); // Виброотклик S24+
      setState(() { board[curr]++; lastDrop = curr; stones--; });
      await Future.delayed(const Duration(milliseconds: 180));
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