import 'package:flutter/material.dart';

class PageHome extends StatelessWidget {
  const PageHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 80),
          const SizedBox(height: 20),
          const Text('Search Page', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Text(
            'Swipe left or right',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
