import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ppu_feeds/models/post.dart';
import 'package:ppu_feeds/pages/postcomments_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PostCard extends StatefulWidget {
  final int courseId;
  final int sectionId;

  const PostCard({
    super.key,
    required this.courseId,
    required this.sectionId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  late Future<List<Post>> futurePosts;

  @override
  void initState() {
    super.initState();
    futurePosts = fetchPosts(widget.courseId, widget.sectionId);
  }

  Future<List<Post>> fetchPosts(int courseId, int sectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final postsJson = jsonResponse["posts"] as List<dynamic>?;

        if (postsJson == null) {
          throw Exception("Invalid response format: 'posts' is null");
        }

        return postsJson.map((e) => Post.fromJson(e)).toList();
      } else {
        throw Exception(
            "Failed to fetch posts. Status code: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching posts: $e");
      return Future.error("Error fetching posts: $e");
    }
  }

  Future<void> sendPost(int courseId, int sectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.post(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/$courseId/sections/$sectionId/posts"),
        headers: {
          "Authorization": "$token",
          "Content-Type": "application/json",
        },
        body: json.encode({"body": _postController.text}),
      );

      if (response.statusCode == 200) {
        final jsonObject = jsonDecode(response.body);
        print("Post sent successfully: $jsonObject");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Posted successfully!")),
        );

        _postController.clear();

        setState(() {
          futurePosts = fetchPosts(courseId, sectionId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    }
  }

  Future<void> deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.delete(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/${widget.courseId}/sections/${widget.sectionId}/posts/$postId"),
        headers: {"Authorization": "$token"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted successfully!")),
        );
        setState(() {
          futurePosts = fetchPosts(widget.courseId, widget.sectionId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error deleting post: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> modifyPost(int postId, String newBody) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    try {
      final response = await http.put(
        Uri.parse(
            "http://feeds.ppu.edu/api/v1/courses/${widget.courseId}/sections/${widget.sectionId}/posts/$postId"),
        headers: {
          "Authorization": "$token",
          "Content-Type": "application/json",
        },
        body: json.encode({"body": newBody}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post updated successfully!")),
        );
        setState(() {
          futurePosts = fetchPosts(widget.courseId, widget.sectionId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error updating post: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showEditDialog(Post post) {
    _editController.text = post.body;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(
            labelText: 'Edit your post',
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
              modifyPost(post.id, _editController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: "Write a post",
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
              if (_postController.text.isNotEmpty) {
                sendPost(widget.courseId, widget.sectionId);
              }
            },
            icon: const Icon(Icons.send),
            color: const Color(0xFF0A7075),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          futurePosts = fetchPosts(widget.courseId, widget.sectionId);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 3.0),
            Expanded(
              child: FutureBuilder<List<Post>>(
                future: futurePosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No posts available"));
                  } else {
                    final posts = snapshot.data!;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostCommentsScreen(
                                  courseId: widget.courseId,
                                  sectionId: widget.sectionId,
                                  postId: post.id,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post.author,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              post.datePosted,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _showEditDialog(post),
                                            color: Colors.blue,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('Delete Post'),
                                                content: const Text(
                                                    'Are you sure you want to delete this post?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      deletePost(post.id);
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
                                  const Divider(),
                                  Text(
                                    post.body,
                                    style: const TextStyle(fontSize: 16),
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
            ),
            _buildPostInput(),
          ],
        ),
      ),
    );
  }
}
