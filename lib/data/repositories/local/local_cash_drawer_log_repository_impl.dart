import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/adapters/hive_cache_store.dart';
import 'package:mts/core/adapters/repository_pending_changes_tracker.dart';
import 'package:mts/core/adapters/sqflite_database_adapter.dart';
import 'package:mts/core/services/crud_config.dart';
import 'package:mts/core/services/repository_crud_service.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/cash_drawer_log/cash_drawer_log_model.dart';
import 'package:mts/domain/repositories/local/cash_drawer_log_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final cashDrawerLogBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CashDrawerLogModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final cashDrawerLogLocalRepoProvider = Provider<CashDrawerLogRepository>((ref) {
  return LocalCashDrawerLogRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(cashDrawerLogBoxProvider),
    crudService: ref.read(repositoryCrudServiceProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
class LocalCashDrawerLogRepositoryImpl implements CashDrawerLogRepository {
  /// Database table and column names
  static const String cId = 'id';
  static const String cStaffName = 'staff_name';
  static const String cActivity = 'activity';
  static const String cCompanyId = 'company_id';
  static const String cShiftId = 'shift_id';
  static const String cPosDeviceName = 'pos_device_name';
  static const String cPosDeviceId = 'pos_device_id';
  static const String cShiftStartAt = 'shift_start_at';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String tableName = 'cash_drawer_logs';

  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final RepositoryCrudService _crudService;
  CrudConfig<CashDrawerLogModel>? _config;

  LocalCashDrawerLogRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required RepositoryCrudService crudService,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _crudService = crudService;

  Future<CrudConfig<CashDrawerLogModel>> _getConfig() async {
    if (_config == null) {
      final db = await _dbHelper.database;
      _config = CrudConfig<CashDrawerLogModel>(
        db: SqfliteDatabaseAdapter(db),
        cache: HiveCacheStore(_hiveBox),
        pendingChangesTracker: RepositoryPendingChangesTracker(
          _pendingChangesRepository,
        ),
        tableName: tableName,
        modelName: CashDrawerLogModel.modelName,
        idColumn: cId,
        updatedAtColumn: cUpdatedAt,
        getId: (model) => model.id,
        setId: (model, id) => model.id = id,
        toJson: (model) => model.toJson(),
        fromJson: CashDrawerLogModel.fromJson,
        setTimestamps: (model) {
          model.createdAt = DateTime.now();
          model.updatedAt = DateTime.now();
        },
        updateTimestamp: (model) => model.updatedAt = DateTime.now(),
      );
    }
    return _config!;
  }

  // ==================== CRUD Operations ====================

  /// Create the table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cStaffName TEXT NULL,
      $cActivity TEXT NULL,
      $cCompanyId TEXT NULL,
      $cShiftId TEXT NULL,
      $cPosDeviceName TEXT NULL,
      $cPosDeviceId TEXT NULL,
      $cShiftStartAt TIMESTAMP DEFAULT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    CashDrawerLogModel model, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.insert(
      config.copyWith(trackPendingChanges: isInsertToPending),
      model,
    );
  }

  @override
  Future<int> update(
    CashDrawerLogModel model, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.update(
      config.copyWith(trackPendingChanges: isInsertToPending),
      model,
    );
  }

  @override
  Future<int> upsert(
    CashDrawerLogModel model, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.upsert(
      config.copyWith(trackPendingChanges: isInsertToPending),
      model,
    );
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    final config = await _getConfig();
    return await _crudService.delete(
      config.copyWith(trackPendingChanges: isInsertToPending),
      id,
    );
  }

  @override
  Future<bool> upsertBulk(
    List<CashDrawerLogModel> list, {
    required bool isInsertToPending,
  }) async {
    final config = await _getConfig();
    return await _crudService.upsertBulk(
      config.copyWith(trackPendingChanges: isInsertToPending),
      list,
    );
  }

  @override
  Future<bool> replaceAllData(
    List<CashDrawerLogModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all cash drawer logs', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  @override
  Future<List<CashDrawerLogModel>> getListCashDrawerLogs() async {
    final config = await _getConfig();
    return await _crudService.getList(config);
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<CashDrawerLogModel?> getById(String id) async {
    final config = await _getConfig();
    return await _crudService.getById(config, id);
  }

  // ==================== Delete Operations ====================

  @override
  Future<bool> deleteAll() async {
    final config = await _getConfig();
    return await _crudService.deleteAll(config);
  }
}
