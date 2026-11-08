import 'package:flutter/material.dart';

// Entry point of the app. Flutter starts running from main().
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App name shown in the task switcher
      title: 'BorrowCircle',

      // Hides the red "DEBUG" banner
      debugShowCheckedModeBanner: false,

      // App-wide theme. Every page uses these colors by default.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // primary from the design
          secondary: const Color(0xFF10B981), // secondary green
          tertiary: const Color(0xFFF59E0B), // tertiary amber
        ),
        // The design uses white page backgrounds
        scaffoldBackgroundColor: Colors.white,
      ),

      // First screen shown when the app opens.
      // Temporary test screen. Replace with SplashPage() once auth.dart is ready.
      home: const Scaffold(
        body: Center(child: Text('BorrowCircle')),
      ),
    );
  }
}