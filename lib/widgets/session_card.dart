import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../models/session_data.dart';
import 'dart:async';

class SessionCard extends StatefulWidget {
  final Function(SessionData)? onSessionComplete;
  const SessionCard({Key? key, this.onSessionComplete}) : super(key: key);

  @override
  _SessionCardState createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  Timer? timer;
  Timer? breakTimer;
  DateTime? sessionStartTime;
  DateTime? breakStartTime;
  Duration currentSessionDuration = Duration.zero;
  Duration currentBreakDuration = Duration.zero;
  Duration totalWorkDuration = Duration.zero;
  Duration totalBreakDuration = Duration.zero;
  bool isSessionActive = false;
  bool isDayEnded = false;

  @override
  void initState() {
    super.initState();
    _loadDayStatus();
    _loadTotalDurations();
  }

  Future<void> _loadDayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEndDay = prefs.getString('lastEndDay');
    if (lastEndDay != null) {
      final lastEndDate = DateTime.parse(lastEndDay);
      if (lastEndDate.day == DateTime.now().day) {
        setState(() {
          isDayEnded = true;
        });
      } else {
        await prefs.remove('lastEndDay');
        setState(() {
          isDayEnded = false;
          totalWorkDuration = Duration.zero;
          totalBreakDuration = Duration.zero;
        });
      }
    }
  }

  Future<void> _loadTotalDurations() async {
    final sessions = await SessionData.getAllSessions();
    final today = DateTime.now();
    final todaySessions = sessions.where((session) =>
        session.date.year == today.year &&
        session.date.month == today.month &&
        session.date.day == today.day);

    setState(() {
      totalWorkDuration = todaySessions.fold(
        Duration.zero,
        (total, session) => total + session.workDuration,
      );
      totalBreakDuration = todaySessions.fold(
        Duration.zero,
        (total, session) => total + session.breakDuration,
      );
    });
  }

  void startSession() {
    if (isDayEnded) return;
    setState(() {
      isSessionActive = true;
      sessionStartTime = DateTime.now();
      breakTimer?.cancel();
      if (breakStartTime != null) {
        totalBreakDuration += DateTime.now().difference(breakStartTime!);
      }
      breakStartTime = null;
    });

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentSessionDuration = DateTime.now().difference(sessionStartTime!);
      });
    });
  }

  void stopSession() async {
    timer?.cancel();
    if (sessionStartTime != null) {
      final sessionData = SessionData(
        date: sessionStartTime!,
        workDuration: currentSessionDuration,
        breakDuration: currentBreakDuration,
      );
      await SessionData.saveSession(sessionData);
      widget.onSessionComplete?.call(sessionData);

      setState(() {
        totalWorkDuration += currentSessionDuration;
        currentSessionDuration = Duration.zero;
        breakStartTime = DateTime.now();
        currentBreakDuration = Duration.zero;
      });

      breakTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (breakStartTime != null) {
            currentBreakDuration = DateTime.now().difference(breakStartTime!);
          }
        });
      });
    }

    setState(() {
      isSessionActive = false;
      sessionStartTime = null;
    });
  }

  Future<void> _showEndDayConfirmation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(
            'End Work Day?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to end the work day?\n\n'
            'Warning: You won\'t be able to start new sessions until tomorrow.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('End Day'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                    'lastEndDay', DateTime.now().toIso8601String());
                if (isSessionActive) stopSession();
                setState(() {
                  isDayEnded = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Indicator
          Container(
            margin: EdgeInsets.only(bottom: 15),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSessionActive
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSessionActive ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSessionActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  isSessionActive ? "Connected" : "Disconnected",
                  style: TextStyle(
                    color: isSessionActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Time Displays
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn("Start", formatDuration(currentSessionDuration),
                  Colors.white),
              _buildTimeColumn(
                  "Break", formatDuration(currentBreakDuration), Colors.orange),
            ],
          ),
          SizedBox(height: 25),
          // Daily Statistics
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailStat(
                      Icons.work,
                      "Work Time",
                      formatDuration(
                          totalWorkDuration + currentSessionDuration),
                      Colors.green,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    _buildDetailStat(
                      Icons.coffee,
                      "Break Time",
                      formatDuration(totalBreakDuration + currentBreakDuration),
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Control Buttons
          ElevatedButton(
            onPressed: isDayEnded
                ? null
                : (isSessionActive ? stopSession : startSession),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSessionActive ? Colors.red : Colors.green,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSessionActive ? "Stop Session" : "Start Session",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isDayEnded) ...[
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showEndDayConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "End Work Day",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Work day ended",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStat(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    breakTimer?.cancel();
    super.dispose();
  }
}
