import 'package:flutter/material.dart';
import 'package:ppu_feeds/app_drawer.dart';
import 'package:ppu_feeds/custom_widgets/course_card.dart';
import 'package:ppu_feeds/models/course.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  late Future<List<Course>> futureCourses;

  @override
  void initState() {
    super.initState();
    futureCourses = fetchedCourses();
  }

  Future<List<Course>> fetchedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      var response = await http.get(
        Uri.parse("http://feeds.ppu.edu/api/v1/courses"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> coursesJson = jsonResponse["courses"];
        return coursesJson.map((e) => Course.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A7075),
        title: const Text(
          "Courses",
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureCourses = fetchedCourses();
          });
        },
        child: FutureBuilder<List<Course>>(
          future: futureCourses,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data!.isEmpty) {
              return const Center(child: Text("No courses available"));
            } else {
              final courses = snapshot.data!;
              return ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final Course course = courses[index];
                  return CourseCard(id: course.id);
                },
              );
            }
          },
        ),
      ),
    );
  }
}
