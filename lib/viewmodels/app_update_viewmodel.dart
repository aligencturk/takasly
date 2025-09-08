import 'package:flutter/material.dart';
import '../services/app_update_service.dart';
import '../utils/logger.dart';

class AppUpdateViewModel extends ChangeNotifier {
  bool _isChecking = false;
  bool get isChecking => _isChecking;

  Future<void> checkForUpdate(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();
    try {
      await AppUpdateService.instance.checkAndPromptUpdate(context);
    } catch (e, s) {
      Logger.error('App update kontrol hatası: $e', error: e, stackTrace: s);
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}


