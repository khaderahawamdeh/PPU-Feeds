class Post {
  final int id;
  final String body;
  final String datePosted;
  final String author;

  Post({
    required this.id,
    required this.body,
    required this.datePosted,
    required this.author,
  });

  factory Post.fromJson(dynamic jsonObject) {
    return Post(
      id: jsonObject["id"] ?? 'Unknown ID',
      body: jsonObject["body"] ?? 'Unknown Author',
      datePosted: jsonObject["date_posted"] ?? 'No content',
      author: jsonObject["author"] ?? 'Unknown Date',
    );
  }
}
