import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final DateTime date;
  final Duration workDuration;
  final Duration breakDuration;

  SessionData({
    required this.date,
    required this.workDuration,
    required this.breakDuration,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'workDuration': workDuration.inSeconds,
      'breakDuration': breakDuration.inSeconds,
    };
  }

  // Create from JSON
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      date: DateTime.parse(json['date']),
      workDuration: Duration(seconds: json['workDuration']),
      breakDuration: Duration(seconds: json['breakDuration']),
    );
  }

  // Static methods for data persistence
  static Future<void> saveSession(SessionData session) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessions = prefs.getStringList('sessions') ?? [];
    sessions.add(jsonEncode(session.toJson()));
    await prefs.setStringList('sessions', sessions);
  }

  static Future<List<SessionData>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessions = prefs.getStringList('sessions') ?? [];
    return sessions.map((s) => SessionData.fromJson(jsonDecode(s))).toList();
  }
}
