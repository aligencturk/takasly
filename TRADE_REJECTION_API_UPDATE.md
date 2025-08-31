# Takas Reddedilme Durumu API Güncellemesi

## 📋 İstek Detayları

**Endpoint:** `{{BASE_URL}}service/user/product/{userId}/tradeList`
**Method:** GET

## 🎯 Gerekli Değişiklik

API response'una yeni bir alan eklenmesi gerekiyor:

### Yeni Alan
- **`isTradeRejected`** (boolean): Herhangi bir taraf takas teklifini reddettiyse `true` döner

## 🔧 İş Mantığı

### Takas Reddedilme Kuralları:
- **Receiver reddederse:** Hem receiver hem sender durumu **7** olur
- **Sender reddederse:** Hem sender hem receiver durumu **7** olur  
- **API Response:** `isTradeRejected: true` döner
- **Kullanıcı Deneyimi:** Her iki taraf da "reddedildi" mesajını görür

### isTradeRejected Hesaplama Mantığı:
```javascript
isTradeRejected = (senderStatusID === 7 || receiverStatusID === 7)
```

## 📱 Flutter (Frontend) Tarafında Yapılan Değişiklikler

### 1. UserTrade Modeli Güncellemesi
`UserTrade` modeline `isTradeRejected` alanı eklendi:

```dart
class UserTrade {
  // ... diğer alanlar
  final bool isTradeRejected; // Herhangi bir taraf reddettiyse true döner
  
  // Constructor'da hesaplama
  factory UserTrade.fromJson(Map<String, dynamic> json) {
    // ...
    final isTradeRejected = (senderStatusID == 7 || receiverStatusID == 7);
    // ...
  }
}
```

### 2. TradeCard Widget Güncellemeleri
- **Durum Gösterimi:** `isTradeRejected: true` ise durum "Reddedildi" olarak gösterilir
- **Özel Mesaj:** Reddedilen takaslar için kırmızı uyarı mesajı gösterilir
- **Buton Kontrolü:** Reddedilen takaslar için "Takası Tamamla" ve "Puan Ver" butonları gizlenir
- **Renk Kodlaması:** Reddedilen takaslar kırmızı renk ile vurgulanır

## 📄 Mevcut API Response Örneği

```json
{
  "error": false,
  "success": true,
  "data": {
    "trades": [
      {
        "offerID": 123,
        "senderUserID": 456,
        "receiverUserID": 789,
        "senderStatusID": 7,    // Reddedildi durumu
        "receiverStatusID": 7,   // Reddedildi durumu  
        "senderStatusTitle": "Reddedildi",
        "receiverStatusTitle": "Reddedildi",
        // ... diğer alanlar
      }
    ]
  }
}
```

## 🎯 Beklenen API Response (Güncelleme Sonrası)

```json
{
  "error": false,
  "success": true,
  "data": {
    "trades": [
      {
        "offerID": 123,
        "senderUserID": 456,
        "receiverUserID": 789,
        "senderStatusID": 7,
        "receiverStatusID": 7,
        "senderStatusTitle": "Reddedildi", 
        "receiverStatusTitle": "Reddedildi",
        "isTradeRejected": true,    // 🆕 YENİ ALAN
        // ... diğer alanlar
      }
    ]
  }
}
```

## ✅ Durum Kodları

| StatusID | Durum | Açıklama |
|----------|--------|-----------|
| 1 | Bekliyor | Takas teklifi beklemede |
| 2 | Onaylandı | Takas onaylandı |
| 7 | Reddedildi | Takas reddedildi |
| ... | ... | Diğer durumlar |

## 🔍 Test Senaryoları

1. **Normal Takas:** `senderStatusID: 1, receiverStatusID: 1` → `isTradeRejected: false`
2. **Sender Reddetti:** `senderStatusID: 7, receiverStatusID: 7` → `isTradeRejected: true`
3. **Receiver Reddetti:** `senderStatusID: 7, receiverStatusID: 7` → `isTradeRejected: true`

## 📞 İletişim

Bu değişiklik acil olarak uygulanması gereken bir güncelleme. Sorular için iletişime geçebilirsiniz.

---
**Tarih:** 31 Ağustos 2025  
**Dosya:** TRADE_REJECTION_API_UPDATE.md
