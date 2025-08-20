## Bildirim Türlerine Göre FCM Mesaj Formatları

Bu dosya, farklı bildirim türleri için server tarafından gönderilmesi gereken FCM mesaj formatlarını içerir.

### 1. Yeni Takas Teklifi (new_trade_offer)

```json
{
    "message": {
        "topic": "USER_ID",
        "notification": {
            "title": "Yeni Takas Teklifi 🔄",
            "body": "İlanınız için yeni bir takas teklifi var! Hemen kontrol edin 👀"
        },
        "data": {
            "keysandvalues": "{\"type\":\"new_trade_offer\",\"id\":\"OFFER_ID\"}"
        }
    }
}
```

### 2. Takas Onaylandı (trade_offer_approved)

```json
{
    "message": {
        "topic": "USER_ID",
        "notification": {
            "title": "Takas Onaylandı ✅",
            "body": "Harika! Takas teklifiniz kabul edildi. Artık takas yapabilirsiniz 🎉"
        },
        "data": {
            "keysandvalues": "{\"type\":\"trade_offer_approved\",\"id\":\"OFFER_ID\"}"
        }
    }
}
```

### 3. Teklif Reddedildi (trade_offer_rejected)

```json
{
    "message": {
        "topic": "USER_ID",
        "notification": {
            "title": "Teklif Reddedildi ❌",
            "body": "Takas teklifiniz reddedildi. Başka fırsatları keşfedin! 🔍"
        },
        "data": {
            "keysandvalues": "{\"type\":\"trade_offer_rejected\",\"id\":\"OFFER_ID\"}"
        }
    }
}
```

### 4. Takas Tamamlandı (trade_completed)

```json
{
    "message": {
        "topic": "USER_ID",
        "notification": {
            "title": "Takas Tamamlandı 🎊",
            "body": "Takasınız başarıyla tamamlandı! Yeni bir takas yapmaya ne dersiniz? 🚀"
        },
        "data": {
            "keysandvalues": "{\"type\":\"trade_completed\",\"id\":\"OFFER_ID\"}"
        }
    }
}
```

### 5. Öne Çıkarma Süresi Doldu (sponsor_expired)

```json
{
    "message": {
        "topic": "USER_ID",
        "notification": {
            "title": "Süre doldu ⏳",
            "body": "İlanın öne çıkma süresi sona erdi. Ama merak etme, tek tıkla tekrar öne çıkarabilirsin 🚀"
        },
        "data": {
            "keysandvalues": "{\"type\":\"sponsor_expired\",\"id\":\"PRODUCT_ID\"}"
        }
    }
}
```

## Önemli Notlar

1. **Topic**: Her bildirim kullanıcının ID'sine göre topic'e gönderilmelidir
2. **keysandvalues**: JSON string formatında type ve id bilgilerini içermelidir
3. **type**: Bildirim türünü belirler ve yönlendirme mantığında kullanılır
4. **id**: İlgili kaynak ID'si (offer_id veya product_id)

## Yönlendirme Davranışları

- **new_trade_offer, trade_offer_approved, trade_offer_rejected, trade_completed**: Teklif detay sayfasına yönlendirir
- **sponsor_expired**: İlan detay sayfasına yönlendirir
- **Bilinmeyen türler**: Bildirimler sayfasına yönlendirir

## Test Etmek İçin

Postman veya curl ile yukarıdaki formatları kullanarak test edebilirsiniz:

```bash
curl -X POST \
  https://fcm.googleapis.com/v1/projects/takasla-b2aa5/messages:send \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d 'YUKARIDAKI_JSON_FORMATLARINDAN_BİRİ'
```
