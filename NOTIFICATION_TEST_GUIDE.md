## Bildirim Yönlendirme Test Kılavuzu

Bu dosya, bildirim tıklama yönlendirmelerini test etmek için adımları içerir.

### Test Edebileceğiniz Bildirim Türleri

1. **Yeni Takas Teklifi (new_trade_offer)**
   - Teklif detay sayfasına yönlendirir
   - Test için keysandvalues: `{"type":"new_trade_offer","id":"123"}`

2. **Takas Onaylandı (trade_offer_approved)**
   - Teklif detay sayfasına yönlendirir
   - Test için keysandvalues: `{"type":"trade_offer_approved","id":"123"}`

3. **Teklif Reddedildi (trade_offer_rejected)**
   - Teklif detay sayfasına yönlendirir
   - Test için keysandvalues: `{"type":"trade_offer_rejected","id":"123"}`

4. **Takas Tamamlandı (trade_completed)**
   - Teklif detay sayfasına yönlendirir
   - Test için keysandvalues: `{"type":"trade_completed","id":"123"}`

5. **Öne Çıkarma Süresi Doldu (sponsor_expired)**
   - İlan detay sayfasına yönlendirir
   - Test için keysandvalues: `{"type":"sponsor_expired","id":"456"}`

### Test Methodları

#### 1. NotificationService Test Notification
```dart
// Kod içinde test notification gönder
NotificationService.instance.sendTestNotification(
  type: 'new_trade_offer',
  id: '123'
);
```

#### 2. FCM API ile Test
Postman veya curl ile aşağıdaki format ile test edin:

```json
{
    "message": {
        "topic": "USER_ID",
        "notification": {
            "title": "Test Bildirimi",
            "body": "Bu bir test bildirimidir"
        },
        "data": {
            "keysandvalues": "{\"type\":\"new_trade_offer\",\"id\":\"123\"}"
        }
    }
}
```

### Test Senaryoları

#### Senaryo 1: Foreground Bildirim
1. Uygulama açıkken bildirim gönder
2. Bildirimin görüntülenip görüntülenmediğini kontrol et
3. Bildirime tıkla
4. Doğru sayfaya yönlendirilip yönlendirilmediğini kontrol et

#### Senaryo 2: Background Bildirim
1. Uygulamayı background'a al (home tuşu)
2. Bildirim gönder
3. Bildirime tıkla
4. Uygulamanın doğru sayfada açılıp açılmadığını kontrol et

#### Senaryo 3: Cold Start Bildirim
1. Uygulamayı tamamen kapat
2. Bildirim gönder
3. Bildirime tıkla
4. Uygulamanın açılıp doğru sayfaya yönlendirilip yönlendirilmediğini kontrol et

### Beklenen Davranışlar

| Bildirim Türü | Hedef Sayfa | Route |
|---------------|-------------|-------|
| new_trade_offer | Teklif Detayı | /trade-detail |
| trade_offer_approved | Teklif Detayı | /trade-detail |
| trade_offer_rejected | Teklif Detayı | /trade-detail |
| trade_completed | Teklif Detayı | /trade-detail |
| sponsor_expired | İlan Detayı | /product-detail |
| Bilinmeyen | Bildirimler | /notifications |

### Debug İpuçları

1. **Logger kontrolleri**: Console'da `NotificationService` tag'li logları kontrol edin
2. **Data formatı**: `keysandvalues` alanının doğru JSON formatında olduğundan emin olun
3. **Context kontrolü**: Navigation sırasında context'in null olmadığından emin olun
4. **Route kontrolü**: Hedef route'ların main.dart'ta tanımlandığından emin olun

### Sorun Giderme

**Bildirim görünmüyor:**
- FCM izinlerinin verildiğini kontrol edin
- NotificationService'in init edildiğini kontrol edin
- Android channel ayarlarını kontrol edin

**Yönlendirme çalışmıyor:**
- ErrorHandlerService.navigatorKey'in tanımlı olduğunu kontrol edin
- Hedef sayfanın route'unda hata olmadığından emin olun
- Data parsing'in doğru çalıştığını kontrol edin

**Navigation hatası:**
- Context'in null olmadığından emin olun
- Route arguments'ların doğru formatda olduğunu kontrol edin
- BuildContext'in async gap sonrası kullanılmadığından emin olun
