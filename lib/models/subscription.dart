class Subscription {
  final int id;
  final int sectionId;
  final String course;
  final String section;
  final String lecturer;
  final String subscriptionDate;

  Subscription({
    required this.id,
    required this.sectionId,
    required this.section,
    required this.course,
    required this.lecturer,
    required this.subscriptionDate,
  });

  factory Subscription.fromJson(dynamic jsonObject) {
    return Subscription(
      id: jsonObject["id"],
      sectionId: jsonObject["section_id"],
      section: jsonObject["section"],
      course: jsonObject["course"],
      lecturer: jsonObject["lecturer"],
      subscriptionDate: jsonObject["subscription_date"],
    );
  }
}
