import 'package:upgrader/upgrader.dart';

class TurkishUpgraderMessages implements UpgraderMessages {
  @override
  String get body => 'Yeni bir güncelleme mevcut. En son özellikleri ve iyileştirmeleri almak için uygulamayı güncelleyin.';

  @override
  String? message(UpgraderMessage upgraderMessage) => 'Yeni bir güncelleme mevcut.';

  @override
  String get buttonTitleUpdate => 'Güncelle';

  @override
  String get buttonTitleLater => 'Daha Sonra';

  @override
  String get buttonTitleIgnore => 'Görmezden Gel';

  @override
  String get prompt => 'Güncelleme';

  @override
  String get title => 'Güncelleme Mevcut';

  @override
  String get languageCode => 'tr';

  @override
  String get releaseNotes => 'Sürüm notları mevcut değil.';
}
