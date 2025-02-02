import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/session_data.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime selectedDate = DateTime.now();
  List<SessionData> sessionData = [];

  @override
  void initState() {
    super.initState();
    loadSessionData();
  }

  Future<void> loadSessionData() async {
    final sessions = await SessionData.getAllSessions();
    setState(() {
      sessionData = sessions;
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes";
  }

  List<SessionData> getMonthSessions() {
    Map<DateTime, SessionData> dailySessions = {};

    // Group sessions by date (combining multiple sessions in the same day)
    for (var session in sessionData) {
      DateTime dateKey = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );

      if (dateKey.year == selectedDate.year &&
          dateKey.month == selectedDate.month) {
        if (dailySessions.containsKey(dateKey)) {
          var existingSession = dailySessions[dateKey]!;
          dailySessions[dateKey] = SessionData(
            date: dateKey,
            workDuration: existingSession.workDuration + session.workDuration,
            breakDuration:
                existingSession.breakDuration + session.breakDuration,
          );
        } else {
          dailySessions[dateKey] = session;
        }
      }
    }

    // Convert to list and sort
    return dailySessions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Duration getTotalDuration(List<SessionData> sessions, bool isWork) {
    return sessions.fold(
      Duration.zero,
      (total, session) =>
          total + (isWork ? session.workDuration : session.breakDuration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthSessions = getMonthSessions();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text("Work Report", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: _buildReport(monthSessions),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15),
      color: AppTheme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                selectedDate = DateTime(
                  selectedDate.year,
                  selectedDate.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              setState(() {
                selectedDate = DateTime(
                  selectedDate.year,
                  selectedDate.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReport(List<SessionData> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    final totalWork = getTotalDuration(sessions, true);
    final totalBreak = getTotalDuration(sessions, false);

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(totalWork, totalBreak, sessions.length),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _buildSessionCard(sessions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      Duration totalWork, Duration totalBreak, int daysCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total Work\n Hours",
                formatDuration(totalWork),
                Icons.work,
                Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Total Break\n Time",
                formatDuration(totalBreak),
                Icons.coffee,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Working Days",
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                "$daysCount days",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SessionData session) {
    return GestureDetector(
      onTap: () => _showSessionDetails(session),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(session.date),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    formatDuration(session.workDuration),
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStat(
                    Icons.work, "Work5", formatDuration(session.workDuration)),
                SizedBox(width: 16),
                _buildMiniStat(Icons.coffee, "Break",
                    formatDuration(session.breakDuration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        SizedBox(width: 4),
        Text(
          "$value",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            "No sessions recorded\nfor this month",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(SessionData session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSessionDetails(session),
    );
  }

  Widget _buildSessionDetails(SessionData session) {
    final efficiency = (session.workDuration.inMinutes /
            (session.workDuration.inMinutes + session.breakDuration.inMinutes) *
            100)
        .toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(session.date),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildDetailRow("Work Time", formatDuration(session.workDuration)),
          SizedBox(height: 12),
          _buildDetailRow("Break Time", formatDuration(session.breakDuration)),
          SizedBox(height: 12),
          _buildDetailRow("Efficiency", "$efficiency%"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
