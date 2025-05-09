import 'package:delegator/pages/page-main.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottom Nav with Swipe',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PageMain(),
    );
  }
}
