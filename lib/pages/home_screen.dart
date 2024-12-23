// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, prefer_const_constructors, avoid_print, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:ppu_feeds/app_drawer.dart';
import 'package:ppu_feeds/custom_widgets/homecourse_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A7075),
        title: const Text(
          "Home",
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      drawer: AppDrawer(),
      body: HomeCourseCard(),
    );
  }
}
