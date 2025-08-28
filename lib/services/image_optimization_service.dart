import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:takasly/utils/logger.dart';

/// Görsel dosya dönüşüm servisi
/// Backend tarafında optimizasyon yapıldığı için sadece dosya dönüşümü yapar
class ImageOptimizationService {
  /// XFile listesini File listesine dönüştürür
  /// [xFiles] - XFile listesi (ImagePicker'dan gelen)
  /// [maxImages] - Maksimum işlenecek görsel sayısı
  /// Returns: File listesi
  static Future<List<File>> convertXFilesToFiles(
    List<XFile> xFiles, {
    int maxImages = 5,
  }) async {
    try {
      Logger.debug(
        '🖼️ ImageOptimizationService - Converting ${xFiles.length} XFiles to Files',
      );

      List<File> files = xFiles
          .take(maxImages)
          .map((xFile) => File(xFile.path))
          .toList();
      Logger.debug(
        '🖼️ ImageOptimizationService - Conversion completed: ${files.length} files',
      );
      return files;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error converting XFiles: $e',
      );
      return xFiles.take(maxImages).map((xFile) => File(xFile.path)).toList();
    }
  }

  /// Tek bir XFile'ı File'a dönüştürür (profil fotoğrafı için)
  /// [xFile] - Dönüştürülecek XFile
  /// Returns: File
  static Future<File> convertSingleXFileToFile(XFile xFile) async {
    try {
      Logger.debug(
        '🖼️ ImageOptimizationService - Converting single XFile to File: ${xFile.path}',
      );

      final File file = File(xFile.path);
      Logger.debug('🖼️ ImageOptimizationService - Conversion completed');
      return file;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error converting single XFile: $e',
      );
      return File(xFile.path);
    }
  }

  /// Dosya boyutu kontrolü yapar
  /// [file] - Kontrol edilecek dosya
  /// Returns: Dosya uygun boyutta mı?
  static Future<bool> isFileSizeAcceptable(File file) async {
    try {
      final int fileSize = await file.length();
      // Maksimum dosya boyutu 10MB olarak ayarlandı (backend optimizasyon yapacak)
      const int maxFileSizeBytes = 10 * 1024 * 1024;
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error checking file size: $e',
      );
      return false;
    }
  }

  /// Dosya boyutunu human-readable format'ta döner
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Uint8List'i File'a dönüştürür
  /// [imageBytes] - Dönüştürülecek görsel bytes
  /// [fileName] - Dosya adı
  /// Returns: File
  static Future<File> convertUint8ListToFile(
    List<int> imageBytes,
    String fileName,
  ) async {
    try {
      Logger.debug(
        '🖼️ ImageOptimizationService - Converting Uint8List to File: $fileName',
      );

      // Geçici dosya yolu oluştur
      final Directory tempDir = Directory.systemTemp;
      final String filePath = '${tempDir.path}/$fileName';

      // Dosyayı oluştur ve yaz
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      Logger.debug(
        '🖼️ ImageOptimizationService - File created: ${file.path} (${imageBytes.length} bytes)',
      );

      return file;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error converting Uint8List to File: $e',
      );
      rethrow;
    }
  }
}
