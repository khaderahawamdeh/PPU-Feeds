import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ppu_feeds/models/course.dart';
import 'package:ppu_feeds/models/subscription.dart';
import 'package:ppu_feeds/pages/coursefeed_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeCourseCard extends StatefulWidget {
  const HomeCourseCard({super.key});

  @override
  State<HomeCourseCard> createState() => _HomeCourseCardState();
}

class _HomeCourseCardState extends State<HomeCourseCard> {
  late Future<Map<String, List>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<Map<String, List>> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final subscriptionsResponse = await http.get(
        Uri.parse("http://feeds.ppu.edu/api/v1/subscriptions"),
        headers: {"Authorization": "$token"},
      );

      final coursesResponse = await http.get(
        Uri.parse("http://feeds.ppu.edu/api/v1/courses"),
        headers: {"Authorization": "$token"},
      );

      if (subscriptionsResponse.statusCode == 200 &&
          coursesResponse.statusCode == 200) {
        List<dynamic> subsJson =
            jsonDecode(subscriptionsResponse.body)["subscriptions"];
        List<dynamic> coursesJson = jsonDecode(coursesResponse.body)["courses"];

        final subscriptions =
            subsJson.map((e) => Subscription.fromJson(e)).toList();
        final courses = coursesJson.map((e) => Course.fromJson(e)).toList();

        return {"subscriptions": subscriptions, "courses": courses};
      } else {
        throw Exception(
            "Failed to fetch data: ${subscriptionsResponse.statusCode}, ${coursesResponse.statusCode}");
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          futureData = fetchData();
        });
      },
      child: FutureBuilder<Map<String, List>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          } else {
            final subscriptions =
                snapshot.data!["subscriptions"] as List<Subscription>;
            final courses = snapshot.data!["courses"] as List<Course>;

            if (subscriptions.isEmpty || courses.isEmpty) {
              return const Center(
                child: Text(
                  "No subscriptions or courses found",
                  style: TextStyle(fontSize: 18.0),
                ),
              );
            }

            return ListView.builder(
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = subscriptions[index];

                final course = courses.firstWhere(
                  (course) => course.name == subscription.course,
                );

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseFeedsScreen(
                          courseId: course.id,
                          sectionId: subscription.sectionId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.course,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            course.collegeName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(
                            "Section: ${subscription.section}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Lecturer: ${subscription.lecturer}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
