import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppu_feeds/models/comment.dart';

class PostCommentsScreen extends StatefulWidget {
  final int courseId;
  final int sectionId;
  final int postId;

  const PostCommentsScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.postId,
  });

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  late Future<List<Comment>> futureComments;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editController = TextEditingController();


  Map<int, bool> likedComments = {};

  @override
  void initState() {
    super.initState();
    futureComments =
        fetchComments(widget.courseId, widget.sectionId, widget.postId);
  }

  Future<List<Comment>> fetchComments(
      int courseId, int sectionId, int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> commentsJson = jsonResponse["comments"];
        return commentsJson.map((e) => Comment.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load comments: ${response.statusCode}");
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> addComment(int courseId, int sectionId, int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.post(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments"),
        headers: {
          "Authorization": "$token",
          "Content-Type": "application/json",
        },
        body: json.encode({"body": _commentController.text}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonObject = jsonDecode(response.body);
        print("Comment added successfully: $jsonObject");

        _commentController.clear();

        setState(() {
          futureComments = fetchComments(courseId, sectionId, postId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comment added successfully!")),
        );
      } else {
        print("Failed to add comment. Status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to add comment: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error occurred while adding comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $e")),
      );
    }
  }

  Future<void> updateComment(
      int courseId, int sectionId, int postId, int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.put(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments/$commentId"),
        headers: {
          "Authorization": "$token",
          "Content-Type": "application/json",
        },
        body: json.encode({"body": _editController.text}),
      );

      if (response.statusCode == 200) {
        setState(() {
          futureComments = fetchComments(courseId, sectionId, postId);
        });
      } else {
        print("Failed to update comment. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred while updating comment: $e");
    }
  }

  Future<void> deleteComment(
      int courseId, int sectionId, int postId, int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.delete(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments/$commentId"),
        headers: {
          "Authorization": "$token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          futureComments = fetchComments(courseId, sectionId, postId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comment deleted successfully!")),
        );
      } else {
        print("Failed to delete comment. Status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to delete comment: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error occurred while deleting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $e")),
      );
    }
  }


  Future<void> toggleLike(
      int courseId, int sectionId, int postId, int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.post(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments/$commentId/like"),
        headers: {
          "Authorization": "$token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
         
          likedComments[commentId] = !(likedComments[commentId] ?? false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Like toggled successfully!")),
        );
      } else {
        print("Failed to toggle like. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred while toggling like: $e");
    }
  }

  Future<int> getLikesCount(
      int courseId, int sectionId, int postId, int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments/$commentId/likes"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse["likes_count"];
      } else {
        throw Exception("Failed to fetch likes count: ${response.statusCode}");
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<bool> checkIfLiked(
      int courseId, int sectionId, int postId, int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts/$postId/comments/$commentId/like"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse["liked"];
      } else {
        throw Exception("Failed to check if liked: ${response.statusCode}");
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  void _showEditDialog(Comment comment) {
    _editController.text = comment.body;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(
            labelText: 'Edit your comment',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              updateComment(
                widget.courseId,
                widget.sectionId,
                widget.postId,
                comment.id,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          futureComments =
              fetchComments(widget.courseId, widget.sectionId, widget.postId);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Write a comment",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  addComment(widget.courseId, widget.sectionId, widget.postId);
                }
              },
              icon: const Icon(Icons.send),
              color: const Color(0xFF0A7075),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comments',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A7075),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Comment>>(
                future: futureComments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No comments found"));
                  } else {
                    final comments = snapshot.data!;

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];

                        return Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 5.0),
                                Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.author,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 1.0),
                                        Text(
                                          comment.datePosted,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Divider(),
                                        Text(
                                          comment.body,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Row(
                                        children: [
                                          FutureBuilder<bool>(
                                            future: checkIfLiked(
                                                widget.courseId,
                                                widget.sectionId,
                                                widget.postId,
                                                comment.id),
                                            builder: (context, likeSnapshot) {
                                              if (likeSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              } else if (likeSnapshot
                                                  .hasError) {
                                                return IconButton(
                                                  icon: const Icon(
                                                    Icons.thumb_up,
                                                  ),
                                                  onPressed: () {
                                                    toggleLike(
                                                        widget.courseId,
                                                        widget.sectionId,
                                                        widget.postId,
                                                        comment.id);
                                                  },
                                                );
                                              } else {
                                                bool isLiked =
                                                    likeSnapshot.data ?? false;
                                                return IconButton(
                                                  icon: Icon(
                                                    isLiked
                                                        ? Icons.thumb_up
                                                        : Icons
                                                            .thumb_up_outlined,
                                                  ),
                                                  onPressed: () {
                                                    toggleLike(
                                                        widget.courseId,
                                                        widget.sectionId,
                                                        widget.postId,
                                                        comment.id);
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          Row(
                                            children: [
                                              FutureBuilder<int>(
                                                future: getLikesCount(
                                                    widget.courseId,
                                                    widget.sectionId,
                                                    widget.postId,
                                                    comment.id),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const CircularProgressIndicator();
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return const Text(
                                                      "Likes: 0",
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    );
                                                  } else {
                                                    return Text(
                                                      "${snapshot.data} Likes",
                                                      style: const TextStyle(
                                                          color: Colors.grey),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showEditDialog(comment),
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Comment'),
                                          content: const Text(
                                              'Are you sure you want to delete this comment?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                deleteComment(
                                                    widget.courseId,
                                                    widget.sectionId,
                                                    widget.postId,
                                                    comment.id);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }
}
