const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Chat bildirimi gönder
exports.sendChatNotification = functions.https.onCall(async (data, context) => {
    try {
        console.log('=== CHAT NOTIFICATION START ===');
        console.log('Timestamp:', new Date().toISOString());

        // Kullanıcı kimlik doğrulaması kontrol et (daha esnek)
        let currentUserId = 'unknown';
        if (context.auth) {
            currentUserId = context.auth.uid;
            console.log('✅ Kimlik doğrulanmış kullanıcı:', currentUserId);
        } else {
            console.log('⚠️ Kullanıcı kimlik doğrulanmamış, devam ediliyor...');
        }

        const { recipientId, fcmToken, title, body, chatId, senderId, messageType, timestamp } = data;

        console.log('📥 Gelen veriler:', {
            recipientId,
            fcmTokenLength: fcmToken ? fcmToken.length : 0,
            title,
            body,
            chatId,
            senderId,
            messageType,
            timestamp
        });

        // FCM token detaylı log
        console.log('🔍 FCM TOKEN DETAYI:', {
            token: fcmToken,
            tokenType: typeof fcmToken,
            tokenLength: fcmToken ? fcmToken.length : 0,
            tokenStart: fcmToken ? fcmToken.substring(0, 20) : 'null',
            tokenEnd: fcmToken ? fcmToken.substring(fcmToken.length - 10) : 'null',
            isValidFormat: fcmToken && typeof fcmToken === 'string' && fcmToken.length >= 100
        });

        // Gerekli alanları kontrol et
        if (!fcmToken || !title || !body || !chatId || !senderId) {
            console.error('❌ Eksik parametreler:', {
                recipientId,
                fcmToken: fcmToken ? 'mevcut' : 'eksik',
                title,
                body,
                chatId,
                senderId
            });
            throw new functions.https.HttpsError('invalid-argument', 'Eksik parametreler');
        }

        // FCM token formatını kontrol et
        if (typeof fcmToken !== 'string' || fcmToken.length < 100) {
            console.error('❌ Geçersiz FCM token formatı:', {
                type: typeof fcmToken,
                length: fcmToken ? fcmToken.length : 0,
                sample: fcmToken ? fcmToken.substring(0, 50) : 'null'
            });
            throw new functions.https.HttpsError('invalid-argument', 'Geçersiz FCM token formatı');
        }

        console.log('✅ FCM token kontrol edildi, uzunluk:', fcmToken.length);
        console.log('🔍 FCM token örneği:', fcmToken.substring(0, 50) + '...');

        // FCM mesajı hazırla
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: 'chat_message',
                chatId: chatId,
                senderId: senderId,
                messageType: messageType || 'text',
                timestamp: timestamp ? timestamp.toString() : Date.now().toString(),
            },
            android: {
                notification: {
                    channelId: 'chat_channel',
                    priority: 'high',
                    sound: 'notification_sound',
                    icon: '@drawable/ic_notification',
                    color: '#FF5722',
                    tag: `chat_${chatId}`,
                    // group alanını kaldır (Android'de desteklenmiyor)
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'notification_sound.aiff',
                        badge: 1,
                        category: 'chat_message',
                        'thread-id': chatId,
                    },
                },
            },
        };

        console.log('📱 FCM mesajı hazırlandı, gönderiliyor...');
        console.log('📤 FCM mesaj detayları:', {
            token: fcmToken.substring(0, 20) + '...',
            title: message.notification.title,
            body: message.notification.body,
            data: message.data
        });

        // FCM ile bildirim gönder
        const response = await admin.messaging().send(message);

        console.log('✅ FCM yanıtı:', response);

        // Bildirim logunu kaydet
        try {
            await admin.database().ref(`notifications/${recipientId}`).push({
                type: 'chat_message',
                chatId: chatId,
                senderId: senderId,
                messageType: messageType || 'text',
                title: title,
                body: body,
                timestamp: timestamp || Date.now(),
                fcmResponse: response,
                createdAt: admin.database.ServerValue.TIMESTAMP,
            });
            console.log('✅ Bildirim logu kaydedildi');
        } catch (dbError) {
            console.warn('⚠️ Bildirim logu kaydedilemedi:', dbError);
            // Ana işlemi etkilemesin
        }

        console.log('🎉 Chat bildirimi başarıyla gönderildi:', response);
        console.log('=== CHAT NOTIFICATION SUCCESS ===');
        return { success: true, messageId: response };

    } catch (error) {
        console.error('=== CHAT NOTIFICATION ERROR ===');
        console.error('❌ Chat bildirimi hatası:', error);

        // Hata tipine göre özel mesajlar
        let errorMessage = 'Bildirim gönderilemedi';

        if (error.code === 'messaging/invalid-registration-token') {
            errorMessage = 'FCM token geçersiz';
        } else if (error.code === 'messaging/registration-token-not-registered') {
            errorMessage = 'FCM token kayıtlı değil';
        } else if (error.code === 'messaging/quota-exceeded') {
            errorMessage = 'FCM kotası aşıldı';
        } else if (error.code === 'messaging/server-unavailable') {
            errorMessage = 'FCM sunucu hatası';
        } else if (error.code === 'messaging/internal-error') {
            errorMessage = 'FCM iç hata';
        }

        console.error('🔍 Hata detayı:', {
            code: error.code,
            message: error.message,
            stack: error.stack
        });

        console.error('=== CHAT NOTIFICATION ERROR END ===');
        throw new functions.https.HttpsError('internal', errorMessage, error);
    }
});

// Kullanıcı çıkış yaptığında FCM token'ı sil
exports.cleanupUserToken = functions.auth.user().onDelete(async (user) => {
    try {
        const uid = user.uid;

        // Kullanıcının FCM token'ını sil
        await admin.database().ref(`users/${uid}/fcmToken`).remove();

        // Kullanıcının bildirimlerini sil
        await admin.database().ref(`notifications/${uid}`).remove();

        console.log(`Kullanıcı ${uid} için temizlik tamamlandı`);
    } catch (error) {
        console.error('Kullanıcı temizlik hatası:', error);
    }
});

// Chat silindiğinde ilgili bildirimleri temizle
exports.cleanupChatNotifications = functions.database
    .ref('/chats/{chatId}')
    .onDelete(async (snapshot, context) => {
        try {
            const chatId = context.params.chatId;

            // Bu chat'e ait tüm bildirimleri bul ve sil
            const notificationsRef = admin.database().ref('notifications');
            const snapshot = await notificationsRef.orderByChild('chatId').equalTo(chatId).once('value');

            if (snapshot.exists()) {
                const updates = {};
                snapshot.forEach((childSnapshot) => {
                    updates[`${childSnapshot.key}`] = null;
                });

                await notificationsRef.update(updates);
                console.log(`Chat ${chatId} için ${Object.keys(updates).length} bildirim silindi`);
            }
        } catch (error) {
            console.error('Chat bildirim temizlik hatası:', error);
        }
    });
