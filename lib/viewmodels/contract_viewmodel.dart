import 'package:flutter/foundation.dart';
import '../services/contract_service.dart';
import '../models/contract.dart';
import '../utils/logger.dart';

class ContractViewModel extends ChangeNotifier {
  final ContractService _contractService = ContractService();

  Contract? _membershipContract;
  Contract? _kvkkContract;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Contract? get membershipContract => _membershipContract;
  Contract? get kvkkContract => _kvkkContract;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Üyelik sözleşmesini API'den yükler
  Future<bool> loadMembershipContract() async {
    if (_membershipContract != null) {
      Logger.debug(
        '🔍 ContractViewModel - Membership contract already loaded, skipping API call',
        tag: 'ContractViewModel',
      );
      return true;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug(
        '🔍 ContractViewModel - Loading membership contract from API...',
        tag: 'ContractViewModel',
      );

      final response = await _contractService.getMembershipContract();

      if (response.isSuccess && response.data != null) {
        _membershipContract = response.data;
        Logger.info(
          '✅ ContractViewModel - Membership contract loaded successfully',
          tag: 'ContractViewModel',
        );
        Logger.debug(
          '🔍 ContractViewModel - Contract title: ${_membershipContract!.title}',
          tag: 'ContractViewModel',
        );
        return true;
      } else {
        _setError(response.error ?? 'Üyelik sözleşmesi yüklenemedi');
        Logger.error(
          '❌ ContractViewModel - Failed to load membership contract',
          tag: 'ContractViewModel',
        );
        return false;
      }
    } catch (e) {
      _setError('Üyelik sözleşmesi yükleme hatası: $e');
      Logger.error(
        '❌ ContractViewModel - Exception: $e',
        tag: 'ContractViewModel',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// KVKK aydınlatma metnini API'den yükler
  Future<bool> loadKvkkContract() async {
    if (_kvkkContract != null) {
      Logger.debug(
        '🔍 ContractViewModel - KVKK contract already loaded, skipping API call',
        tag: 'ContractViewModel',
      );
      return true;
    }

    _setLoading(true);
    _clearError();

    try {
      Logger.debug(
        '🔍 ContractViewModel - Loading KVKK contract from API...',
        tag: 'ContractViewModel',
      );

      final response = await _contractService.getKvkkContract();

      if (response.isSuccess && response.data != null) {
        _kvkkContract = response.data;
        Logger.info(
          '✅ ContractViewModel - KVKK contract loaded successfully',
          tag: 'ContractViewModel',
        );
        Logger.debug(
          '🔍 ContractViewModel - KVKK title: ${_kvkkContract!.title}',
          tag: 'ContractViewModel',
        );
        return true;
      } else {
        _setError(response.error ?? 'KVKK metni yüklenemedi');
        Logger.error(
          '❌ ContractViewModel - Failed to load KVKK contract',
          tag: 'ContractViewModel',
        );
        return false;
      }
    } catch (e) {
      _setError('KVKK yükleme hatası: $e');
      Logger.error(
        '❌ ContractViewModel - Exception: $e',
        tag: 'ContractViewModel',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Üyelik sözleşmesini zorla yeniler
  Future<void> refreshMembershipContract() async {
    _membershipContract = null;
    await loadMembershipContract();
  }

  /// KVKK metnini zorla yeniler
  Future<void> refreshKvkkContract() async {
    _kvkkContract = null;
    await loadKvkkContract();
  }

  /// Üyelik sözleşmesi içeriğini HTML olarak alır
  String get membershipContractHtml => _membershipContract?.desc ?? '';

  /// KVKK metni içeriğini HTML olarak alır
  String get kvkkContractHtml => _kvkkContract?.desc ?? '';

  /// Üyelik sözleşmesi başlığını alır
  String get membershipContractTitle =>
      _membershipContract?.title ?? 'Üyelik Sözleşmesi';

  /// KVKK metni başlığını alır
  String get kvkkContractTitle =>
      _kvkkContract?.title ?? 'KVKK Aydınlatma Metni';

  /// Üyelik sözleşmesi yüklenip yüklenmediğini kontrol eder
  bool get isMembershipContractLoaded => _membershipContract != null;

  /// KVKK metni yüklenip yüklenmediğini kontrol eder
  bool get isKvkkContractLoaded => _kvkkContract != null;

  /// Üyelik sözleşmesi içeriğini alır
  String get membershipContractContent => _membershipContract?.desc ?? '';

  /// KVKK metni içeriğini alır
  String get kvkkContractContent => _kvkkContract?.desc ?? '';

  // Private methods - State değişikliklerini güvenli şekilde yap
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
