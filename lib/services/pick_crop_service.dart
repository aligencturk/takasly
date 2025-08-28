import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:takasly/utils/logger.dart';

/// Fotoğraf seçme ve düzenleme servisi
/// Galeriden veya kameradan fotoğraf seçer, crop ekranında düzenleme yapar
class PickCropService {
  static final ImagePicker _picker = ImagePicker();

  /// Fotoğraf seçme ve düzenleme işlemi
  /// [source] - Fotoğraf kaynağı (galeri veya kamera)
  /// [aspectRatio] - Crop ekranında kullanılacak aspect ratio (null = serbest)
  /// [compressQuality] - Sıkıştırma kalitesi (0.0 - 1.0)
  /// [initialImage] - Başlangıç olarak kullanılacak fotoğraf (opsiyonel)
  /// Returns: Düzenlenmiş fotoğraf Uint8List olarak
  static Future<Uint8List?> pickAndCropImage({
    ImageSource source = ImageSource.gallery,
    double? aspectRatio,
    int compressQuality = 85,
    File? initialImage,
  }) async {
    try {
      Logger.debug(
        '🖼️ PickCropService - Starting image pick and crop process',
      );

      // 1. Fotoğraf seç veya mevcut fotoğrafı kullan
      File imageFile;
      String imagePath;

      if (initialImage != null && await initialImage.exists()) {
        // Mevcut fotoğrafı kullan
        imageFile = initialImage;
        imagePath = initialImage.path;
        Logger.debug('🖼️ PickCropService - Using existing image: $imagePath');
      } else {
        // Yeni fotoğraf seç
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: compressQuality,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (pickedFile == null) {
          Logger.debug('🖼️ PickCropService - No image selected');
          return null;
        }

        Logger.debug(
          '🖼️ PickCropService - Image selected: ${pickedFile.path}',
        );
        imageFile = File(pickedFile.path);
        imagePath = pickedFile.path;
      }

      // Dosya varlığını kontrol et
      if (!await imageFile.exists()) {
        Logger.error(
          '🖼️ PickCropService - Image file does not exist: $imagePath',
        );
        return null;
      }

      // 2. Crop ekranını aç
      final CroppedFile? croppedFile = await _openCropScreen(
        imagePath,
        aspectRatio: aspectRatio,
      );

      if (croppedFile == null) {
        Logger.debug('🖼️ PickCropService - Crop cancelled');
        return null;
      }

      Logger.debug('🖼️ PickCropService - Image cropped: ${croppedFile.path}');

      // Cropped dosya varlığını kontrol et
      final File croppedImageFile = File(croppedFile.path);
      if (!await croppedImageFile.exists()) {
        Logger.error(
          '🖼️ PickCropService - Cropped file does not exist: ${croppedFile.path}',
        );
        return null;
      }

      // 3. Uint8List'e dönüştür
      final Uint8List imageBytes = await croppedFile.readAsBytes();
      Logger.debug(
        '🖼️ PickCropService - Image converted to bytes: ${imageBytes.length} bytes',
      );

      return imageBytes;
    } catch (e, stackTrace) {
      Logger.error('🖼️ PickCropService - Error in pick and crop process: $e');
      Logger.error('🖼️ PickCropService - Stack trace: $stackTrace');

      // Hata durumunda fallback: mevcut fotoğrafı veya yeni seçilen fotoğrafı döndür
      try {
        Logger.info(
          '🖼️ PickCropService - Attempting fallback: returning original image without crop',
        );

        if (initialImage != null && await initialImage.exists()) {
          // Mevcut fotoğrafı döndür
          final Uint8List fallbackBytes = await initialImage.readAsBytes();
          Logger.info(
            '🖼️ PickCropService - Fallback successful with existing image: ${fallbackBytes.length} bytes',
          );
          return fallbackBytes;
        } else {
          // Yeni fotoğraf seç
          final XFile? fallbackFile = await _picker.pickImage(
            source: source,
            imageQuality: compressQuality,
            maxWidth: 1920,
            maxHeight: 1920,
          );

          if (fallbackFile != null) {
            final Uint8List fallbackBytes = await fallbackFile.readAsBytes();
            Logger.info(
              '🖼️ PickCropService - Fallback successful with new image: ${fallbackBytes.length} bytes',
            );
            return fallbackBytes;
          }
        }
      } catch (fallbackError) {
        Logger.error(
          '🖼️ PickCropService - Fallback also failed: $fallbackError',
        );
      }

      return null;
    }
  }

  /// Sadece fotoğraf seçme (crop olmadan)
  /// [source] - Fotoğraf kaynağı
  /// [compressQuality] - Sıkıştırma kalitesi
  /// Returns: Seçilen fotoğraf Uint8List olarak
  static Future<Uint8List?> pickImageOnly({
    ImageSource source = ImageSource.gallery,
    int compressQuality = 85,
  }) async {
    try {
      Logger.debug('🖼️ PickCropService - Starting image pick only process');

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: compressQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        Logger.debug('🖼️ PickCropService - No image selected');
        return null;
      }

      Logger.debug('🖼️ PickCropService - Image selected: ${pickedFile.path}');

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      Logger.debug(
        '🖼️ PickCropService - Image converted to bytes: ${imageBytes.length} bytes',
      );

      return imageBytes;
    } catch (e) {
      Logger.error('🖼️ PickCropService - Error in pick image process: $e');
      return null;
    }
  }

  /// Mevcut dosyayı crop ekranında aç
  /// [imagePath] - Düzenlenecek görsel yolu
  /// [aspectRatio] - Aspect ratio
  /// Returns: Düzenlenmiş dosya
  static Future<CroppedFile?> cropExistingImage({
    required String imagePath,
    double? aspectRatio,
  }) async {
    try {
      Logger.debug(
        '🖼️ PickCropService - Starting crop for existing image: $imagePath',
      );

      final CroppedFile? croppedFile = await _openCropScreen(
        imagePath,
        aspectRatio: aspectRatio,
      );

      if (croppedFile == null) {
        Logger.debug('🖼️ PickCropService - Crop cancelled for existing image');
        return null;
      }

      Logger.debug(
        '🖼️ PickCropService - Existing image cropped: ${croppedFile.path}',
      );
      return croppedFile;
    } catch (e) {
      Logger.error('🖼️ PickCropService - Error cropping existing image: $e');
      return null;
    }
  }

  /// Crop ekranını açar
  /// [imagePath] - Düzenlenecek görsel yolu
  /// [aspectRatio] - Aspect ratio
  /// Returns: Düzenlenmiş dosya
  static Future<CroppedFile?> _openCropScreen(
    String imagePath, {
    double? aspectRatio,
  }) async {
    try {
      Logger.debug('🖼️ PickCropService - Opening crop screen for: $imagePath');

      // Dosya varlığını kontrol et
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        Logger.error(
          '🖼️ PickCropService - Source image file does not exist: $imagePath',
        );
        return null;
      }

      // Dosya boyutunu kontrol et
      final int fileSize = await imageFile.length();
      if (fileSize == 0) {
        Logger.error(
          '🖼️ PickCropService - Source image file is empty: $imagePath',
        );
        return null;
      }

      Logger.debug('🖼️ PickCropService - Source image size: $fileSize bytes');

      // ImageCropper'ı güvenli bir şekilde çağır
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: imagePath,
          aspectRatio: aspectRatio != null
              ? CropAspectRatio(ratioX: aspectRatio, ratioY: 1.0)
              : null,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Fotoğrafı Düzenle',
              toolbarColor: const Color(0xFF10B981),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: aspectRatio != null
                  ? CropAspectRatioPreset.square
                  : CropAspectRatioPreset.original,
              lockAspectRatio: aspectRatio != null,
              hideBottomControls: false,
              cropFrameColor: const Color(0xFF10B981),
              cropGridColor: const Color(0xFF10B981),
              cropGridColumnCount: 3,
              cropGridRowCount: 3,
              statusBarColor: const Color(0xFF10B981),
              backgroundColor: Colors.black,
              showCropGrid: true,
            ),
            IOSUiSettings(
              title: 'Fotoğrafı Düzenle',
              aspectRatioLockEnabled: aspectRatio != null,
              aspectRatioPickerButtonHidden: aspectRatio != null,
              rotateButtonsHidden: false,
              rotateClockwiseButtonHidden: false,
              doneButtonTitle: 'Uygula',
              cancelButtonTitle: 'İptal',
              hidesNavigationBar: false,
              minimumAspectRatio: 1.0,
            ),
          ],
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } catch (cropError) {
        Logger.error(
          '🖼️ PickCropService - ImageCropper.cropImage failed: $cropError',
        );
        // Crop hatası durumunda null döndür, ana metod fallback'i deneyecek
        return null;
      }

      if (croppedFile != null) {
        Logger.debug(
          '🖼️ PickCropService - Crop completed successfully: ${croppedFile.path}',
        );

        // Cropped dosya varlığını kontrol et
        final File croppedFileCheck = File(croppedFile.path);
        if (!await croppedFileCheck.exists()) {
          Logger.error(
            '🖼️ PickCropService - Cropped file does not exist after crop: ${croppedFile.path}',
          );
          return null;
        }

        final int croppedFileSize = await croppedFileCheck.length();
        if (croppedFileSize == 0) {
          Logger.error(
            '🖼️ PickCropService - Cropped file is empty: ${croppedFile.path}',
          );
          return null;
        }

        Logger.debug(
          '🖼️ PickCropService - Cropped file size: $croppedFileSize bytes',
        );
      } else {
        Logger.debug('🖼️ PickCropService - Crop cancelled by user');
      }

      return croppedFile;
    } catch (e, stackTrace) {
      Logger.error('🖼️ PickCropService - Error opening crop screen: $e');
      Logger.error('🖼️ PickCropService - Stack trace: $stackTrace');
      return null;
    }
  }

  /// Birden fazla fotoğraf seçme (crop olmadan)
  /// [maxImages] - Maksimum seçilebilecek fotoğraf sayısı
  /// [compressQuality] - Sıkıştırma kalitesi
  /// Returns: Seçilen fotoğraflar Uint8List listesi olarak
  static Future<List<Uint8List>> pickMultipleImages({
    int maxImages = 5,
    int compressQuality = 85,
  }) async {
    try {
      Logger.debug(
        '🖼️ PickCropService - Starting multiple image pick process',
      );

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: compressQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFiles.isEmpty) {
        Logger.debug('🖼️ PickCropService - No images selected');
        return [];
      }

      Logger.debug(
        '🖼️ PickCropService - ${pickedFiles.length} images selected',
      );

      final List<Uint8List> imageBytesList = [];

      for (int i = 0; i < pickedFiles.length && i < maxImages; i++) {
        try {
          final Uint8List imageBytes = await pickedFiles[i].readAsBytes();
          imageBytesList.add(imageBytes);
          Logger.debug(
            '🖼️ PickCropService - Image ${i + 1} converted: ${imageBytes.length} bytes',
          );
        } catch (e) {
          Logger.error(
            '🖼️ PickCropService - Error converting image ${i + 1}: $e',
          );
        }
      }

      Logger.debug(
        '🖼️ PickCropService - Multiple images processed: ${imageBytesList.length} images',
      );
      return imageBytesList;
    } catch (e) {
      Logger.error(
        '🖼️ PickCropService - Error in multiple image pick process: $e',
      );
      return [];
    }
  }

  /// Fotoğraf boyutunu kontrol et
  /// [imageBytes] - Kontrol edilecek fotoğraf
  /// [maxSizeMB] - Maksimum boyut (MB)
  /// Returns: Boyut uygun mu?
  static bool isImageSizeAcceptable(
    Uint8List imageBytes, {
    double maxSizeMB = 10.0,
  }) {
    final double sizeInMB = imageBytes.length / (1024 * 1024);
    final bool isAcceptable = sizeInMB <= maxSizeMB;

    Logger.debug(
      '🖼️ PickCropService - Image size: ${sizeInMB.toStringAsFixed(2)} MB, Acceptable: $isAcceptable',
    );

    return isAcceptable;
  }

  /// Fotoğraf boyutunu human-readable format'ta döner
  static String formatImageSize(Uint8List imageBytes) {
    final int bytes = imageBytes.length;
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
