import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:takasly/utils/logger.dart';

/// Fotoğraf seçme ve düzenleme servisi
/// Galeriden veya kameradan fotoğraf seçer, kullanıcı istediğinde crop ekranında düzenleme yapar
class PickCropService {
  static final ImagePicker _picker = ImagePicker();

  /// Tekli fotoğraf seçme (düzenleme olmadan)
  /// [source] - Fotoğraf kaynağı (galeri veya kamera)
  /// [compressQuality] - Sıkıştırma kalitesi (0.0 - 1.0)
  /// Returns: Seçilen fotoğraf Uint8List olarak
  static Future<Uint8List?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
    int compressQuality = 85,
  }) async {
    try {
      Logger.debug('🖼️ PickCropService - Starting single image pick process');

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
      Logger.error(
        '🖼️ PickCropService - Error in single image pick process: $e',
      );
      return null;
    }
  }

  /// Çoklu fotoğraf seçme (düzenleme olmadan)
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

  /// Mevcut fotoğrafı düzenleme ekranında aç
  /// [imageBytes] - Düzenlenecek görsel bytes
  /// [aspectRatio] - Aspect ratio (null = serbest)
  /// Returns: Düzenlenmiş görsel Uint8List olarak
  static Future<Uint8List?> editExistingImage({
    required Uint8List imageBytes,
    double? aspectRatio,
  }) async {
    try {
      Logger.debug(
        '🖼️ PickCropService - Starting edit for existing image: ${imageBytes.length} bytes',
      );

      // Geçici dosya oluştur
      final Directory tempDir = Directory.systemTemp;
      final String tempFileName =
          'temp_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String tempFilePath = '${tempDir.path}/$tempFileName';

      final File tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(imageBytes);

      // Crop ekranını aç
      final CroppedFile? croppedFile = await _openCropScreen(
        tempFilePath,
        aspectRatio: aspectRatio,
      );

      // Geçici dosyayı temizle
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (croppedFile == null) {
        Logger.debug('🖼️ PickCropService - Edit cancelled');
        return null;
      }

      Logger.debug('🖼️ PickCropService - Image edited: ${croppedFile.path}');

      // Cropped dosya varlığını kontrol et
      final File croppedImageFile = File(croppedFile.path);
      if (!await croppedImageFile.exists()) {
        Logger.error(
          '🖼️ PickCropService - Cropped file does not exist: ${croppedFile.path}',
        );
        return null;
      }

      // Uint8List'e dönüştür
      final Uint8List editedBytes = await croppedFile.readAsBytes();
      Logger.debug(
        '🖼️ PickCropService - Edited image converted to bytes: ${editedBytes.length} bytes',
      );

      return editedBytes;
    } catch (e, stackTrace) {
      Logger.error(
        '🖼️ PickCropService - Error in edit existing image process: $e',
      );
      Logger.error('🖼️ PickCropService - Stack trace: $stackTrace');
      return null;
    }
  }

  /// Mevcut dosyayı düzenleme ekranında aç
  /// [imagePath] - Düzenlenecek görsel yolu
  /// [aspectRatio] - Aspect ratio
  /// Returns: Düzenlenmiş dosya
  static Future<CroppedFile?> editImageFromPath({
    required String imagePath,
    double? aspectRatio,
  }) async {
    try {
      Logger.debug(
        '🖼️ PickCropService - Starting edit for image from path: $imagePath',
      );

      // Dosya varlığını kontrol et
      final File originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        Logger.error(
          '🖼️ PickCropService - Source image file does not exist: $imagePath',
        );
        return null;
      }

      // Crop ekranını aç
      final CroppedFile? croppedFile = await _openCropScreen(
        imagePath,
        aspectRatio: aspectRatio,
      );

      if (croppedFile != null) {
        Logger.debug(
          '🖼️ PickCropService - Image edited from path: ${croppedFile.path}',
        );
        return croppedFile;
      }

      return null;
    } catch (e) {
      Logger.error('🖼️ PickCropService - Error editing image from path: $e');
      return null;
    }
  }

  /// Düzenleme ekranını açar
  /// [imagePath] - Düzenlenecek görsel yolu
  /// [aspectRatio] - Aspect ratio
  /// Returns: Düzenlenmiş dosya
  static Future<CroppedFile?> _openCropScreen(
    String imagePath, {
    double? aspectRatio,
  }) async {
    try {
      Logger.debug('🖼️ PickCropService - Opening edit screen for: $imagePath');

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
        return null;
      }

      if (croppedFile != null) {
        Logger.debug(
          '🖼️ PickCropService - Edit completed successfully: ${croppedFile.path}',
        );

        // Cropped dosya varlığını kontrol et
        final File croppedFileCheck = File(croppedFile.path);
        if (!await croppedFileCheck.exists()) {
          Logger.error(
            '🖼️ PickCropService - Cropped file does not exist after edit: ${croppedFile.path}',
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
          '🖼️ PickCropService - Edited file size: $croppedFileSize bytes',
        );
      } else {
        Logger.debug('🖼️ PickCropService - Edit cancelled by user');
      }

      return croppedFile;
    } catch (e, stackTrace) {
      Logger.error('🖼️ PickCropService - Error opening edit screen: $e');
      Logger.error('🖼️ PickCropService - Stack trace: $stackTrace');
      return null;
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
