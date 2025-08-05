class Notification {
  final int id;
  final String title;
  final String body;
  final String type;
  final String typeId;
  final String url;
  final String createDate;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.typeId,
    required this.url,
    required this.createDate,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      typeId: json['type_id']?.toString() ?? '',
      url: json['url'] ?? '',
      createDate: json['create_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'type_id': typeId,
      'url': url,
      'create_date': createDate,
    };
  }

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: $type, createDate: $createDate)';
  }
} 