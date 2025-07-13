class District {
  final String id;
  final String name;
  final String cityId;

  const District({
    required this.id,
    required this.name,
    required this.cityId,
  });

  factory District.fromJson(Map<String, dynamic> json, {String? cityId}) {
    // API'den gelen gerçek alanlar: districtName, districtNo
    // districtNo'yu ID olarak kullanıyoruz
    final districtNo = json['districtNo']?.toString() ?? '';
    
    return District(
      id: districtNo,
      name: json['districtName'] ?? '',
      cityId: cityId ?? '', // Bu parametre olarak verilecek
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'districtID': id,
      'districtName': name,
      'cityID': cityId,
    };
  }

  District copyWith({
    String? id,
    String? name,
    String? cityId,
  }) {
    return District(
      id: id ?? this.id,
      name: name ?? this.name,
      cityId: cityId ?? this.cityId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'District(id: $id, name: $name, cityId: $cityId)';
  }
} 