// lib/views/widgets/user_card_widget.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';

class UserCardWidget extends StatelessWidget {
  final User? user;

  const UserCardWidget({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 50, color: Colors.blue[700]),
            ),
            const SizedBox(height: 16),
            Text(
              user?.username ?? 'Unknown User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (user?.email != null)
              Text(
                user!.email!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            if (user?.isPremium == true)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Premium User',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
