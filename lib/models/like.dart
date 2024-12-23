class Like {
  final int likesCount;

  Like({
    required this.likesCount,
  });

  factory Like.fromJson(dynamic jsonObject) {
    return Like(
      likesCount: jsonObject["likes_count"],
    );
  }
}
