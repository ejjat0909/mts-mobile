import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_downloaded_file_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/domain/repositories/local/downloaded_file_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/receipt_settings_repository.dart';
import 'package:sqflite/sqflite.dart';

final receiptSettingsBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ReceiptSettingsModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final receiptSettingsLocalRepoProvider =
    Provider<LocalReceiptSettingsRepository>((ref) {
      return LocalReceiptSettingsRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(receiptSettingsBoxProvider),
        downloadedFileRepository: ref.read(downloadedFileLocalRepoProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalReceiptSettingsRepository] that uses local database
class LocalReceiptSettingsRepositoryImpl
    implements LocalReceiptSettingsRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalDownloadedFileRepository _downloadedFileRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String outletId = 'outlet_id';
  static const String emailedLogo = 'emailed_logo';
  static const String printedLogo = 'printed_logo';
  static const String emailLogoUrl = 'email_logo_url';
  static const String printLogoUrl = 'print_logo_url';
  static const String emailedLogoName = 'emailed_logo_name';
  static const String printedLogoName = 'printed_logo_name';
  static const String header = 'header';
  static const String footer = 'footer';
  static const String companyName = 'company_name';
  static const String outletName = 'outlet_name';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'receipt_settings';

  /// Constructor
  LocalReceiptSettingsRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalDownloadedFileRepository downloadedFileRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _downloadedFileRepository = downloadedFileRepository;

  /// Create the receipt settings table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $outletId TEXT NULL,
      $emailedLogoName TEXT NULL,
      $printedLogoName TEXT NULL,
      $emailedLogo TEXT NULL,
      $printedLogo TEXT NULL,
      $emailLogoUrl TEXT NULL,
      $printLogoUrl TEXT NULL,
      $header TEXT NULL,
      $footer TEXT NULL,
      $companyName TEXT NULL,
      $outletName TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new receipt setting
  @override
  Future<int> insert(
    ReceiptSettingsModel receiptSettingModel, {
    required bool isInsertToPending,
  }) async {
    receiptSettingModel.id ??= IdUtils.generateUUID().toString();
    receiptSettingModel.updatedAt = DateTime.now();
    receiptSettingModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(
      tableName,
      receiptSettingModel.toJson(),
    );

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: ReceiptSettingsModel.modelName,
        modelId: receiptSettingModel.id!,
        data: jsonEncode(receiptSettingModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(receiptSettingModel.id, receiptSettingModel.toJson());
    }

    return result;
  }

  /// Update an existing receipt setting
  @override
  Future<int> update(
    ReceiptSettingsModel receiptSettingModel, {
    required bool isInsertToPending,
  }) async {
    int result = await _dbHelper.updateDb(
      tableName,
      receiptSettingModel.toJson(),
    );

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ReceiptSettingsModel.modelName,
        modelId: receiptSettingModel.id!,
        data: jsonEncode(receiptSettingModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(receiptSettingModel.id, receiptSettingModel.toJson());
    }

    return result;
  }

  /// Delete a receipt setting by ID
  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = ReceiptSettingsModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ReceiptSettingsModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No receipt settings record found with id: $id');
      return 0;
    }
  }

  /// Delete multiple receipt settings
  @override
  Future<bool> deleteBulk(
    List<ReceiptSettingsModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> ids = list.map((e) => e.id!).toList();
    if (ids.isEmpty) {
      return false;
    }

    try {
      // Insert to pending changes if required
      if (isInsertToPending) {
        for (ReceiptSettingsModel model in list) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ReceiptSettingsModel.modelName,
            modelId: model.id!,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }
      // loop rsm to get the downloaded file model
      for (ReceiptSettingsModel item in list) {
        // get downloaded file where modelId = model.id
        final listDfm = await _downloadedFileRepository
            .getDownloadedFilesByModelId(item.id!);
        if (listDfm.isNotEmpty) {
          await _downloadedFileRepository.deleteBulk(
            listDfm,
            isInsertToPending: false,
          );
          List<String> ids = listDfm.map((e) => e.id!).toList();
          await _hiveBox.deleteAll(ids);
        }
      }
      String whereIn = ids.map((_) => '?').join(',');
      await Future.wait([
        _hiveBox.deleteAll(ids),
        db.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: ids),
      ]);

      return true;
    } catch (e) {
      prints('Error deleting bulk receipt settings: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      // Get all receipt settings before deleting them

      await Future.wait([_hiveBox.clear(), db.delete(tableName)]);

      return true;
    } catch (e) {
      prints('Error deleting all receipt settings: $e');
      return false;
    }
  }

  // get list receipt settings
  @override
  Future<List<ReceiptSettingsModel>> getListReceiptSettings() async {
    List<ReceiptSettingsModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ReceiptSettingsModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ReceiptSettingsModel.fromJson(maps[index]);
    });
  }

  /// Insert multiple receipt settings
  @override
  Future<bool> upsertBulk(
    List<ReceiptSettingsModel> listRSM, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert = listRSM.map((m) => m.id).whereType<String>().toList();

      final existingIds = <String>{};
      if (idsToInsert.isNotEmpty) {
        final placeholders = List.filled(idsToInsert.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$cId IN ($placeholders)',
          whereArgs: idsToInsert,
          columns: [cId],
        );
        existingIds.addAll(existingRecords.map((r) => r[cId] as String));
      }

      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      // Key: Only ONE pre-flight check before batch, not per-item checks
      Batch batch = db.batch();

      for (ReceiptSettingsModel model in listRSM) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: ReceiptSettingsModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          // If two workers race here, one succeeds, the other is silently ignored
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: ReceiptSettingsModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }

        // insert to downloaded file model
        // for email logo
        //await insertFilesToDownloadedHive(model);
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive cache after successful batch commit
      await _hiveBox.putAll(
        Map.fromEntries(
          listRSM
              .where((m) => m.id != null)
              .map((m) => MapEntry(m.id!, m.toJson())),
        ),
      );
      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk receipt settings: $e');
      return false;
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<ReceiptSettingsModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();

      // Step 2: Insert new data using existing insertBulk method
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          prints('Failed to insert bulk data in $tableName');
          return false;
        }
      }

      // Note: Pending changes for insertion are handled by insertBulk method
      // when isInsertToPending is true
      // Note: Downloaded files for logos are also handled by insertBulk method

      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }

  /// Refresh Hive box with new receipt settings, deleting settings not in the new list

  /// Upsert multiple receipt settings to Hive box, merging with existing data
  ///
  /// Unlike [refreshBulkHiveBox], this preserves settings not in the new list.
  /// - Inserts new settings
  /// - Updates existing settings
  /// - **Keeps existing settings NOT in the list** (upsert behavior)
  ///
}
