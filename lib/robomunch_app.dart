import 'package:flutter/material.dart';
import 'home_screen.dart';

class RoboMunchApp extends StatelessWidget {
  const RoboMunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoboMunch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC97A3A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A0A00),
      ),
      home: const HomeScreen(),
    );
  }
}
