import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ppu_feeds/models/course.dart';
import 'package:ppu_feeds/models/section.dart';
import 'package:ppu_feeds/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseCard extends StatefulWidget {
  final int id;

  const CourseCard({
    super.key,
    required this.id,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  late Future<Course> futureCourse;
  late Future<List<Section>> futureSections;
  late Future<List<Subscription>> futureSubs;

  @override
  void initState() {
    super.initState();
    futureCourse = fetchCourse(widget.id);
    futureSections = fetchSections(widget.id);
    futureSubs = fetchSubs();
  }

  Future<List<Section>> fetchSections(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse("http://feeds.ppu.edu/api/v1/courses/$id/sections"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> sectionsJson = jsonResponse["sections"];
        return sectionsJson.map((e) => Section.fromJson(e)).toList();
      } else {
        throw Exception(response.statusCode);
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<Course> fetchCourse(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse("http://feeds.ppu.edu/api/v1/courses/$id"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        final courseJson = jsonResponse["course"];
        return Course.fromJson(courseJson);
      } else {
        throw Exception(response.statusCode);
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<List<Subscription>> fetchSubs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse("http://feeds.ppu.edu/api/v1/subscriptions"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> subscriptionsJson = jsonResponse["subscriptions"];
        return subscriptionsJson.map((e) => Subscription.fromJson(e)).toList();
      } else {
        throw Exception(response.statusCode);
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> _subscribeCourseSection(int courseId, int sectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      http.Response response = await http.post(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/subscribe"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          futureSubs = fetchSubs();
        });
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> _unsubscribeCourseSection(
      int courseId, int sectionId, int subscriptionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      http.Response response = await http.delete(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/subscribe/$subscriptionId"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          futureSubs = fetchSubs();
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(jsonResponse["status"])));
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
          futureCourse = fetchCourse(widget.id);
          futureSections = fetchSections(widget.id);
          futureSubs = fetchSubs();
        });
      },
      child: FutureBuilder<Course>(
        future: futureCourse,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No courses found"));
          } else {
            final course = snapshot.data!;
            return Column(
              children: [
                const SizedBox(
                  height: 3.0,
                ),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.name,
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
                                  FutureBuilder<List<Section>>(
                                    future: futureSections,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                            child: Text("${snapshot.error}"));
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return const Text("No sections found");
                                      } else {
                                        final List<Section> sections =
                                            snapshot.data!;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: sections.map(
                                            (section) {
                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3.0),
                                                title: Text(
                                                  "Section: ${section.name}",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  "Lecturer: ${section.lecturer}",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                trailing: FutureBuilder<
                                                    List<Subscription>>(
                                                  future: futureSubs,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasError) {
                                                      return Text(
                                                          "${snapshot.error}");
                                                    }
                                                    final subscription =
                                                        snapshot.data
                                                            ?.firstWhere(
                                                      (sub) =>
                                                          sub.sectionId ==
                                                          section.id,
                                                      orElse: () =>
                                                          Subscription(
                                                        id: -1,
                                                        sectionId: section.id,
                                                        section: section.name,
                                                        course: course.name,
                                                        lecturer:
                                                            section.lecturer,
                                                        subscriptionDate: DateTime
                                                                .now()
                                                            .toIso8601String(),
                                                      ),
                                                    );

                                                    final isSubscribed =
                                                        subscription?.id != -1;

                                                    return TextButton.icon(
                                                      onPressed: () {
                                                        if (isSubscribed) {
                                                          _unsubscribeCourseSection(
                                                            course.id,
                                                            section.id,
                                                            subscription!.id,
                                                          );
                                                        } else {
                                                          _subscribeCourseSection(
                                                            course.id,
                                                            section.id,
                                                          );
                                                        }
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.black,
                                                      ),
                                                      icon: Icon(
                                                        isSubscribed
                                                            ? Icons.check
                                                            : Icons.add,
                                                        color: Colors.black,
                                                      ),
                                                      label: Text(isSubscribed
                                                          ? "Subscribed"
                                                          : "Subscribe"),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ).toList(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 3.0,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
