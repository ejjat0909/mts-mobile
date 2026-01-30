import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/adapters/hive_cache_store.dart';
import 'package:mts/core/adapters/repository_pending_changes_tracker.dart';
import 'package:mts/core/adapters/sqflite_database_adapter.dart';
import 'package:mts/core/services/crud_config.dart';
import 'package:mts/core/services/repository_crud_service.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_repository_impl.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/domain/repositories/local/category_discount_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/discount_repository.dart';
import 'package:sqflite/sqflite.dart';

final categoryDiscountBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CategoryDiscountModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final categoryDiscountLocalRepoProvider =
    Provider<LocalCategoryDiscountRepository>((ref) {
      return LocalCategoryDiscountRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        localDiscountRepository: ref.read(discountLocalRepoProvider),
        hiveBox: ref.read(categoryDiscountBoxProvider),
        crudService: ref.read(repositoryCrudServiceProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalCategoryDiscountRepository] that uses local database
class LocalCategoryDiscountRepositoryImpl
    implements LocalCategoryDiscountRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalDiscountRepository _localDiscountRepository;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final RepositoryCrudService _crudService;
  PivotCrudConfig<CategoryDiscountModel>? _config;

  /// Database table and column names
  static const String categoryId = 'category_id';
  static const String discountId = 'discount_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'category_discount';

  // Discount table constants
  static const String discountTableName = 'discounts';

  /// Constructor
  LocalCategoryDiscountRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required LocalDiscountRepository localDiscountRepository,
    required Box<Map> hiveBox,
    required RepositoryCrudService crudService,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _localDiscountRepository = localDiscountRepository,
       _hiveBox = hiveBox,
       _crudService = crudService;

  Future<PivotCrudConfig<CategoryDiscountModel>> _getConfig() async {
    if (_config == null) {
      final db = await _dbHelper.database;
      _config = PivotCrudConfig<CategoryDiscountModel>(
        db: SqfliteDatabaseAdapter(db),
        cache: HiveCacheStore(_hiveBox),
        pendingChangesTracker: RepositoryPendingChangesTracker(
          _pendingChangesRepository,
        ),
        tableName: tableName,
        modelName: CategoryDiscountModel.modelName,
        updatedAtColumn: updatedAt,
        getCompositeKey: (model) => '${model.categoryId}_${model.discountId}',
        getKeyColumns:
            (model) => {
              categoryId: model.categoryId,
              discountId: model.discountId,
            },
        toJson: (model) => model.toJson(),
        fromJson: CategoryDiscountModel.fromJson,
        setTimestamps: (model) {
          model.createdAt ??= DateTime.now();
          model.updatedAt = DateTime.now();
        },
      );
    }
    return _config!;
  }

  // ==================== CRUD Operations ====================

  /// Create the category discount table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $categoryId TEXT NULL,
      $discountId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert or update a category discount
  /// If the category discount exists (based on categoryId and discountId), it will be updated
  /// If the category discount doesn't exist, it will be inserted
  @override
  Future<int> upsert(
    CategoryDiscountModel categoryDiscountModel, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.upsertPivot(
      config.copyWith(trackPendingChanges: isInsertToPending),
      categoryDiscountModel,
    );
  }

  @override
  Future<bool> upsertBulk(
    List<CategoryDiscountModel> list, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.upsertBulkPivot(
      config.copyWith(trackPendingChanges: isInsertToPending),
      list,
    );
  }

  @override
  Future<int> deletePivot(
    CategoryDiscountModel categoryDiscountModel, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.deletePivot(
      config.copyWith(trackPendingChanges: isInsertToPending),
      '${categoryDiscountModel.categoryId}_${categoryDiscountModel.discountId}',
      {
        categoryId: categoryDiscountModel.categoryId,
        discountId: categoryDiscountModel.discountId,
      },
    );
  }

  @override
  Future<bool> deleteBulk(
    List<CategoryDiscountModel> listCategoryDiscount, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.deleteBulkPivot(
      config.copyWith(trackPendingChanges: isInsertToPending),
      listCategoryDiscount,
    );
  }

  @override
  Future<bool> deleteAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all category discounts', e);
      return false;
    }
  }

  @override
  Future<List<CategoryDiscountModel>> getListCategoryDiscount() async {
    final config = await _getConfig();
    return await _crudService.getListPivot(config);
  }

  @override
  Future<List<DiscountModel>> getDiscountModelsByCategoryId(
    String idCategory,
  ) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$categoryId = ?',
      whereArgs: [idCategory],
    );

    // Extract discount IDs from the result
    List<String> discountIds =
        maps.map((map) => map['discount_id'] as String).toList();

    return await _localDiscountRepository.getDiscountModelsByDiscountIds(
      discountIds,
    );
  }

  @override
  Future<bool> replaceAllData(
    List<CategoryDiscountModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data from SQLite
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Step 2: Clear Hive
      await _hiveBox.clear();

      // Step 3: Insert new data using existing insertBulk method
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          await LogUtils.error(
            'Failed to insert bulk data in $tableName',
            null,
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error replacing all data in $tableName', e);
      return false;
    }
  }

  // ==================== Other Operations ====================

  @override
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.deleteByColumnName(
      config.copyWith(trackPendingChanges: isInsertToPending),
      columnName,
      value,
    );
  }
}
