import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File utility functions
class FileUtils {
  /// Get application documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get temporary directory
  static Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Create a directory if it doesn't exist
  static Future<Directory> createDirectoryIfNotExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return await directory.create(recursive: true);
    }
    return directory;
  }

  /// Write string to file
  static Future<File> writeStringToFile(
    String path,
    String content, {
    FileMode mode = FileMode.write,
  }) async {
    final file = File(path);
    return await file.writeAsString(content, mode: mode);
  }

  /// Read string from file
  static Future<String> readStringFromFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  /// Delete file
  static Future<bool> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Check if file exists
  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Get file size
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Copy file
  static Future<File> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    final sourceFile = File(sourcePath);
    return await sourceFile.copy(destinationPath);
  }

  /// Move file
  static Future<File> moveFile(
    String sourcePath,
    String destinationPath,
  ) async {
    final sourceFile = File(sourcePath);
    return await sourceFile.rename(destinationPath);
  }

  /// Get file extension
  static String getFileExtension(String path) {
    return path.split('.').last;
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String path) {
    final fileName = path.split('/').last;
    return fileName.split('.').first;
  }

  /// Get file name with extension
  static String getFileName(String path) {
    return path.split('/').last;
  }
}
