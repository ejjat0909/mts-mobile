import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_downloaded_file_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/downloaded_file_repository.dart';
import 'package:mts/domain/repositories/local/item_representation_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Hive Box Provider
/// ================================
final itemRepresentationBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ItemRepresentationModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final itemRepresentationLocalRepoProvider =
    Provider<LocalItemRepresentationRepository>((ref) {
      return LocalItemRepresentationRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        downloadedFileRepository: ref.read(downloadedFileLocalRepoProvider),
        hiveBox: ref.read(itemRepresentationBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalItemRepresentationRepository] that uses local database
class LocalItemRepresentationRepositoryImpl
    implements LocalItemRepresentationRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final LocalDownloadedFileRepository _downloadedFileRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String color = 'color';
  static const String shape = 'shape';
  static const String imagePath = 'image_path';
  static const String imageName = 'image_name';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String useImage = 'use_image';
  static const String downloadUrl = 'download_url';
  static const String tableName = 'item_representations';

  /// Constructor
  LocalItemRepresentationRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required LocalDownloadedFileRepository downloadedFileRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _downloadedFileRepository = downloadedFileRepository,
       _hiveBox = hiveBox;

  /// Create the item representation table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $color TEXT NULL,
      $shape INTEGER NULL,
      $imagePath TEXT NULL,
      $imageName TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $useImage INTEGER DEFAULT 0,
      $downloadUrl TEXT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new item representation
  @override
  Future<int> insert(
    ItemRepresentationModel model, {
    required bool isInsertToPending,
  }) async {
    model.id ??= IdUtils.generateUUID().toString();
    model.updatedAt = DateTime.now();
    model.createdAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.insertDb(tableName, model.toJson());

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(model.id!, model.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: ItemRepresentationModel.modelName,
        modelId: model.id,
        data: jsonEncode(model.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // update
  @override
  Future<int> update(
    ItemRepresentationModel itemRepresentationModel, {
    required bool isInsertToPending,
  }) async {
    itemRepresentationModel.updatedAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.updateDb(
      tableName,
      itemRepresentationModel.toJson(),
    );

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(
        itemRepresentationModel.id!,
        itemRepresentationModel.toJson(),
      );
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ItemRepresentationModel.modelName,
        modelId: itemRepresentationModel.id,
        data: jsonEncode(itemRepresentationModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // delete
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
      final model = ItemRepresentationModel.fromJson(results.first);

      // Delete the record from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      if (result > 0) {
        await _hiveBox.delete(id);
      }

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ItemRepresentationModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No item representation record found with id: $id');
      return 0;
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<ItemRepresentationModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> ids = list.map((e) => e.id!).toList();

    if (ids.isEmpty) {
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (ItemRepresentationModel item in list) {
        List<Map<String, dynamic>> results = await db.query(
          tableName,
          where: '$cId = ?',
          whereArgs: [item.id],
        );

        if (results.isNotEmpty) {
          final model = ItemRepresentationModel.fromJson(results.first);

          // Insert to pending changes
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ItemRepresentationModel.modelName,
            modelId: model.id,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }
    }

    // loop ir to get the downloaded file model
    for (ItemRepresentationModel item in list) {
      // get downloaded file where modelId = model.id
      final listDfm = await _downloadedFileRepository
          .getDownloadedFilesByModelId(item.id!);
      if (listDfm.isNotEmpty) {
        await _downloadedFileRepository.deleteBulk(
          listDfm,
          isInsertToPending: false,
        );
        await _hiveBox.delete(item.id);
      }
    }

    String whereIn = ids.map((_) => '?').join(',');
    try {
      await db.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: ids);

      // Delete from Hive
      await _hiveBox.deleteAll(ids);

      return true;
    } catch (e) {
      prints('Error deleting bulk item representation: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all item representation: $e');
      return false;
    }
  }

  // getListItemRepresentation
  @override
  Future<List<ItemRepresentationModel>> getListItemRepresentationModel() async {
    List<ItemRepresentationModel> listIR = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ItemRepresentationModel.fromJson,
    );

    if (listIR.isNotEmpty) {
      return listIR;
    }

    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ItemRepresentationModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> upsertBulk(
    List<ItemRepresentationModel> listIR, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      final idsToInsert = listIR.map((m) => m.id).whereType<String>().toList();

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
      Batch batch = db.batch();

      for (ItemRepresentationModel model in listIR) {
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
                modelName: ItemRepresentationModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: ItemRepresentationModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }

        // Handle downloaded file
        // await insertFilesToDownloadedHive(model);
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listIR) {
        if (model.id != null) {
          hiveDataMap[model.id!] = model.toJson();
        }
      }
      if (hiveDataMap.isNotEmpty) {
        await _hiveBox.putAll(hiveDataMap);
      }

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk item representation: $e');
      return false;
    }
  }

  Future<void> insertFilesToDownloadedHive(
    ItemRepresentationModel model,
  ) async {
    if (model.downloadUrl != null && model.imagePath != null) {
      // get downloaded file by url and image path
      DownloadedFileModel dfm = await _downloadedFileRepository
          .getByImagePathAndUrl(
            imagePath: model.imagePath!,
            downloadUrl: model.downloadUrl!,
          );

      if (dfm.id == null) {
        // if tak jumpa
        // means url has updated or have new itemRepresentation
        DownloadedFileModel df = DownloadedFileModel(
          id: IdUtils.generateUUID(),
          fileName: model.imageName, // new
          url: model.downloadUrl, // new
          modelId: model.id, // depends
          nameModel: ItemRepresentationModel.modelName,
          isDownloaded: false,
          createdAt: model.updatedAt,
          updatedAt: model.updatedAt,
        );
        await _downloadedFileRepository.insert(df, isInsertToPending: false);
      }
    } else {
      // get downloaded file where modelId = model.id
      final listDfm = await _downloadedFileRepository
          .getDownloadedFilesByModelId(model.id!);
      if (listDfm.isNotEmpty) {
        await _downloadedFileRepository.deleteBulk(
          listDfm,
          isInsertToPending: false,
        );
      }
    }
  }

  @override
  Future<String?> getImagePathById(String idIR) async {
    List<ItemRepresentationModel> listIR = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ItemRepresentationModel.fromJson,
    );
    if (listIR.isNotEmpty) {
      return listIR.where((ir) => ir.id == idIR).firstOrNull?.imagePath;
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [imagePath],
      where: '$cId = ?',
      whereArgs: [idIR],
    );
    if (maps.isNotEmpty) {
      return maps[0][imagePath];
    }
    return null;
  }

  /// Streams the image path for the current ID
  // Future<void> streamImagePathById() async {
  //   if (_currentIdIR == null || _currentIdIR!.isEmpty) {
  //     prints("Error: Current ID is not set.");
  //     _imagePathStreamController.add(null);
  //     return;
  //   }

  //   try {
  //     Database db = await _dbHelper.database;
  //     final List<Map<String, dynamic>> maps = await db.query(
  //       tableName,
  //       columns: [imagePath],
  //       where: '$id = ?',
  //       whereArgs: [_currentIdIR],
  //     );

  //     if (maps.isNotEmpty) {
  //       final imagePathString = maps[0][imagePath];
  //       _imagePathStreamController.add(imagePathString);
  //     } else {
  //       prints("No image path found for ID: $_currentIdIR");
  //       _imagePathStreamController.add(null);
  //     }
  //   } catch (e) {
  //     prints("Error streaming image path for ID $_currentIdIR: $e");
  //     _imagePathStreamController.add(null);
  //   }
  // }

  // get list item representation not synced

  @override
  Future<bool> replaceAllData(
    List<ItemRepresentationModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);

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

      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }
}
