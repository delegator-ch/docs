// lib/pages/page-home.dart
import 'package:flutter/material.dart';
import '../components/monthly_calender.dart';
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
  void initState() {
    super.initState();
    // Example: Mark some dates
    _markedDates = [
      DateTime(_currentYear, _currentMonth, 10),
      DateTime(_currentYear, _currentMonth, 15),
      DateTime(_currentYear, _currentMonth, 20),
    ];
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _handleAddPressed() {
    // Handle add button press
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add button pressed')));
  }

  void _onDaySelected(DateTime date) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${date.day}/${date.month}/${date.year}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalendarComponent(
      calendarContent: _buildCalendarContent(),
      onAddPressed: _handleAddPressed,
      onLeftArrowPressed: _prevMonth,
      onRightArrowPressed: _nextMonth,
      showHeaderNotification: false,
      showCalendarNotification: false,
    );
  }

  Widget _buildCalendarContent() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            '${_getMonthName(_currentMonth)} $_currentYear',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: MonthlyCalendar(
              year: _currentYear,
              month: _currentMonth,
              onDaySelected: _onDaySelected,
              markedDates: _markedDates,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}
