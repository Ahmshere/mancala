import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
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

/* ===================== ЛОКАЛИЗАЦИЯ ===================== */

enum Language { ru, en, de }

const Map<Language, Map<String, String>> labels = {
  Language.ru: {
    'title': 'МАНКАЛА',
    'pvp': '2 ИГРОКА',
    'ai': 'ПРОТИВ БОТА',
    'diff': 'СЛОЖНОСТЬ',
    'p1_turn': 'ХОД: ИГРОК 1',
    'p2_turn': 'ХОД: ИГРОК 2',
    'ai_turn': 'ХОД: РОБОТ',
    'over': 'ИГРА ОКОНЧЕНА',
    'score': 'СЧЕТ',
    'menu': 'В МЕНЮ',
    'no_moves': 'НЕТ ДОСТУПНЫХ ХОДОВ!',
  },
  Language.en: {
    'title': 'MANCALA',
    'pvp': '2 PLAYERS',
    'ai': 'VS COMPUTER',
    'diff': 'DIFFICULTY',
    'p1_turn': 'TURN: PLAYER 1',
    'p2_turn': 'TURN: PLAYER 2',
    'ai_turn': 'TURN: AI THINKING',
    'over': 'GAME OVER',
    'score': 'SCORE',
    'menu': 'MENU',
    'no_moves': 'NO MOVES POSSIBLE!',
  },
  Language.de: {
    'title': 'MANKALA',
    'pvp': '2 SPIELER',
    'ai': 'GEGEN COMPUTER',
    'diff': 'SCHWIERIGKEIT',
    'p1_turn': 'AM ZUG: SPIELER 1',
    'p2_turn': 'AM ZUG: SPIELER 2',
    'ai_turn': 'KI DENKT NACH...',
    'over': 'SPIEL VORBEI',
    'score': 'ERGEBNIS',
    'menu': 'HAUPTMENÜ',
    'no_moves': 'KEINE ZÜGE MÖGLICH!',
  }
};

/* ===================== МЕНЮ (АДАПТИВНОЕ) ===================== */

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Difficulty _difficulty = Difficulty.medium;
  Language _lang = Language.en;

  @override
  Widget build(BuildContext context) {
    var txt = labels[_lang]!;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(colors: [Color(0xFF5D4037), Color(0xFF1B100E)], radius: 1.5),
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              bool isLandscape = orientation == Orientation.landscape;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Flex(
                  direction: isLandscape ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Секция заголовка и языка
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: Language.values.map((l) => TextButton(
                            onPressed: () => setState(() => _lang = l),
                            child: Text(l.name.toUpperCase(), 
                              style: TextStyle(
                                color: _lang == l ? Colors.amber : Colors.white54, 
                                fontWeight: FontWeight.bold,
                                fontSize: isLandscape ? 14 : 16
                              )),
                          )).toList(),
                        ),
                        Text(txt['title']!, 
                          style: TextStyle(
                            fontSize: isLandscape ? 40 : 50, 
                            fontWeight: FontWeight.bold, 
                            color: const Color(0xFFFFD54F), 
                            letterSpacing: 4,
                            shadows: const [Shadow(color: Colors.black, blurRadius: 10)]
                          )
                        ),
                      ],
                    ),
                    
                    // Секция кнопок и сложности
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _menuBtn(txt['pvp']!, GameMode.pvp, isLandscape),
                        const SizedBox(height: 12),
                        _menuBtn(txt['ai']!, GameMode.ai, isLandscape),
                        const SizedBox(height: 15),
                        Text(txt['diff']! + ":", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 5,
                          children: Difficulty.values.map((d) => ChoiceChip(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            label: Text(d.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                            selected: _difficulty == d,
                            onSelected: (s) => setState(() => _difficulty = d),
                          )).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _menuBtn(String text, GameMode mode, bool isLandscape) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8D6E63),
        minimumSize: Size(isLandscape ? 200 : 260, isLandscape ? 45 : 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MancalaGame(mode: mode, difficulty: _difficulty, lang: _lang))),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

/* ===================== ИГРА ===================== */
// Оставляем логику игры без изменений (как в предыдущем ответе), 
// так как она уже работает корректно и использует FittedBox.

enum GameMode { pvp, ai }
enum Difficulty { easy, medium, hard }

class MancalaGame extends StatefulWidget {
  final GameMode mode;
  final Difficulty difficulty;
  final Language lang;
  const MancalaGame({super.key, required this.mode, required this.difficulty, required this.lang});

  @override
  State<MancalaGame> createState() => _MancalaGameState();
}

class _MancalaGameState extends State<MancalaGame> {
  List<int> board = List.filled(14, 4);
  bool isP1Turn = true;
  bool animating = false;
  bool noMovesMessage = false;
  int? lastDrop;

  @override
  void initState() {
    super.initState();
    board[6] = 0; board[13] = 0;
  }

  int get depth {
    if (widget.difficulty == Difficulty.hard) return 6;
    if (widget.difficulty == Difficulty.medium) return 4;
    return 2;
  }

  Future<void> handleTap(int index) async {
    if (animating) return;
    if (isP1Turn && (index > 5 || board[index] == 0)) return;
    if (!isP1Turn && (widget.mode == GameMode.ai || index < 7 || index > 12 || board[index] == 0)) return;
    await executeMove(index);
  }

  Future<void> executeMove(int start) async {
    setState(() { animating = true; noMovesMessage = false; });
    int stones = board[start];
    board[start] = 0;
    int curr = start;
    bool isP1 = start < 6;

    while (stones > 0) {
      curr = (curr + 1) % 14;
      if (isP1 && curr == 13) curr = 0;
      if (!isP1 && curr == 6) curr = 7;
      HapticFeedback.selectionClick();
      setState(() { board[curr]++; lastDrop = curr; stones--; });
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (curr != 6 && curr != 13 && board[curr] == 1) {
      bool onOwnSide = isP1 ? curr < 6 : (curr > 6 && curr < 13);
      int opposite = 12 - curr;
      if (onOwnSide && board[opposite] > 0) {
        setState(() {
          board[isP1 ? 6 : 13] += board[opposite] + 1;
          board[curr] = 0; board[opposite] = 0;
        });
        HapticFeedback.mediumImpact();
      }
    }

    bool extraTurn = (isP1 && curr == 6) || (!isP1 && curr == 13);
    if (extraTurn && _isSideEmpty(isP1)) {
      extraTurn = false;
      setState(() => noMovesMessage = true);
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!extraTurn) isP1Turn = !isP1Turn;

    setState(() { animating = false; lastDrop = null; });
    if (_isSideEmpty(true) || _isSideEmpty(false)) {
      _finalizeGame();
    } else if (!isP1Turn && widget.mode == GameMode.ai) {
      _aiAction();
    }
  }

  bool _isSideEmpty(bool p1) {
    int start = p1 ? 0 : 7;
    return board.sublist(start, start + 6).every((s) => s == 0);
  }

  void _finalizeGame() {
    setState(() {
      for (int i = 0; i < 6; i++) { board[6] += board[i]; board[i] = 0; }
      for (int i = 7; i < 13; i++) { board[13] += board[i]; board[i] = 0; }
    });
    _showResult();
  }

  void _aiAction() async {
    if (animating) return;
    await Future.delayed(const Duration(milliseconds: 600));
    int move = _minimaxBest(List.from(board), depth);
    if (move != -1) executeMove(move);
  }

  int _minimaxBest(List<int> b, int d) {
    int best = -1000, move = -1;
    for (int i = 7; i <= 12; i++) {
      if (b[i] > 0) {
        int v = _quickEval(List.from(b), i);
        if (v > best) { best = v; move = i; }
      }
    }
    return move;
  }

  int _quickEval(List<int> b, int move) {
    int s = b[move]; b[move] = 0;
    int c = move;
    while(s > 0) {
      c = (c + 1) % 14; if (c == 6) c = 7;
      b[c]++; s--;
    }
    return b[13] - b[6];
  }

  void _showResult() {
    var txt = labels[widget.lang]!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        title: Text(txt['over']!),
        content: Text("${txt['score']!}: ${board[6]} - ${board[13]}"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: Text(txt['menu']!))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var txt = labels[widget.lang]!;
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B18),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              noMovesMessage ? txt['no_moves']! : (isP1Turn ? txt['p1_turn']! : (widget.mode == GameMode.ai ? txt['ai_turn']! : txt['p2_turn']!)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20, 
                color: noMovesMessage ? Colors.redAccent : (isP1Turn ? Colors.greenAccent : Colors.orangeAccent), 
                fontWeight: FontWeight.bold
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    child: _buildWoodBoard(),
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context), 
              icon: const Icon(Icons.arrow_back, size: 18), 
              label: Text(txt['menu']!)
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildWoodBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF3E2723), width: 8),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
    bool canClick = (isP1Turn && i < 6) || (!isP1Turn && widget.mode == GameMode.pvp && i > 6 && i < 13);
    return GestureDetector(
      onTap: () => handleTap(i),
      child: Container(
        width: 75, height: 75,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: lastDrop == i ? Colors.white24 : Colors.black26,
          shape: BoxShape.circle,
          border: Border.all(color: canClick && !animating ? Colors.white70 : Colors.black45, width: 2),
        ),
        child: Center(
          child: Text("${board[i]}", 
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: board[i] > 0 ? Colors.white : Colors.white24)),
        ),
      ),
    );
  }

  Widget _buildKalah(int i, Color color) {
    return Container(
      width: 90, height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(45),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars, color: color.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text("${board[i]}", style: TextStyle(fontSize: 44, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}