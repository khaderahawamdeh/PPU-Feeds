class Section {
  final int id;
  final String name;
  final String course;
  final String lecturer;

  Section({
    required this.id,
    required this.name,
    required this.course,
    required this.lecturer,
  });

  factory Section.fromJson(dynamic jsonObject) {
    return Section(
      id: jsonObject["id"],
      name: jsonObject["name"],
      course: jsonObject["course"],
      lecturer: jsonObject["lecturer"],
    );
  }
}