// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


Map<String, dynamic> _$ContactSubjectToJson(ContactSubject instance) =>
    <String, dynamic>{
      'subjectID': instance.subjectID,
      'subjectTitle': instance.subjectTitle,
    };

ContactSubjectsResponse _$ContactSubjectsResponseFromJson(
  Map<String, dynamic> json,
) => ContactSubjectsResponse(
  error: json['error'] as bool,
  success: json['success'] as bool,
  data: ContactSubjectsData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ContactSubjectsResponseToJson(
  ContactSubjectsResponse instance,
) => <String, dynamic>{
  'error': instance.error,
  'success': instance.success,
  'data': instance.data,
};


Map<String, dynamic> _$ContactSubjectsDataToJson(
  ContactSubjectsData instance,
) => <String, dynamic>{'subjects': instance.subjects};
