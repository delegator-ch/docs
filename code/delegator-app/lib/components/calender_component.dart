// lib/components/calendar_component.dart
import 'package:flutter/material.dart';

class CalendarComponent extends StatelessWidget {
  final Widget calendarContent;
  final VoidCallback onAddPressed;
  final VoidCallback onLeftArrowPressed;
  final VoidCallback onRightArrowPressed;
  final bool showHeaderNotification;
  final bool showCalendarNotification;

  const CalendarComponent({
    super.key,
    required this.calendarContent,
    required this.onAddPressed,
    required this.onLeftArrowPressed,
    required this.onRightArrowPressed,
    this.showHeaderNotification = false,
    this.showCalendarNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            _buildCalendarSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Home',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              // Notification bubble
              if (showHeaderNotification)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              const SizedBox(width: 12),
              // Add button
              InkWell(
                onTap: onAddPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Text(
              'Kalender',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Left arrow
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: onLeftArrowPressed,
                    ),
                    // Calendar content
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          calendarContent,
                          // Notification circle in center (if needed)
                          if (showCalendarNotification)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Right arrow
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: onRightArrowPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
