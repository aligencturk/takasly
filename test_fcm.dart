import 'dart:convert';
import 'package:http/http.dart' as http;

/// Firebase Console'dan test FCM mesajı gönderme
/// Bu dosya sadece test amaçlıdır, production'da kullanılmamalıdır
class FCMTestService {
  static const String _fcmApiUrl = 'https://fcm.googleapis.com/v1/projects/takasla-b2aa5/messages:send';
  
  /// Test FCM mesajı gönder
  static Future<bool> sendTestMessage({
    required String fcmToken,
    required String serverKey, // Firebase Console > Project Settings > Cloud Messaging > Server key
  }) async {
    try {
      print('🚀 Test FCM mesajı gönderiliyor...');
      print('📱 FCM Token: ${fcmToken.substring(0, 20)}...');
      
      final message = {
        "message": {
          "token": fcmToken,
          "notification": {
            "title": "Test Bildirimi",
            "body": "Bu bir test bildirimidir. FCM çalışıyor! 🎉"
          },
          "data": {
            "type": "test",
            "id": "1",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          },
          "android": {
            "notification": {
              "channel_id": "high_importance_channel",
              "priority": "high",
              "default_sound": true,
              "default_vibrate_timings": true,
              "default_light_settings": true,
            }
          },
          "apns": {
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
              }
            }
          }
        }
      };

      final response = await http.post(
        Uri.parse(_fcmApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(message),
      );

      print('📡 FCM Response Status: ${response.statusCode}');
      print('📡 FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Test FCM mesajı başarıyla gönderildi!');
        return true;
      } else {
        print('❌ FCM mesaj gönderme hatası: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ FCM mesaj gönderme exception: $e');
      return false;
    }
  }
  
  /// Toplu test mesajı gönder (topic kullanarak)
  static Future<bool> sendTestMessageToTopic({
    required String topic,
    required String serverKey,
  }) async {
    try {
      print('🚀 Topic\'e test FCM mesajı gönderiliyor...');
      print('📢 Topic: $topic');
      
      final message = {
        "message": {
          "topic": topic,
          "notification": {
            "title": "Topic Test Bildirimi",
            "body": "Bu bir topic test bildirimidir. FCM çalışıyor! 🎉"
          },
          "data": {
            "type": "topic_test",
            "id": "2",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          },
          "android": {
            "notification": {
              "channel_id": "high_importance_channel",
              "priority": "high",
              "default_sound": true,
              "default_vibrate_timings": true,
              "default_light_settings": true,
            }
          },
          "apns": {
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
              }
            }
          }
        }
      };

      final response = await http.post(
        Uri.parse(_fcmApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(message),
      );

      print('📡 FCM Response Status: ${response.statusCode}');
      print('📡 FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Topic test FCM mesajı başarıyla gönderildi!');
        return true;
      } else {
        print('❌ Topic FCM mesaj gönderme hatası: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Topic FCM mesaj gönderme exception: $e');
      return false;
    }
  }
}

/// Test kullanımı
void main() async {
  print('🧪 FCM Test Servisi Başlatılıyor...');
  print('');
  print('📋 Kullanım:');
  print('1. Firebase Console > Project Settings > Cloud Messaging > Server key alın');
  print('2. Uygulamada FCM token alın');
  print('3. Aşağıdaki parametreleri güncelleyin:');
  print('');
  
  // Test parametreleri - bunları güncelleyin
  const String fcmToken = 'YOUR_FCM_TOKEN_HERE';
  const String serverKey = 'YOUR_SERVER_KEY_HERE';
  const String topic = 'test_topic';
  
  if (fcmToken == 'YOUR_FCM_TOKEN_HERE' || serverKey == 'YOUR_SERVER_KEY_HERE') {
    print('⚠️  Lütfen FCM token ve server key\'i güncelleyin!');
    return;
  }
  
  print('🧪 Test 1: Tek cihaza mesaj gönderme');
  await FCMTestService.sendTestMessage(
    fcmToken: fcmToken,
    serverKey: serverKey,
  );
  
  print('');
  print('🧪 Test 2: Topic\'e mesaj gönderme');
  await FCMTestService.sendTestMessageToTopic(
    topic: topic,
    serverKey: serverKey,
  );
  
  print('');
  print('✅ Test tamamlandı!');
}
