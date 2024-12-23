import 'package:flutter/material.dart';
import 'package:ppu_feeds/pages/feeds_screen.dart';
import 'package:ppu_feeds/pages/home_screen.dart';
import 'package:ppu_feeds/pages/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
      routes: {
        "/Login": (context) => LoginScreen(),
        "/Home": (context) => const HomeScreen(),
        "/Feeds": (context) => const FeedsScreen(),
      },
    );
  }
}
