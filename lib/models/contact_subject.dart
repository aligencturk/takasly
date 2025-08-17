import 'package:json_annotation/json_annotation.dart';

part 'contact_subject.g.dart';

@JsonSerializable()
class ContactSubject {
  final int subjectID;
  final String subjectTitle;

  const ContactSubject({required this.subjectID, required this.subjectTitle});

  factory ContactSubject.fromJson(Map<String, dynamic> json) {
    // Güvenli parse işlemi
    return ContactSubject(
      subjectID: _safeInt(json['subjectID']),
      subjectTitle: _safeString(json['subjectTitle']),
    );
  }

  Map<String, dynamic> toJson() => _$ContactSubjectToJson(this);

  /// Güvenli integer dönüşümü
  static int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  /// Güvenli string dönüşümü
  static String _safeString(dynamic value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return '';
  }

  ContactSubject copyWith({int? subjectID, String? subjectTitle}) {
    return ContactSubject(
      subjectID: subjectID ?? this.subjectID,
      subjectTitle: subjectTitle ?? this.subjectTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactSubject && other.subjectID == subjectID;
  }

  @override
  int get hashCode => subjectID.hashCode;

  @override
  String toString() {
    return 'ContactSubject(subjectID: $subjectID, subjectTitle: $subjectTitle)';
  }
}

@JsonSerializable()
class ContactSubjectsResponse {
  final bool error;
  final bool success;
  final ContactSubjectsData data;

  const ContactSubjectsResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory ContactSubjectsResponse.fromJson(Map<String, dynamic> json) =>
      _$ContactSubjectsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ContactSubjectsResponseToJson(this);
}

@JsonSerializable()
class ContactSubjectsData {
  final List<ContactSubject> subjects;

  const ContactSubjectsData({required this.subjects});

  factory ContactSubjectsData.fromJson(Map<String, dynamic> json) {
    // Subjects array'ini güvenli şekilde parse et
    final List<ContactSubject> subjectsList = [];

    if (json['subjects'] is List) {
      final subjectsJson = json['subjects'] as List;
      for (var subjectJson in subjectsJson) {
        if (subjectJson is Map<String, dynamic>) {
          try {
            subjectsList.add(ContactSubject.fromJson(subjectJson));
          } catch (e) {
            // Hatalı subject'i atla, devam et
            continue;
          }
        }
      }
    }

    return ContactSubjectsData(subjects: subjectsList);
  }

  Map<String, dynamic> toJson() => _$ContactSubjectsDataToJson(this);
}
