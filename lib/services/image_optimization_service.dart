import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:takasly/utils/logger.dart';
import 'package:image/image.dart' as img;

/// Görsel dosya dönüşüm servisi
/// Backend tarafında optimizasyon yapıldığı için sadece dosya dönüşümü yapar
/// EXIF orientation bilgisini korur ve fotoğrafların doğru açıda yüklenmesini sağlar
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

  /// Uint8List'i File'a dönüştürür ve orientation'ı düzeltir
  /// [imageBytes] - Dönüştürülecek görsel bytes
  /// [fileName] - Dosya adı
  /// Returns: File
  static Future<File> convertUint8ListToFile(
    List<int> imageBytes,
    String fileName,
  ) async {
    try {
      Logger.debug(
        '🖼️ ImageOptimizationService - Converting Uint8List to File with orientation fix: $fileName',
      );

      // Geçici dosya yolu oluştur
      final Directory tempDir = Directory.systemTemp;
      final String filePath = '${tempDir.path}/$fileName';

      // Orientation'ı düzelt ve dosyayı oluştur
      final Uint8List processedBytes = await _fixImageOrientation(imageBytes);
      final File file = File(filePath);
      await file.writeAsBytes(processedBytes);

      Logger.debug(
        '🖼️ ImageOptimizationService - File created with orientation fix: ${file.path} (${processedBytes.length} bytes)',
      );

      return file;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error converting Uint8List to File: $e',
      );
      rethrow;
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

  /// Fotoğraf orientation'ını düzeltir
  /// [imageBytes] - Düzeltilecek görsel bytes
  /// Returns: Orientation'ı düzeltilmiş görsel bytes
  static Future<Uint8List> _fixImageOrientation(List<int> imageBytes) async {
    try {
      // Image paketi ile görseli decode et
      final img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        Logger.warning(
          '🖼️ ImageOptimizationService - Could not decode image, returning original',
        );
        return Uint8List.fromList(imageBytes);
      }

      // EXIF metadata'yı oku ve orientation'ı belirle
      final int orientation = _getImageOrientation(imageBytes);
      Logger.debug(
        '🖼️ ImageOptimizationService - Detected orientation: $orientation',
      );

      // Orientation'a göre döndür
      final img.Image orientedImage = _applyOrientation(image, orientation);

      // JPEG formatında encode et (kaliteyi koru)
      final List<int> processedBytes = img.encodeJpg(
        orientedImage,
        quality: 95,
      );

      Logger.debug(
        '🖼️ ImageOptimizationService - Image orientation fixed: ${imageBytes.length} -> ${processedBytes.length} bytes',
      );

      return Uint8List.fromList(processedBytes);
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error fixing orientation: $e',
      );
      // Hata durumunda orijinal bytes'ı döndür
      return Uint8List.fromList(imageBytes);
    }
  }

  /// EXIF metadata'dan orientation bilgisini al
  /// [imageBytes] - Görsel bytes
  /// Returns: Orientation değeri (1-8)
  static int _getImageOrientation(List<int> imageBytes) {
    try {
      // JPEG EXIF header'ını ara
      final String hexString = imageBytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      // EXIF marker'ı ara (FFE1)
      final int exifIndex = hexString.indexOf('ffe1');
      if (exifIndex == -1) {
        Logger.debug(
          '🖼️ ImageOptimizationService - No EXIF data found, using default orientation 1',
        );
        return 1;
      }

      // Orientation tag'ini ara (0112)
      final int orientationIndex = hexString.indexOf('0112', exifIndex);
      if (orientationIndex == -1) {
        Logger.debug(
          '🖼️ ImageOptimizationService - No orientation tag found, using default orientation 1',
        );
        return 1;
      }

      // Orientation değerini oku (2 byte sonra)
      final int valueIndex = orientationIndex + 8; // 0112 + 2 byte offset
      if (valueIndex + 4 <= hexString.length) {
        final String orientationHex = hexString.substring(
          valueIndex,
          valueIndex + 4,
        );
        final int orientation = int.parse(orientationHex, radix: 16);
        Logger.debug(
          '🖼️ ImageOptimizationService - EXIF orientation value: $orientation',
        );
        return orientation;
      }

      return 1;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error reading EXIF orientation: $e',
      );
      return 1;
    }
  }

  /// Orientation bilgisini uygula
  /// [image] - İşlenecek görsel
  /// [orientation] - EXIF orientation değeri
  /// Returns: Orientation'ı düzeltilmiş görsel
  static img.Image _applyOrientation(img.Image image, int orientation) {
    try {
      Logger.debug(
        '🖼️ ImageOptimizationService - Applying orientation $orientation to image ${image.width}x${image.height}',
      );

      img.Image orientedImage = image;

      switch (orientation) {
        case 1: // Normal (0°)
          // Hiçbir şey yapma
          break;
        case 2: // Mirrored horizontal
          orientedImage = img.flipHorizontal(image);
          Logger.debug(
            '🖼️ ImageOptimizationService - Applied horizontal mirror',
          );
          break;
        case 3: // Rotated 180°
          orientedImage = img.copyRotate(image, angle: 180);
          Logger.debug('🖼️ ImageOptimizationService - Applied 180° rotation');
          break;
        case 4: // Mirrored vertical
          orientedImage = img.flipVertical(image);
          Logger.debug(
            '🖼️ ImageOptimizationService - Applied vertical mirror',
          );
          break;
        case 5: // Mirrored horizontal + rotated 90° CCW
          orientedImage = img.copyRotate(img.flipHorizontal(image), angle: 90);
          Logger.debug(
            '🖼️ ImageOptimizationService - Applied horizontal mirror + 90° CCW rotation',
          );
          break;
        case 6: // Rotated 90° CW
          orientedImage = img.copyRotate(image, angle: 90);
          Logger.debug(
            '🖼️ ImageOptimizationService - Applied 90° CW rotation',
          );
          break;
        case 7: // Mirrored horizontal + rotated 90° CW
          orientedImage = img.copyRotate(img.flipHorizontal(image), angle: 270);
          Logger.debug(
            '🖼️ ImageOptimizationService - Applied horizontal mirror + 90° CW rotation',
          );
          break;
        case 8: // Rotated 90° CCW
          orientedImage = img.copyRotate(image, angle: 270);
          Logger.debug(
            '🖼️ ImageOptimizationService - Applied 90° CCW rotation',
          );
          break;
        default:
          Logger.warning(
            '🖼️ ImageOptimizationService - Unknown orientation value: $orientation, keeping original',
          );
          return image;
      }

      return orientedImage;
    } catch (e) {
      Logger.error(
        '🖼️ ImageOptimizationService - Error applying orientation: $e',
      );
      return image;
    }
  }
}
