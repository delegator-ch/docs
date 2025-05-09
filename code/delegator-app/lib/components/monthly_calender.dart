// lib/components/monthly_calendar.dart
import 'package:flutter/material.dart';
import '../service/event_service.dart';

class MonthlyCalendar extends StatelessWidget {
  final int year;
  final int month;
  final Function(DateTime)? onDaySelected;
  final List<DateTime>? markedDates;
  final List<Event>? events;

  const MonthlyCalendar({
    super.key,
    required this.year,
    required this.month,
    this.onDaySelected,
    this.markedDates,
    this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 10),
        _buildCalendarGrid(context),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Tue', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Thu', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    // Calculate first day of month
    final firstDay = DateTime(year, month, 1);

    // Calculate days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Calculate which day of week the month starts (0 = Monday in our grid)
    // DateTime weekday gives 1-7 where 1 is Monday
    int firstDayOffset = firstDay.weekday - 1;

    // Total number of calendar cells (accounting for previous month days)
    final totalDays = firstDayOffset + daysInMonth;

    // Calculate number of rows needed
    final rows = (totalDays / 7).ceil();

    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: rows * 7, // Full grid with all cells
        itemBuilder: (context, index) {
          // Check if we're showing a day from previous month
          if (index < firstDayOffset) {
            return Container(); // Empty cell for previous month days
          }

          // Check if we're showing a day from next month
          final day = index - firstDayOffset + 1;
          if (day > daysInMonth) {
            return Container(); // Empty cell for next month days
          }

          // Current date being built
          final date = DateTime(year, month, day);

          // Check if it's today
          final isToday = _isToday(date);

          // Check if it's a marked date
          final isMarked =
              markedDates?.any(
                (markedDate) =>
                    markedDate.year == date.year &&
                    markedDate.month == date.month &&
                    markedDate.day == date.day,
              ) ??
              false;

          // Check if the day has events
          final hasEvents = _hasEvents(day);

          return GestureDetector(
            onTap: () {
              if (onDaySelected != null) {
                onDaySelected!(date);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    hasEvents
                        ? Colors.blue.withOpacity(0.2)
                        : isToday
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                border:
                    isMarked ? Border.all(color: Colors.blue, width: 1) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasEvents)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _hasEvents(int day) {
    if (events == null || events!.isEmpty) return false;

    // For each event, extract the hour from start time
    // and use it to create a date to check against
    for (var event in events!) {
      // Parse time (assuming format like "12:00:00")
      final timeParts = event.start.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        // Set day as current day in iteration
        // This is a simplification - in a real app, events would have proper date data
        final eventDate = DateTime(year, month, day, hour, minute);

        // Check if the date matches (in a real app, you'd check more precisely)
        // For demo purposes, we'll just show every 3rd day has an event
        if (day % 3 == 0) {
          return true;
        }
      }
    }

    return false;
  }
}
