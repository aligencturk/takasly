import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takasly/utils/logger.dart';

/// Görsel boyut kontrolü ve küçültme servisi
/// Galeri kapandıktan sonra seçilen görselleri otomatik olarak optimize eder
class ImageOptimizationService {
  
  /// Maksimum genişlik (px)
  static const int maxWidth = 1920;
  
  /// Maksimum yükseklik (px) 
  static const int maxHeight = 1920;
  
  /// JPEG kalitesi (0-100)
  static const int jpegQuality = 85;
  
  /// Maksimum dosya boyutu (bytes) - 2MB
  static const int maxFileSizeBytes = 2 * 1024 * 1024;

  /// Seçilen görsel dosyalarını optimize eder
  /// [imageFiles] - Optimize edilecek dosya listesi
  /// [maxImages] - Maksimum işlenecek görsel sayısı (varsayılan: 5)
  /// Returns: Optimize edilmiş File listesi
  static Future<List<File>> optimizeImages(
    List<File> imageFiles, {
    int maxImages = 5,
  }) async {
    try {
      Logger.debug('🖼️ ImageOptimizationService - Starting optimization for ${imageFiles.length} images');
      
      if (imageFiles.isEmpty) {
        Logger.warning('🖼️ ImageOptimizationService - No images to optimize');
        return [];
      }

      // Maksimum sayıyı aş
      List<File> filesToProcess = imageFiles.take(maxImages).toList();
      
      List<File> optimizedFiles = [];
      
      for (int i = 0; i < filesToProcess.length; i++) {
        final File originalFile = filesToProcess[i];
        Logger.debug('🖼️ ImageOptimizationService - Processing image ${i + 1}/${filesToProcess.length}: ${originalFile.path}');
        
        try {
          // Dosya boyutu kontrolü
          final int originalSize = await originalFile.length();
          Logger.debug('🖼️ ImageOptimizationService - Original file size: ${originalSize} bytes (${(originalSize / 1024).toStringAsFixed(1)} KB)');
          
          // Eğer dosya zaten uygun boyuttaysa ve küçükse, optimize etme
          if (originalSize <= maxFileSizeBytes / 2) {
            // Dosya boyutu 1MB'den küçükse, boyut kontrolü yap ama optimize etme
            final ui.Image? image = await _loadImageFromFile(originalFile);
            if (image != null) {
              if (image.width <= maxWidth && image.height <= maxHeight) {
                Logger.debug('🖼️ ImageOptimizationService - Image already optimized, skipping: ${originalFile.path}');
                optimizedFiles.add(originalFile);
                image.dispose();
                continue;
              }
              image.dispose();
            }
          }
          
          // Görsel optimizasyonu yap
          final File? optimizedFile = await _optimizeImage(originalFile);
          
          if (optimizedFile != null) {
            final int optimizedSize = await optimizedFile.length();
            Logger.debug('🖼️ ImageOptimizationService - Optimized file size: ${optimizedSize} bytes (${(optimizedSize / 1024).toStringAsFixed(1)} KB)');
            Logger.debug('🖼️ ImageOptimizationService - Size reduction: ${((originalSize - optimizedSize) / originalSize * 100).toStringAsFixed(1)}%');
            optimizedFiles.add(optimizedFile);
          } else {
            Logger.warning('🖼️ ImageOptimizationService - Failed to optimize, using original: ${originalFile.path}');
            optimizedFiles.add(originalFile);
          }
          
        } catch (e) {
          Logger.error('🖼️ ImageOptimizationService - Error processing image ${originalFile.path}: $e');
          // Hata durumunda orijinal dosyayı ekle
          optimizedFiles.add(originalFile);
        }
      }
      
      Logger.debug('🖼️ ImageOptimizationService - Optimization completed: ${optimizedFiles.length} images processed');
      return optimizedFiles;
      
    } catch (e) {
      Logger.error('🖼️ ImageOptimizationService - General optimization error: $e');
      // Hata durumunda orijinal dosyaları döndür
      return imageFiles.take(maxImages).toList();
    }
  }

  /// XFile listesini optimize eder ve File listesi döner
  /// [xFiles] - XFile listesi (ImagePicker'dan gelen)
  /// [maxImages] - Maksimum işlenecek görsel sayısı
  /// Returns: Optimize edilmiş File listesi
  static Future<List<File>> optimizeXFiles(
    List<XFile> xFiles, {
    int maxImages = 5,
  }) async {
    try {
      Logger.debug('🖼️ ImageOptimizationService - Converting ${xFiles.length} XFiles to Files for optimization');
      
      List<File> files = xFiles.take(maxImages).map((xFile) => File(xFile.path)).toList();
      return await optimizeImages(files, maxImages: maxImages);
      
    } catch (e) {
      Logger.error('🖼️ ImageOptimizationService - Error converting XFiles: $e');
      return xFiles.take(maxImages).map((xFile) => File(xFile.path)).toList();
    }
  }

  /// Tek bir XFile'ı optimize eder (profil fotoğrafı için)
  /// [xFile] - Optimize edilecek XFile
  /// Returns: Optimize edilmiş File
  static Future<File> optimizeSingleXFile(XFile xFile) async {
    try {
      Logger.debug('🖼️ ImageOptimizationService - Optimizing single image: ${xFile.path}');
      
      final List<File> optimizedFiles = await optimizeXFiles([xFile], maxImages: 1);
      
      if (optimizedFiles.isNotEmpty) {
        return optimizedFiles.first;
      } else {
        Logger.warning('🖼️ ImageOptimizationService - Failed to optimize single image, returning original');
        return File(xFile.path);
      }
      
    } catch (e) {
      Logger.error('🖼️ ImageOptimizationService - Error optimizing single image: $e');
      return File(xFile.path);
    }
  }

  /// Bir dosyadan ui.Image yükler
  static Future<ui.Image?> _loadImageFromFile(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      Logger.error('🖼️ ImageOptimizationService - Error loading image from file: $e');
      return null;
    }
  }

  /// Görsel dosyasını optimize eder
  static Future<File?> _optimizeImage(File originalFile) async {
    try {
      // Dosyayı byte array olarak oku
      final Uint8List bytes = await originalFile.readAsBytes();
      
      // ui.Image'e dönüştür
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Boyut hesaplama
      double scaleRatio = 1.0;
      
      if (image.width > maxWidth || image.height > maxHeight) {
        final double widthRatio = maxWidth / image.width;
        final double heightRatio = maxHeight / image.height;
        scaleRatio = widthRatio < heightRatio ? widthRatio : heightRatio;
      }
      
      final int newWidth = (image.width * scaleRatio).round();
      final int newHeight = (image.height * scaleRatio).round();
      
      Logger.debug('🖼️ ImageOptimizationService - Resizing from ${image.width}x${image.height} to ${newWidth}x${newHeight} (scale: ${scaleRatio.toStringAsFixed(2)})');
      
      // Canvas oluştur ve yeniden boyutlandır
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Rect srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final Rect dstRect = Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble());
      
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(newWidth, newHeight);
      
      // JPEG formatında encode et
      final ByteData? pngData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      
      // Memory cleanup
      image.dispose();
      resizedImage.dispose();
      picture.dispose();
      
      if (pngData == null) {
        Logger.error('🖼️ ImageOptimizationService - Failed to encode image data');
        return null;
      }
      
      // Temporary dosya oluştur
      final String originalPath = originalFile.path;
      final String directory = originalFile.parent.path;
      final String fileName = originalPath.split('/').last.split('.').first;
      final String optimizedPath = '$directory/${fileName}_optimized.jpg';
      
      final File optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(pngData.buffer.asUint8List());
      
      Logger.debug('🖼️ ImageOptimizationService - Image saved to: $optimizedPath');
      return optimizedFile;
      
    } catch (e) {
      Logger.error('🖼️ ImageOptimizationService - Error optimizing image: $e');
      return null;
    }
  }

  /// Dosya boyutu kontrolü yapar
  /// [file] - Kontrol edilecek dosya
  /// Returns: Dosya uygun boyutta mı?
  static Future<bool> isFileSizeAcceptable(File file) async {
    try {
      final int fileSize = await file.length();
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      Logger.error('🖼️ ImageOptimizationService - Error checking file size: $e');
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
}
