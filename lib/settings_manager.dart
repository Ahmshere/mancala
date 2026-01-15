import 'package:flutter/material.dart';

enum Language { ru, en, de }
enum VisualMode { numbersOnly, stonesAndNumbers }
enum Difficulty { easy, medium, hard }
enum GameMode { pvp, ai }

class GameSettings {
  static Language lang = Language.en;
  static Difficulty difficulty = Difficulty.medium;
  static VisualMode visualMode = VisualMode.stonesAndNumbers;
  static const String appVersion = "1.0";

  static const Map<Language, Map<String, String>> labels = {
    Language.ru: {
      'title': 'МАНКАЛА', 'pvp': '2 ИГРОКА', 'ai': 'ПРОТИВ БОТА',
      'diff': 'СЛОЖНОСТЬ', 'p1_turn': 'ИГРОК: 1', 'p2_turn': 'ИГРОК: 2',
      'ai_turn': 'БОТ ДУМАЕТ', 'over': 'КОНЕЦ', 'score': 'СЧЕТ',
      'menu': 'В МЕНЮ', 'settings': 'НАСТРОЙКИ',
      'vis_mode': 'ВИД КАМНЕЙ', 'vis_1': 'Цифры', 'vis_2': 'Цифры + Камни'
    },
    Language.en: {
      'title': 'MANCALA', 'pvp': '2 PLAYERS', 'ai': 'PLAYER VS AI',
      'diff': 'DIFFICULTY', 'p1_turn': 'PLAYER TURN', 'p2_turn': 'PLAYER TURN',
      'ai_turn': 'AI THINKING', 'over': 'GAME OVER', 'score': 'SCORE',
      'menu': 'MENU', 'settings': 'SETTINGS',
      'vis_mode': 'VISUALS', 'vis_1': 'Numbers', 'vis_2': 'Stones + Numbers'
    },
    Language.de: {
      'title': 'MANKALA', 'pvp': '2 SPIELER', 'ai': 'SPIELER VS KI',
      'diff': 'SCHWIERIGKEIT', 'p1_turn': 'P1 ZUG', 'p2_turn': 'P2 ZUG',
      'ai_turn': 'KI DENKT', 'over': 'ENDE', 'score': 'STAND',
      'menu': 'MENÜ', 'settings': 'SETUP',
      'vis_mode': 'OPTIK', 'vis_1': 'Zahlen', 'vis_2': 'Steine + Zahlen'
    }
  };
}