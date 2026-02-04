import 'package:flutter/material.dart';

enum Language { ru, en, de }

enum VisualMode { numbersOnly, stonesAndNumbers, stonesOnly }

enum Difficulty { easy, medium, hard }

enum GameMode { pvp, ai }

class GameSettings {
  static Language lang = Language.en;
  static Difficulty difficulty = Difficulty.medium;
  static VisualMode visualMode = VisualMode.stonesAndNumbers;
  static const String appVersion = "1.0.0"; // Версия тут

  static bool isSoundOn = true;
  static bool isMusicOn = true;
  static double musicVolume = 0.5;
  static double sfxVolume = 0.5;

  // Не забудь добавить переводы для новых пунктов меню в Label

  static const Map<Language, Map<String, String>> labels = {
    Language.en: {
      'title': 'MANCALA',
      'pvp': 'Player vs Player',
      'ai': 'Player vs AI',
      'settings': 'Settings',
      'rules': 'How to Play',
      'close': 'Close',
      'menu': 'Main Menu',
      'p1_turn': 'Player 1 Turn',
      'p2_turn': 'Player 2 Turn',
      'ai_turn': 'AI Turn',
      'vis_1': 'Numbers Only',
      'vis_2': 'Stones & Numbers',
      'game_over': 'Game Over',
      'p1_wins': '🎉 Player 1 Wins!',
      'p2_wins': '🎉 Player 2 Wins!',
      'ai_wins': '🤖 AI Wins!',
      'draw': '🤝 Draw!',
      'p1': 'Player 1',
      'p2': 'Player 2',
      'play_again': 'Play Again',
      'support_title': 'Support the Creator',
      'support_text':
          'Im a writer, musician, and traveler. This game features my original code and hand-recorded soundscapes. From Meanwhile, in My Life... stories to The Grand Tour Alone project — your support fuels my independent creative journey.',
      'rules_text': '''
🎯 OBJECTIVE:

Collect more stones in your Kalah (large pit) than your opponent.

🎮 GAME SETUP:

• The board has 12 small pits (6 per player) and 2 Kalahs (large pits).
• At the start of the game, each small pit contains 4 stones.
• Your side: bottom row + right Kalah (large pit).
• Opponent’s side: top row + left Kalah (large pit).

▶️ HOW TO PLAY:

Choose and tap any pit with stones on YOUR side.

Stones are distributed counterclockwise, one stone per pit.

During a move, stones are placed into all pits except the opponent’s Kalah.

If the last stone lands in YOUR Kalah, you get another turn!

If the last stone lands in an empty pit on YOUR side, that stone and all stones from the opposite pit are moved to your Kalah.

🏁 END OF THE GAME:

When one player’s side is empty, the game ends.
The player with more stones wins!

💡 STRATEGY TIP:

Try to make your last stone land in your Kalah to earn an extra turn!
''',
      'music': 'Music',
      'sound': 'Sound Effects',
      'volume': 'Volume',
      'exit_confirm_title': 'Leave Game?',
      'exit_confirm_desc': 'Are you sure you want to exit?',
      'easy': 'EASY',
      'medium': 'MEDIUM',
      'hard': 'HARD',
    },
    Language.ru: {
      'title': 'МАНКАЛА',
      'pvp': 'Игрок против Игрока',
      'ai': 'Игрок против ИИ',
      'settings': 'Настройки',
      'rules': 'Как играть',
      'close': 'Закрыть',
      'menu': 'Главное меню',
      'p1_turn': 'Ход Игрока 1',
      'p2_turn': 'Ход Игрока 2',
      'ai_turn': 'Ход ИИ',
      'vis_1': 'Только числа',
      'vis_2': 'Камни и числа',
      'game_over': 'Игра окончена',
      'p1_wins': '🎉 Игрок 1 победил!',
      'p2_wins': '🎉 Игрок 2 победил!',
      'ai_wins': '🤖 ИИ победил!',
      'draw': '🤝 Ничья!',
      'p1': 'Игрок 1',
      'p2': 'Игрок 2',
      'play_again': 'Играть снова',
      'support_title': 'Поддержать автора',
      'support_text':
          'Я писатель, музыкант и путешественник. В этой игре я соединил код и авторские звуки, записанные вручную. От историй «Meanwhile, in My Life...» до проекта «The Grand Tour Alone» — ваша поддержка помогает мне создавать это искусство независимо.',
      'rules_text': '''
📋 ЦЕЛЬ:
Собрать камней в свою Калаху (большую лунку)  больше, чем противник.(Правая калаха принадлежит игроку 1. (Левая калаха принадлежит игроку 2 или ИИ)

🎮 НАСТРОЙКА ИГРЫ:
• Доска имеет 12 маленьких лунок (по 6 на игрока) и 2 Калахи (большие лунки).
• Вначале игры в каждой маленькой лунке 4 камня.
• Ваша сторона: нижний ряд + правая Калаха (большая лунка).
• Сторона противника: верхний ряд + левая Калаха (большая лунка).

🎯 КАК ИГРАТЬ:
1. Выберите и нажмите на любую лунку с камнями на ВАШЕЙ стороне.
2. Камни распределяются против часовой стрелки, по одному в лунку.
3. При свершении хода камни распределяются во все лунки кроме Калахи (большая лунка) противника.
4. Если последний камень попал в ВАШУ Калаху (большую лунку) → ходите снова!
5. Если последний камень попал в ВАШУ пустую лунку, то этот камень и все камни из противоположной лунки перемещаются в вашу Калаху (большую лунку).
6. Если последний камень попал в ВАШУ пустую лунку, но в противоположной лунке нет камней, то это обычный ход.

🏁 КОНЕЦ ИГРЫ:
Когда одна сторона игрока пуста игра завершается. Выигрывает тот, у кого больше камней!

💡 СОВЕТ ПО СТРАТЕГИИ:
Старайтесь, чтобы последний камень попал в вашу Калаху для дополнительного хода.
''',
      'music': 'Музыка',
      'sound': 'Звуки',
      'volume': 'Громкость',
      'exit_confirm_title': 'Выйти из игры?',
      'exit_confirm_desc': 'Вы уверены? Прогресс будет потерян.',
      'easy': 'ЛЕГКО',
      'medium': 'СРЕДНЕ',
      'hard': 'СЛОЖНО',
    },
    Language.de: {
      'title': 'MANCALA',
      'pvp': 'Spieler gegen Spieler',
      'ai': 'KI',
      'settings': 'Einstellungen',
      'rules': 'Spielanleitung',
      'close': 'Schließen',
      'menu': 'Hauptmenü',
      'p1_turn': 'Spieler 1 ist dran',
      'p2_turn': 'Spieler 2 ist dran',
      'ai_turn': 'KI ist dran',
      'vis_1': 'Nur Zahlen',
      'vis_2': 'Steine & Zahlen',
      'game_over': 'Spiel beendet',
      'p1_wins': '🎉 Spieler 1 gewinnt!',
      'p2_wins': '🎉 Spieler 2 gewinnt!',
      'ai_wins': '🤖 KI gewinnt!',
      'draw': '🤝 Unentschieden!',
      'p1': 'Spieler 1',
      'p2': 'Spieler 2',
      'play_again': 'Nochmal spielen',
      'support_title': 'Unterstütze den Entwickler',
      'support_text':
          'ch bin Autor, Musiker und Reisender. Dieses Spiel kombiniert meinen Code mit handaufgenommenen Soundscapes. Von Meanwhile, in My Life...-Geschichten bis zum The Grand Tour Alone -Projekt — deine Unterstützung fördert meine unabhängige Arbeit.',
      'rules_text': '''
🇩🇪 Deutsch
🎯 ZIEL:

Sammle mehr Steine in deiner Kalah (große Mulde) als dein Gegner.

🎮 SPIELAUFBAU:

• Das Spielbrett hat 12 kleine Mulden (6 pro Spieler) und 2 Kalahs (große Mulden).
• Zu Beginn liegen 4 Steine in jeder kleinen Mulde.
• Deine Seite: untere Reihe + rechte Kalah (große Mulde).
• Gegnerische Seite: obere Reihe + linke Kalah (große Mulde).

▶️ SPIELABLAUF:

Wähle eine Mulde mit Steinen auf DEINER Seite und tippe sie an.

Die Steine werden gegen den Uhrzeigersinn, jeweils ein Stein pro Mulde, verteilt.

Während eines Zuges werden Steine in alle Mulden gelegt, außer in die Kalah des Gegners.

Landet der letzte Stein in DEINER Kalah, darfst du noch einmal ziehen!

Landet der letzte Stein in einer leeren Mulde auf DEINER Seite, werden dieser Stein und alle Steine aus der gegenüberliegenden Mulde in deine Kalah gelegt.

🏁 SPIELENDE:

Sobald eine Spielerseite leer ist, endet das Spiel.
Der Spieler mit den meisten Steinen gewinnt!

💡 STRATEGIETIPP:

Versuche, den letzten Stein in deine Kalah zu legen, um einen zusätzlichen Zug zu erhalten!
''',
      'music': 'Musik',
      'sound': 'Töne',
      'volume': 'Lautstärke',
      'exit_confirm_title': 'Spiel verlassen?',
      'exit_confirm_desc': 'Bist du sicher? Fortschritt geht verloren.',
      'easy': 'LEICHT',
      'medium': 'MITTEL',
      'hard': 'SCHWER',
    },
  };
}
