import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/slideshow_repository.dart';
import 'package:sqflite/sqflite.dart';

final slideShowBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SlideshowModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final slideshowLocalRepoProvider = Provider<LocalSlideshowRepository>((ref) {
  return LocalSlideshowRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(slideShowBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSlideshowRepository] that uses local database
class LocalSlideshowRepositoryImpl implements LocalSlideshowRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'second_displays';
  static const String cId = 'id';
  static const String title = 'title';
  static const String outletId = 'outlet_id';
  static const String description = 'description';
  static const String greeting = 'greetings';
  static const String feedbackDescription = 'feedback_description';
  static const String images = 'images';
  static const String imageNames = 'image_names';
  static const String promotionLink = 'promotion_link';
  static const String downloadUrls = 'download_urls';
  static const String qrPaymentPath = 'qr_payment_path';
  static const String qrPaymentUrl = 'qr_payment_url';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalSlideshowRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the second display table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $title TEXT NULL,
      $outletId TEXT NULL,
      $description TEXT NULL,
      $greeting TEXT NULL,
      $feedbackDescription TEXT NULL,
      $promotionLink TEXT NULL,
      $qrPaymentPath TEXT NULL,
      $qrPaymentUrl TEXT NULL,
      $images TEXT NULL,
      $imageNames TEXT NULL,
      $downloadUrls TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new second display configuration
  @override
  Future<Map<String, dynamic>> insert(
    SlideshowModel sdModel, {
    required bool isInsertToPending,
  }) async {
    sdModel.id ??= IdUtils.generateUUID();
    sdModel.createdAt = DateTime.now();
    sdModel.updatedAt = DateTime.now();

    int success = await _dbHelper.insertDb(tableName, sdModel.toJson());

    if (success > 0) {
      await _hiveBox.put(sdModel.id, sdModel.toJson());

      return {
        DbResponseEnum.isSuccess: true,
        DbResponseEnum.message: 'Successfully inserted',
      };
    } else {
      return {
        DbResponseEnum.isSuccess: false,
        DbResponseEnum.message: 'Failed to insert',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getLatestModel() async {
    List<SlideshowModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SlideshowModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      list.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return {
        DbResponseEnum.isSuccess: true,
        DbResponseEnum.data: list.first,
        DbResponseEnum.message: null,
      };
    }

    Database db = await _dbHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
      tableName,
      orderBy: '$createdAt DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      return {
        DbResponseEnum.isSuccess: true,
        DbResponseEnum.data: SlideshowModel.fromJson(results.first),
        DbResponseEnum.message: null,
      };
    } else {
      return {
        DbResponseEnum.isSuccess: false,
        DbResponseEnum.message: 'No data found',
        DbResponseEnum.data: null,
      };
    }
  }

  /// Get list of all slideshows, checking Hive first for cached data
  Future<List<SlideshowModel>> getListSlideshowModel() async {
    List<SlideshowModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SlideshowModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return SlideshowModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> upsertBulk(
    List<SlideshowModel> secondDisplays, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert =
          secondDisplays.map((m) => m.id).whereType<String>().toList();

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

      for (SlideshowModel model in secondDisplays) {
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
                modelName: SlideshowModel.modelName,
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
                modelName: SlideshowModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive cache after successful batch commit
      await _hiveBox.putAll(
        Map.fromEntries(
          secondDisplays
              .where((m) => m.id != null)
              .map((m) => MapEntry(m.id!, m.toJson())),
        ),
      );
      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      if (isInsertToPending) {
        await Future.wait(
          pendingChanges.map(
            (pendingChange) => _pendingChangesRepository.insert(pendingChange),
          ),
        );
      }

      return true;
    } catch (e) {
      prints('Error inserting bulk second displays: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<SlideshowModel> secondDisplays, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      final List<PendingChangesModel> pendingChanges = [];

      for (SlideshowModel secondDisplay in secondDisplays) {
        // Insert to pending changes if required
        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'deleted',
              modelName: SlideshowModel.modelName,
              modelId: secondDisplay.id,
              data: jsonEncode(secondDisplay.toJson()),
            ),
          );
        }

        batch.delete(
          tableName,
          where: '$cId = ?',
          whereArgs: [secondDisplay.id],
        );

        // Sync deletions to Hive cache
        await _hiveBox.deleteAll(
          secondDisplays.where((m) => m.id != null).map((m) => m.id!).toList(),
        );
      }

      await batch.commit(noResult: true);

      if (isInsertToPending) {
        await Future.wait(
          pendingChanges.map(
            (pendingChange) => _pendingChangesRepository.insert(pendingChange),
          ),
        );
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk second displays: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all second displays: $e');
      return false;
    }
  }

  @override
  Future<int> update(
    SlideshowModel secondDisplay, {
    required bool isInsertToPending,
  }) async {
    secondDisplay.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, secondDisplay.toJson());

    await _hiveBox.put(secondDisplay.id, secondDisplay.toJson());

    return result;
  }

  @override
  Future<SlideshowModel> getModelById(String id) async {
    Database db = await _dbHelper.database;
    final list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SlideshowModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      final cached = list.where((element) => element.id == id).firstOrNull;
      if (cached != null) return cached;
    }

    final List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return SlideshowModel.fromJson(results.first);
    } else {
      return SlideshowModel();
    }
  }

  @override
  Future<bool> replaceAllData(
    List<SlideshowModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();

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

      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    Database db = await _dbHelper.database;
    int result = await db.delete(tableName, where: '$cId = ?', whereArgs: [id]);
    await _hiveBox.delete(id);
    return result;
  }
}
