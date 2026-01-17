import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class GameRecord {
  final String date;
  final String mode; 
  final String score;
  final String duration;
  final String difficulty; // <--- НОВОЕ ПОЛЕ

  GameRecord({
    required this.date, 
    required this.mode, 
    required this.score, 
    required this.duration,
    required this.difficulty, // <--- В конструктор
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'mode': mode,
    'score': score,
    'duration': duration,
    'difficulty': difficulty, // <--- В JSON
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    date: json['date'],
    mode: json['mode'],
    score: json['score'],
    duration: json['duration'],
    difficulty: json['difficulty'] ?? "", // <--- Из JSON (с защитой от null)
  );
}

// 2. ВИДЖЕТ ЭКРАНА СТАТИСТИКИ
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<GameRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Загрузка данных из SharedPreferences
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('game_history');
    
    if (jsonList != null) {
      setState(() {
        _records = jsonList
            .map((item) => GameRecord.fromJson(json.decode(item)))
            .toList();
      });
    }
  }

  // Очистка статистики
  Future<void> _clearStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('game_history');
    setState(() {
      _records.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Темный фон в стиле игры
      appBar: AppBar(
        title: Text("GAME HISTORY", style: GoogleFonts.cinzel(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: _showClearDialog,
            )
        ],
      ),
      body: _records.isEmpty
          ? Center(
              child: Text("NO GAMES RECORDED", 
                style: GoogleFonts.cinzel(color: Colors.white24, fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      record.mode == "VS CPU" ? Icons.computer : Icons.people_alt,
                      color: Colors.amber.withOpacity(0.7),
                      size: 30,
                    ),
                    title: Text(record.score, 
                      style: GoogleFonts.cinzel(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                    subtitle: Text("${record.date} • ${record.duration} ${record.mode == "VS CPU" ? '(${record.difficulty})' : ''}",
                      style: const TextStyle(color: Colors.white70)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text(record.mode, style: const TextStyle(color: Colors.amber, fontSize: 10)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("CLEAR STATS?", style: GoogleFonts.cinzel(color: Colors.amber)),
        content: const Text("Do you want to delete all game history?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              _clearStats();
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}