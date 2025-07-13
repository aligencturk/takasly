class City {
  final String id;
  final String name;
  final String plateCode;

  const City({
    required this.id,
    required this.name,
    required this.plateCode,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    // API'den gelen gerçek alanlar: cityName, cityNo
    // cityNo'yu hem ID hem de plateCode olarak kullanıyoruz
    final cityNo = json['cityNo']?.toString() ?? '';
    
    return City(
      id: cityNo,
      name: json['cityName'] ?? '',
      plateCode: cityNo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityID': id,
      'cityName': name,
      'plateCode': plateCode,
    };
  }

  City copyWith({
    String? id,
    String? name,
    String? plateCode,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      plateCode: plateCode ?? this.plateCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'City(id: $id, name: $name, plateCode: $plateCode)';
  }
} 