import 'dart:convert';
import '../core/http_client.dart';
import '../core/constants.dart';
import '../models/contact_subject.dart';
import '../utils/logger.dart';

class ContactService {
  final HttpClient _httpClient = HttpClient();

  /// İletişim konularını API'den alır
  /// GET /service/general/contact/subjects
  Future<ApiResponse<List<ContactSubject>>> getContactSubjects() async {
    try {
      Logger.debug(
        '🔍 ContactService - İletişim konuları alınıyor...',
        tag: 'ContactService',
      );

      final response = await _httpClient.getWithBasicAuth(
        '/service/general/contact/subjects',
        fromJson: (json) {
          Logger.debug(
            '🔍 ContactService - Raw response: $json',
            tag: 'ContactService',
          );

          if (json is Map<String, dynamic>) {
            // Error kontrolü
            if (json['error'] == true) {
              Logger.error(
                '❌ ContactService - API error: ${json['message'] ?? json['error_message']}',
                tag: 'ContactService',
              );
              return <ContactSubject>[];
            }

            // Success kontrolü
            if (json['success'] != true) {
              Logger.warning(
                '⚠️ ContactService - API success false',
                tag: 'ContactService',
              );
              return <ContactSubject>[];
            }

            // Data kontrolü
            if (json['data'] == null || json['data']['subjects'] == null) {
              Logger.warning(
                '⚠️ ContactService - No subjects data found',
                tag: 'ContactService',
              );
              return <ContactSubject>[];
            }

            final subjects = json['data']['subjects'] as List<dynamic>;
            final List<ContactSubject> contactSubjects = [];

            for (var subjectJson in subjects) {
              if (subjectJson is Map<String, dynamic>) {
                try {
                  contactSubjects.add(ContactSubject.fromJson(subjectJson));
                } catch (e) {
                  Logger.error(
                    '❌ ContactService - Subject parse error: $e',
                    tag: 'ContactService',
                  );
                  // Hatalı subject'i atla, devam et
                  continue;
                }
              }
            }

            Logger.info(
              '✅ ContactService - ${contactSubjects.length} subjects loaded successfully',
              tag: 'ContactService',
            );

            return contactSubjects;
          }

          Logger.error(
            '❌ ContactService - Invalid response format',
            tag: 'ContactService',
          );
          return <ContactSubject>[];
        },
      );

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(response.data!);
      } else {
        Logger.error(
          '❌ ContactService - API call failed: ${response.error}',
          tag: 'ContactService',
        );
        return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error('❌ ContactService - Exception: $e', tag: 'ContactService');
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }

  /// İletişim formu gönderir
  /// POST /service/general/contact/sendMessage
  Future<ApiResponse<Map<String, dynamic>>> sendContactMessage({
    required String userToken,
    required int subjectID,
    required String userName,
    required String userEmail,
    required String message,
  }) async {
    try {
      Logger.debug(
        '🔍 ContactService - İletişim mesajı gönderiliyor...',
        tag: 'ContactService',
      );
      Logger.debug(
        'Parameters: subjectID=$subjectID, userName=$userName, userEmail=$userEmail',
        tag: 'ContactService',
      );

      final body = {
        'userToken': userToken,
        'subject': subjectID,
        'userName': userName,
        'userEmail': userEmail,
        'message': message,
      };

      Logger.debug(
        '📤 ContactService - Request body: ${json.encode(body)}',
        tag: 'ContactService',
      );

      final response = await _httpClient.postWithBasicAuth(
        '/service/general/contact/sendMessage',
        body: body,
        useBasicAuth: true,
        fromJson: (json) {
          Logger.debug(
            '📥 ContactService - Send response: $json',
            tag: 'ContactService',
          );

          if (json is Map<String, dynamic>) {
            // Error kontrolü
            if (json['error'] == true) {
              Logger.error(
                '❌ ContactService - Send API error: ${json['message'] ?? json['error_message']}',
                tag: 'ContactService',
              );
              return <String, dynamic>{};
            }

            // Success kontrolü ve data parse
            if (json['success'] == true && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;

              Logger.info(
                '✅ ContactService - Message sent successfully: ${data['success_message']}',
                tag: 'ContactService',
              );
              Logger.debug(
                '📥 ContactService - Message ID: ${data['message_id']}',
                tag: 'ContactService',
              );

              return {
                'success': true,
                'success_message':
                    data['success_message']?.toString() ??
                    'Mesajınız başarıyla gönderildi.',
                'message_id': data['message_id']?.toString() ?? '',
              };
            }

            Logger.warning(
              '⚠️ ContactService - Send API success false or no data',
              tag: 'ContactService',
            );
            return <String, dynamic>{};
          }

          Logger.error(
            '❌ ContactService - Invalid send response format',
            tag: 'ContactService',
          );
          return <String, dynamic>{};
        },
      );

      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {
        return ApiResponse.success(response.data!);
      } else {
        Logger.error(
          '❌ ContactService - Send API call failed: ${response.error}',
          tag: 'ContactService',
        );
        return ApiResponse.error(response.error ?? ErrorMessages.unknownError);
      }
    } catch (e) {
      Logger.error(
        '❌ ContactService - Send Exception: $e',
        tag: 'ContactService',
      );
      return ApiResponse.error(ErrorMessages.unknownError);
    }
  }
}
