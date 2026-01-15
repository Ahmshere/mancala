import 'package:flutter/material.dart';

enum Language { ru, en, de }
enum VisualMode { numbersOnly, stonesAndNumbers }
enum Difficulty { easy, medium, hard }
enum GameMode { pvp, ai }

class GameSettings {
  static Language lang = Language.en;
  static Difficulty difficulty = Difficulty.medium;
  static VisualMode visualMode = VisualMode.stonesAndNumbers;
  static const String appVersion = "1.2.0";

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
      'rules_text': '''
📋 OBJECTIVE:
Collect more stones in your Kalah (large pit) than your opponent.

🎮 GAME SETUP:
• Board has 12 small pits (6 per player) and 2 Kalahs
• Each small pit starts with 4 stones
• Your side: bottom row + right Kalah
• Opponent's side: top row + left Kalah

🎯 HOW TO PLAY:
1. Pick any pit on YOUR side with stones
2. Distribute stones counter-clockwise, one per pit
3. Include YOUR Kalah, skip opponent's Kalah
4. If last stone lands in YOUR Kalah → go again!
5. If last stone lands in YOUR empty pit → capture that stone + all stones from opposite pit into your Kalah

🏁 GAME ENDS:
When one player's side is empty. Opponent collects remaining stones. Highest score wins!

💡 STRATEGY TIP:
Try to land your last stone in your Kalah for another turn!
''',
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
      'rules_text': '''
📋 ЦЕЛЬ:
Собрать камней в свою Калаху (большую лунку)  больше, чем противник.

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

🏁 КОНЕЦ ИГРЫ:
Когда одна сторона игрока пуста гра завершается. Выигрывает тот, у кого больше!

💡 СОВЕТ ПО СТРАТЕГИИ:
Старайтесь, чтобы последний камень попал в вашу Калаху для дополнительного хода!
''',
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
      'rules_text': '''
📋 ZIEL:
Sammle mehr Steine in deiner Kalah (großes Spielfeld) als dein Gegner.

🎮 SPIELAUFBAU:
• Das Spielbrett hat 12 kleine Mulden (6 pro Spieler) und 2 Kalahs
• Jede kleine Mulde startet mit 4 Steinen
• Deine Seite: untere Reihe + rechte Kalah
• Gegnerseite: obere Reihe + linke Kalah

🎯 SPIELABLAUF:
1. Wähle eine Mulde auf DEINER Seite mit Steinen
2. Verteile die Steine gegen den Uhrzeigersinn, einen pro Mulde
3. Schließe DEINE Kalah ein, überspringe die gegnerische Kalah
4. Wenn der letzte Stein in DEINER Kalah landet → nochmal ziehen!
5. Wenn der letzte Stein in DEINER leeren Mulde landet → erobere diesen Stein + alle Steine aus der gegenüberliegenden Mulde in deine Kalah

🏁 SPIELENDE:
Wenn eine Spielerseite leer ist. Der Gegner sammelt die restlichen Steine. Höchste Punktzahl gewinnt!

💡 STRATEGIE-TIPP:
Versuche, deinen letzten Stein in deiner Kalah zu platzieren für einen weiteren Zug!
''',
    },
  };
}