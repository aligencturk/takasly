class Condition {
  final String id;
  final String name;

  const Condition({
    required this.id,
    required this.name,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    // API'den gelen gerçek alanlar: conditionName, conditionID
    return Condition(
      id: json['conditionID']?.toString() ?? '',
      name: json['conditionName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditionID': id,
      'conditionName': name,
    };
  }

  Condition copyWith({
    String? id,
    String? name,
  }) {
    return Condition(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Condition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Condition(id: $id, name: $name)';
  }
} 