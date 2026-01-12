import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Utility for handling image paths in the database
/// Stores relative paths instead of absolute to prevent path breakage
class ImagePathHelper {
  static String? _appDirPath;

  /// Initialize with the app directory path
  /// Call this once during app startup
  static Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _appDirPath = appDir.path;
  }

  /// Get the app directory path (must call init first)
  static String get appDirPath {
    if (_appDirPath == null) {
      throw StateError('ImagePathHelper.init() must be called before using this class');
    }
    return _appDirPath!;
  }

  /// Convert absolute path to relative path for database storage
  /// Example: /data/user/0/com.app/files/images/product.jpg -> images/product.jpg
  static String toRelativePath(String absolutePath) {
    if (absolutePath.isEmpty) return '';
    
    // If already relative, return as-is
    if (!absolutePath.startsWith('/') && !absolutePath.contains(':\\')) {
      return absolutePath;
    }

    // Check if path contains app directory
    if (_appDirPath != null && absolutePath.startsWith(_appDirPath!)) {
      return absolutePath.substring(_appDirPath!.length + 1); // +1 for the separator
    }

    // Return just the filename if we can't determine relative path
    return p.basename(absolutePath);
  }

  /// Convert relative path to absolute path for file loading
  /// Example: images/product.jpg -> /data/user/0/com.app/files/images/product.jpg
  static String toAbsolutePath(String relativePath) {
    if (relativePath.isEmpty) return '';
    
    // If already absolute, return as-is
    if (relativePath.startsWith('/') || relativePath.contains(':\\')) {
      return relativePath;
    }

    if (_appDirPath == null) {
      throw StateError('ImagePathHelper.init() must be called before using this class');
    }

    return p.join(_appDirPath!, relativePath);
  }

  /// Check if an image file exists
  static bool exists(String path) {
    if (path.isEmpty) return false;
    
    final absolutePath = path.startsWith('/') || path.contains(':\\') 
        ? path 
        : toAbsolutePath(path);
    
    return File(absolutePath).existsSync();
  }

  /// Save image to app directory and return relative path
  static Future<String> saveImage(String tempPath) async {
    if (_appDirPath == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _appDirPath = appDir.path;
    }

    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imagesDir = Directory(p.join(_appDirPath!, 'images'));
    
    // Create images directory if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final savedPath = p.join(imagesDir.path, fileName);
    await File(tempPath).copy(savedPath);

    // Return relative path for database storage
    return p.join('images', fileName);
  }

  /// Get File object from path (handles both relative and absolute)
  static File getFile(String path) {
    final absolutePath = path.startsWith('/') || path.contains(':\\')
        ? path
        : toAbsolutePath(path);
    return File(absolutePath);
  }
}
