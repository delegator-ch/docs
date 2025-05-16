// lib/pages/page-home.dart
import 'package:flutter/material.dart';
import '../components/calender_component.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  List<DateTime> _markedDates = [];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80),
          const SizedBox(height: 20),
          const Text('Profile Page', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Text(
            'Swipe right to see other pages',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
