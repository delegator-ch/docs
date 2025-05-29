// lib/widgets/calendar_widget.dart

import 'package:flutter/material.dart';
import '../models/event.dart';

class CalendarWidget extends StatefulWidget {
  final List<Event>? events;
  final Function(DateTime)? onDateSelected;
  final Function(DateTime)? onMonthChanged;
  final DateTime? selectedDate;
  final bool showEventDots;
  final double height;

  const CalendarWidget({
    Key? key,
    this.events,
    this.onDateSelected,
    this.onMonthChanged,
    this.selectedDate,
    this.showEventDots = true,
    this.height = 300,
  }) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          _buildHeader(),
          _buildWeekDays(),
          Expanded(child: _buildCalendarGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            _getMonthYearText(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInCurrentMonth();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: daysInMonth.length,
        itemBuilder: (context, index) {
          final date = daysInMonth[index];
          return _buildDateCell(date);
        },
      ),
    );
  }

  Widget _buildDateCell(DateTime? date) {
    if (date == null) {
      return Container(); // Empty cell for padding
    }

    final isToday = _isSameDay(date, DateTime.now());
    final isSelected =
        _selectedDate != null && _isSameDay(date, _selectedDate!);
    final isCurrentMonth = date.month == _currentMonth.month;
    final eventsOnDate = _getEventsForDate(date);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateSelected?.call(date);
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : isToday
                  ? Colors.blue[50]
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: Colors.blue, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? Colors.black87
                        : Colors.grey[400],
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (widget.showEventDots && eventsOnDate.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...eventsOnDate.take(3).map((event) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: event.isGig ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                  if (eventsOnDate.length > 3)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<DateTime?> _getDaysInCurrentMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Get the first Monday of the calendar view
    int firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    DateTime startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    List<DateTime?> days = [];

    // Add 42 days (6 weeks) to ensure full calendar view
    for (int i = 0; i < 42; i++) {
      DateTime currentDate = startDate.add(Duration(days: i));
      days.add(currentDate);
    }

    return days;
  }

  List<Event> _getEventsForDate(DateTime date) {
    if (widget.events == null) return [];

    return widget.events!.where((event) {
      return _isSameDay(event.start, date);
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthYearText(DateTime date) {
    const months = [
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
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    widget.onMonthChanged?.call(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    widget.onMonthChanged?.call(_currentMonth);
  }
}
