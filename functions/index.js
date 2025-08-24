const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Chat bildirimi gönder
exports.sendChatNotification = functions.https.onCall(async (data, context) => {
    try {
        // Kullanıcı kimlik doğrulaması kontrol et
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Kullanıcı kimlik doğrulanmamış');
        }

        const { recipientId, fcmToken, title, body, chatId, senderId, messageType, timestamp } = data;

        // Gerekli alanları kontrol et
        if (!fcmToken || !title || !body || !chatId || !senderId) {
            throw new functions.https.HttpsError('invalid-argument', 'Eksik parametreler');
        }

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
                messageType: messageType,
                timestamp: timestamp.toString(),
            },
            android: {
                notification: {
                    channelId: 'chat_channel',
                    priority: 'high',
                    sound: 'notification_sound',
                    icon: '@mipmap/ic_launcher',
                    color: '#FF5722',
                    tag: `chat_${chatId}`,
                    group: `chat_${chatId}`,
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

        // FCM ile bildirim gönder
        const response = await admin.messaging().send(message);

        // Bildirim logunu kaydet
        await admin.database().ref(`notifications/${recipientId}`).push({
            type: 'chat_message',
            chatId: chatId,
            senderId: senderId,
            messageType: messageType,
            title: title,
            body: body,
            timestamp: timestamp,
            fcmResponse: response,
            createdAt: admin.database.ServerValue.TIMESTAMP,
        });

        console.log('Chat bildirimi başarıyla gönderildi:', response);
        return { success: true, messageId: response };

    } catch (error) {
        console.error('Chat bildirimi hatası:', error);
        throw new functions.https.HttpsError('internal', 'Bildirim gönderilemedi', error);
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
