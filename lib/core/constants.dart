class ApiConstants {
  static const String baseUrl = 'https://api.rivorya.com/takasly/';
  static const String apiVersion = '';
  static const String fullUrl = baseUrl;

  // Basic Auth sabitleri (API'nin kendi credential'ları)
  static const String basicAuthUsername = 'Tk2BULs2IC4HJN2nlvp9T5ycBoyMJD';
  static const String basicAuthPassword = 'vRP4rTBAqm1tm2I17I1EI3PHFtE5l0';

  // Endpoints
  static const String products = '/products';
  static const String users = '/users';
  static const String trades = '/trades';
  static const String categories = '/categories';
  static const String chat = '/chat';
  static const String auth = '/auth';
  static const String login = '/service/auth/login';
  static const String register = '/service/auth/register';
  static const String forgotPassword = '/service/auth/forgotPassword';
  static const String updatePassword =
      '/service/auth/forgotPassword/updatePass';
  static const String checkCode = '/service/auth/code/checkCode';
  static const String againSendCode = '/service/auth/code/againSendCode';
  static const String profile = '/auth/profile';

  // User Service Endpoints
  static const String userProfile = '/service/user/id';
  static const String updateAccount = '/service/user/update/account';
  static const String updateUserPassword = '/service/user/update/password';
  static const String deleteUser = '/service/user/delete';
  static const String addProduct =
      '/service/user/product'; // {userId}/addProduct eklenecek
  static const String userProducts =
      '/service/user/product'; // {userId}/productList eklenecek
  static const String allProducts = 'service/user/product/allProductList';
  static const String categoriesList = '/service/general/general/categories/0';
  
  // Trade Service Endpoints
  static const String startTrade = '/service/user/product/startTrade';
  static const String tradeComplete = '/service/user/product/tradeComplete';
  static const String confirmTrade = '/service/user/product/confirmTrade';
  static const String userTrades = '/service/user/product'; // {userId}/tradeList eklenecek
  static const String tradeStatuses = '/service/general/general/tradeStatuses';
  static const String deliveryTypes = '/service/general/general/deliveryTypes';

  // Headers
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer ';
  static const String basic = 'Basic ';

  // Status Codes
  static const int success = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int gone = 410;
  static const int expectationFailed = 417;
  static const int serverError = 500;
}

class AppConstants {
  static const String appName = 'Takasly';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 50;
  static const int maxDescriptionLength = 500;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Animation Durations
  static const int shortAnimation = 200;
  static const int mediumAnimation = 400;
  static const int longAnimation = 600;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

class ErrorMessages {
  static const String networkError = 'İnternet bağlantınızı kontrol edin';
  static const String serverError =
      'Sunucu hatası, lütfen daha sonra tekrar deneyin';
  static const String unknownError = 'Bilinmeyen bir hata oluştu';
  static const String timeoutError = 'İstek zaman aşımına uğradı';
  static const String noDataFound = 'Veri bulunamadı';
  static const String invalidCredentials = 'Geçersiz kullanıcı bilgileri';
  static const String userNotFound = 'Kullanıcı bulunamadı';
  static const String emailAlreadyExists =
      'Bu e-posta adresi zaten kullanılmakta';
  static const String weakPassword = 'Şifre en az 6 karakter olmalıdır';
  static const String invalidEmail = 'Geçersiz e-posta adresi';
  static const String fieldRequired = 'Bu alan zorunludur';
  static const String productNotFound = 'Ürün bulunamadı';
  static const String tradeNotFound = 'Takas bulunamadı';
  static const String accessDenied = 'Erişim reddedildi';
  static const String sessionExpired =
      'Oturumunuz sona erdi, lütfen tekrar giriş yapın';
  static const String forgotPasswordFailed =
      'Şifre sıfırlama talebi gönderilemedi';
  static const String emailNotFound =
      'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
  static const String invalidVerificationCode = 'Geçersiz doğrulama kodu';
  static const String passwordUpdateFailed = 'Şifre güncelleme başarısız';
  static const String verificationCodeExpired = 'Doğrulama kodu süresi dolmuş';
  static const String emailVerificationFailed = 'E-posta doğrulama başarısız';
  static const String emailVerificationCodeInvalid =
      'Geçersiz e-posta doğrulama kodu';
  static const String emailVerificationCodeExpired =
      'E-posta doğrulama kodu süresi dolmuş';
}

class SuccessMessages {
  static const String loginSuccess = 'Giriş başarılı';
  static const String registerSuccess = 'Kayıt başarılı';
  static const String logoutSuccess = 'Çıkış başarılı';
  static const String profileUpdated = 'Profil güncellendi';
  static const String productCreated = 'Ürün oluşturuldu';
  static const String productUpdated = 'Ürün güncellendi';
  static const String productDeleted = 'Ürün silindi';
  static const String tradeCreated = 'Takas teklifi gönderildi';
  static const String tradeAccepted = 'Takas teklifi kabul edildi';
  static const String tradeRejected = 'Takas teklifi reddedildi';
  static const String tradeCanceled = 'Takas iptal edildi';
  static const String messagesSent = 'Mesaj gönderildi';
  static const String forgotPasswordSuccess =
      'Şifre sıfırlama bağlantısı e-postanıza gönderildi';
  static const String passwordResetEmailSent =
      'E-postanızı kontrol edin, şifre sıfırlama talimatları gönderildi';
  static const String passwordUpdateSuccess = 'Şifreniz başarıyla güncellendi';
  static const String passwordChanged =
      'Şifre değişikliği tamamlandı, giriş yapabilirsiniz';
  static const String emailVerificationSuccess =
      'E-posta adresiniz başarıyla doğrulandı';
  static const String emailVerified =
      'E-posta doğrulandı, artık uygulamayı kullanabilirsiniz';
  static const String registrationComplete =
      'Kayıt işlemi tamamlandı, giriş yapabilirsiniz';
  static const String verificationCodeResent =
      'Doğrulama kodu tekrar gönderildi';
}

class Gender {
  static const int male = 1;
  static const int female = 2;
  static const int unspecified = 3;

  static String getGenderText(int gender) {
    switch (gender) {
      case male:
        return 'Erkek';
      case female:
        return 'Kadın';
      case unspecified:
        return 'Belirtilmemiş';
      default:
        return 'Belirtilmemiş';
    }
  }

  static List<Map<String, dynamic>> getGenderOptions() {
    return [
      {'value': male, 'text': 'Erkek'},
      {'value': female, 'text': 'Kadın'},
      {'value': unspecified, 'text': 'Belirtilmemiş'},
    ];
  }
}
