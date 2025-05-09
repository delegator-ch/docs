import 'package:flutter/material.dart';

class PageInfo extends StatelessWidget {
  const PageInfo({super.key});

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
