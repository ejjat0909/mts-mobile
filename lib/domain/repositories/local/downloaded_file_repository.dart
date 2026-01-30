import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';

abstract class LocalDownloadedFileRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single downloaded file record
  Future<int> insert(
    DownloadedFileModel downloadedFileModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing downloaded file record
  Future<int> update(
    DownloadedFileModel downloadedFileModel, {
    required bool isInsertToPending,
  });

  /// Deletes a downloaded file record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple downloaded file records at once
  Future<bool> upsertBulk(
    List<DownloadedFileModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple downloaded file records at once
  Future<bool> deleteBulk(
    List<DownloadedFileModel> list, {
    required bool isInsertToPending,
  });

  // ==================== Query Operations ====================

  /// Retrieves all downloaded file records
  Future<List<DownloadedFileModel>> getListDownloadedFile();

  /// Retrieves a downloaded file by URL
  Future<DownloadedFileModel?> getDownloadedFileByUrl(String url);

  /// Retrieves downloaded files by model ID
  Future<List<DownloadedFileModel>> getDownloadedFilesByModelId(String modelId);

  /// Retrieves the printed logo path
  Future<DownloadedFileModel> getPrintedLogoPath();

  /// Retrieves by image path and URL
  Future<DownloadedFileModel> getByImagePathAndUrl({
    required String imagePath,
    required String downloadUrl,
  });
}
