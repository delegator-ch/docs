import 'package:delegator/pages/page-main.dart';
import 'package:delegator/service/user_service.dart';
import 'package:delegator/service/token_manager.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  // Try to fetch a token with default credentials
  print('Attempting to fetch token with default credentials...');
  bool tokenFetched = await TokenManager.fetchTokenWithDefaultCredentials();

  if (tokenFetched) {
    print('Token fetched successfully!');
  } else {
    print('Failed to fetch token with default credentials');
  }

  // Initialize user service to fetch current user
  await UserService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delegator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Add consistent styling
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: const PageMain(),
    );
  }
}
