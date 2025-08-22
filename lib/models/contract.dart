class Contract {
  final int id;
  final String title;
  final String desc;

  Contract({required this.id, required this.title, required this.desc});

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'desc': desc};
  }

  @override
  String toString() {
    return 'Contract(id: $id, title: $title, desc: $desc)';
  }
}
