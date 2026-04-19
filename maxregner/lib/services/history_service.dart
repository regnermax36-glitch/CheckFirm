import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String id;
  final String prompt;
  final String path;
  final DateTime timestamp;
  final int duration;
  final int bpm;
  final String key;

  HistoryItem({
    required this.id,
    required this.prompt,
    required this.path,
    required this.timestamp,
    required this.duration,
    required this.bpm,
    required this.key,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    'path': path,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration,
    'bpm': bpm,
    'key': key,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'],
    prompt: json['prompt'],
    path: json['path'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: json['duration'],
    bpm: json['bpm'],
    key: json['key'],
  );
}

class HistoryService {
  static const String _key = 'music_history';

  Future<void> saveItem(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyJson = prefs.getStringList(_key) ?? [];
    historyJson.insert(0, jsonEncode(item.toJson()));
    await prefs.setStringList(_key, historyJson);
  }

  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyJson = prefs.getStringList(_key) ?? [];
    return historyJson.map((item) => HistoryItem.fromJson(jsonDecode(item))).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
