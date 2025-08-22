# ContractDialog Kullanım Kılavuzu

Bu widget, üyelik sözleşmesi ve KVKK aydınlatma metni için onay kutucuklu dialog'lar oluşturmak için kullanılır.

## Özellikler

- ✅ Üyelik sözleşmesi ve KVKK metni desteği
- ✅ HTML içerik render etme
- ✅ Onay kutucuğu kontrolü
- ✅ Modern ve responsive tasarım
- ✅ Loading state yönetimi
- ✅ Error handling

## Kullanım Örnekleri

### 1. Üyelik Sözleşmesi Dialog'u

```dart
// Üyelik sözleşmesi için
showDialog(
  context: context,
  builder: (context) => ContractDialog(
    contractType: ContractType.membership,
    onContractAccepted: (accepted) {
      if (accepted) {
        // Kullanıcı sözleşmeyi kabul etti
        print('Üyelik sözleşmesi kabul edildi');
        // Kayıt işlemine devam et
      } else {
        // Kullanıcı sözleşmeyi reddetti
        print('Üyelik sözleşmesi reddedildi');
        // İşlemi iptal et
      }
    },
  ),
);
```

### 2. KVKK Aydınlatma Metni Dialog'u

```dart
// KVKK metni için
showDialog(
  context: context,
  builder: (context) => ContractDialog(
    contractType: ContractType.kvkk,
    onContractAccepted: (accepted) {
      if (accepted) {
        // Kullanıcı KVKK'yı kabul etti
        print('KVKK kabul edildi');
        // İşleme devam et
      } else {
        // Kullanıcı KVKK'yı reddetti
        print('KVKK reddedildi');
        // İşlemi iptal et
      }
    },
  ),
);
```

### 3. Özel Başlık ile Dialog

```dart
// Özel başlık ile
showDialog(
  context: context,
  builder: (context) => ContractDialog(
    contractType: ContractType.membership,
    customTitle: 'Özel Sözleşme Başlığı',
    onContractAccepted: (accepted) {
      // İşlem sonucu
    },
  ),
);
```

### 4. Önceden Yüklenmiş HTML ile Dialog

```dart
// HTML içeriği önceden yüklenmişse
showDialog(
  context: context,
  builder: (context) => ContractDialog(
    contractType: ContractType.membership,
    initialContractHtml: '<p>Önceden yüklenmiş HTML içeriği</p>',
    onContractAccepted: (accepted) {
      // İşlem sonucu
    },
  ),
);
```

## Kayıt Olma Aşamasında Kullanım

### Sıralı Dialog Gösterimi

```dart
Future<void> showRegistrationContracts() async {
  // Önce KVKK metni
  final kvkkAccepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ContractDialog(
      contractType: ContractType.kvkk,
      onContractAccepted: (accepted) {
        Navigator.of(context).pop(accepted);
      },
    ),
  );

  if (kvkkAccepted != true) {
    // KVKK reddedildi, kayıt işlemini iptal et
    return;
  }

  // Sonra üyelik sözleşmesi
  final membershipAccepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ContractDialog(
      contractType: ContractType.membership,
      onContractAccepted: (accepted) {
        Navigator.of(context).pop(accepted);
      },
    ),
  );

  if (membershipAccepted == true) {
    // Her iki sözleşme de kabul edildi, kayıt işlemine devam et
    _continueRegistration();
  }
}
```

### Tek Dialog'da Her İki Sözleşme

```dart
// Her iki sözleşmeyi de tek dialog'da göstermek için
// özel bir widget oluşturabilirsiniz
class RegistrationContractsDialog extends StatefulWidget {
  final Function(bool) onContractsAccepted;
  
  const RegistrationContractsDialog({
    Key? key,
    required this.onContractsAccepted,
  }) : super(key: key);

  @override
  State<RegistrationContractsDialog> createState() => _RegistrationContractsDialogState();
}

class _RegistrationContractsDialogState extends State<RegistrationContractsDialog> {
  bool _kvkkAccepted = false;
  bool _membershipAccepted = false;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          children: [
            // KVKK Checkbox
            CheckboxListTile(
              title: const Text('KVKK Aydınlatma Metni'),
              value: _kvkkAccepted,
              onChanged: (value) {
                setState(() {
                  _kvkkAccepted = value ?? false;
                });
              },
            ),
            
            // Üyelik Sözleşmesi Checkbox
            CheckboxListTile(
              title: const Text('Üyelik Sözleşmesi'),
              value: _membershipAccepted,
              onChanged: (value) {
                setState(() {
                  _membershipAccepted = value ?? false;
                });
              },
            ),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onContractsAccepted(false),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_kvkkAccepted && _membershipAccepted)
                        ? () => widget.onContractsAccepted(true)
                        : null,
                    child: const Text('Kabul Et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Endpoint'leri

- **Üyelik Sözleşmesi**: `GET /service/general/general/contract/4`
- **KVKK Metni**: `GET /service/general/general/contract/3`

## Gereksinimler

- `flutter_html: ^3.0.0-beta.2` paketi
- `ContractViewModel` provider'ı main.dart'ta tanımlanmış olmalı

## Notlar

- Dialog'lar `barrierDismissible: false` ile gösterilerek kullanıcının dışarı tıklayarak kapatması engellenebilir
- Her iki sözleşme de kabul edilmeden kayıt işlemi tamamlanmamalı
- HTML içeriği API'den otomatik olarak yüklenir
- Loading state'ler otomatik olarak yönetilir
