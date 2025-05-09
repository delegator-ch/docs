import 'package:flutter/material.dart';

class PageChat extends StatelessWidget {
  const PageChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home, size: 80),
          const SizedBox(height: 20),
          const Text('Home Page', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Text(
            'Swipe left to see other pages',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
