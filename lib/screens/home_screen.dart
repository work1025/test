import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scip_test_api/screens/reports_screen.dart';
import 'package:scip_test_api/widgets/session_card.dart';
import '../core/theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String formattedDate = "";
  String formattedTime = "";
  bool isSessionActive = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('en', null);
    setState(() {
      formattedDate = DateFormat('EEE d MMM', 'en').format(DateTime.now());
      formattedTime = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Time Tracker",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: AssetImage("assets/images/110.jpg"),
          ),
        ),
        actions: const [
          Icon(Icons.person, color: Colors.black),
          SizedBox(width: 15),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(formattedTime,
                  style: const TextStyle(fontSize: 40, color: Colors.white)),
              Text(formattedDate,
                  style: const TextStyle(fontSize: 24, color: Colors.white)),
              const SizedBox(height: 20),
              SessionCard(),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportsScreen()),
                  );
                },
                child: const Text("Go to an older date >",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
