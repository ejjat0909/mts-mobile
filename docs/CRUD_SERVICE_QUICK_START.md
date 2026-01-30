# Quick Start: Using Refactored CRUD Service

## ✅ What's New

**100% Clean Architecture** - All old methods removed! The service now uses:

- **Abstraction interfaces** (ICacheStore, IDatabaseAdapter, IPendingChangesTracker)
- **Configuration objects** (CrudConfig, PivotCrudConfig)
- **84% fewer parameters** - From 13 to 2 parameters
- **HiveCacheStore** - Thin wrapper around HiveSyncHelper for interface abstraction

### Why HiveCacheStore?

You might ask: "Why not just use HiveSyncHelper directly?"

**Answer**: `HiveCacheStore` provides an **interface** (`ICacheStore`) so your code doesn't depend on Hive directly. This means:

- ✅ **Testable** - Mock the cache in tests
- ✅ **Swappable** - Can replace Hive with Redis, SharedPreferences, etc.
- ✅ **Clean Architecture** - Depend on abstractions, not concretions

`HiveSyncHelper` is great but it's a concrete Hive utility. `HiveCacheStore` wraps it to provide the abstraction layer.

````dart
// Create config once in constructor
final config = CrudConfig<ProductModel>(
  db: SqfliteDatabaseAdapter(_db),
  cache: HiveCacheStore(_hiveBox),
  pendingChangesTracker: RepositoryPendingChangesTracker(_pendingChangesRepo),
  tableName: 'products',
  modelName: 'Product',
  getId: (m) => m.id,
  setId: (m, id) => m.id = id,
  toJson: (m) => m.toJson(),
  fromJson: ProductModel.fromJson,
  setTimestamps: (m) {
    m.createdAt ??= DateTime.now();
    m.updatedAt = DateTime.now();
  },
  updateTimestamp: (m) => m.updatedAt = DateTime.now(),
);

## 🚀 Basic Usage

### Regular Tables (CrudConfig)

```dart
// Create config once in constructor
final config = CrudConfig<ProductModel>(
  db: SqfliteDatabaseAdapter(_db),
  cache: HiveCacheStore(_hiveBox),
  pendingChangesTracker: RepositoryPendingChangesTracker(_pendingChangesRepo),
  tableName: 'products',
  modelName: 'Product',
  getId: (m) => m.id,
  setId: (m, id) => m.id = id,
  toJson: (m) => m.toJson(),
  fromJson: ProductModel.fromJson,
  setTimestamps: (m) {
    m.createdAt ??= DateTime.now();
    m.updatedAt = DateTime.now();
  },
  updateTimestamp: (m) => m.updatedAt = DateTime.now(),
);

// Use config for all operations (2 parameters!)
await _crudService.insert(config, product);
await _crudService.update(config, product);
await _crudService.upsert(config, product);
await _crudService.delete(config, productId);
await _crudService.deleteBulk(config, products);
await _crudService.deleteAll(config);

final product = await _crudService.getById(config, productId);
final products = await _crudService.getList(config);
````

### Pivot Tables (PivotCrudConfig)

```dart
// Create pivot config once
final pivotConfig = PivotCrudConfig<SaleItemModel>(
  db: SqfliteDatabaseAdapter(_db),
  cache: HiveCacheStore(_hiveBox),
  pendingChangesTracker: RepositoryPendingChangesTracker(_pendingChangesRepo),
  tableName: 'sale_items',
  modelName: 'SaleItem',
  getCompositeKey: (m) => '${m.saleId}_${m.productId}',
  getKeyColumns: (m) => {'sale_id': m.saleId, 'product_id': m.productId},
  toJson: (m) => m.toJson(),
  fromJson: SaleItemModel.fromJson,
  setTimestamps: (m) {
    m.createdAt ??= DateTime.now();
    m.updatedAt = DateTime.now();
  },
);

// Use for all pivot operations (2-3 parameters!)
await _crudService.upsertPivot(pivotConfig, saleItem);
await _crudService.deletePivot(pivotConfig, compositeKey, keyColumns);
await _crudService.deleteBulkPivot(pivotConfig, saleItems);
await _crudService.deleteByColumnName(pivotConfig, 'sale_id', saleId);

final item = await _crudService.getByIdPivot(pivotConfig, compositeKey, pivotElements);
final items = await _crudService.getListPivot(pivotConfig);
```

## � Complete Repository Example

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/adapters/hive_cache_store.dart';
import 'package:mts/core/adapters/repository_pending_changes_tracker.dart';
import 'package:mts/core/adapters/sqflite_database_adapter.dart';
import 'package:mts/core/services/crud_config.dart';
import 'package:mts/core/services/repository_crud_service.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';

class ProductLocalRepository {
  final RepositoryCrudService _crudService;
  final Database _db;
  final Box<Map> _hiveBox;
  final LocalPendingChangesRepository _pendingChangesRepo;

  late final CrudConfig<ProductModel> _config;

  ProductLocalRepository(
    this._crudService,
    this._db,
    this._hiveBox,
    this._pendingChangesRepo,
  ) {
    // Initialize config once - reuse for all operations
    _config = CrudConfig<ProductModel>(
      db: SqfliteDatabaseAdapter(_db),
      cache: HiveCacheStore(_hiveBox),
      pendingChangesTracker: RepositoryPendingChangesTracker(_pendingChangesRepo),
      tableName: 'products',
      modelName: 'Product',
      getId: (m) => m.id,
      setId: (m, id) => m.id = id,
      toJson: (m) => m.toJson(),
      fromJson: ProductModel.fromJson,
      setTimestamps: (m) {
        m.createdAt ??= DateTime.now();
        m.updatedAt = DateTime.now();
      },
      updateTimestamp: (m) => m.updatedAt = DateTime.now(),
    );
  }

  // Clean, simple method signatures!
  Future<void> insert(ProductModel product) =>
    _crudService.insert(_config, product);

  Future<void> update(ProductModel product) =>
    _crudService.update(_config, product);

  Future<void> upsert(ProductModel product) =>
    _crudService.upsert(_config, product);

  Future<void> deleteById(String id) =>
    _crudService.delete(_config, id);

  Future<void> deleteBulk(List<ProductModel> products) =>
    _crudService.deleteBulk(_config, products);

  Future<void> deleteAll() =>
    _crudService.deleteAll(_config);

  Future<List<ProductModel>> getAll() =>
    _crudService.getList(_config);

  Future<ProductModel?> getById(String id) =>
    _crudService.getById(_config, id);
}
```

## ⚙️ Optional Features

### Without Cache or Pending Changes

```dart
_config = CrudConfig<ProductModel>(
  db: SqfliteDatabaseAdapter(_db),
  cache: null, // No caching
  pendingChangesTracker: null, // No pending changes tracking
  trackPendingChanges: false,
  // ... rest of config
);
```

### Custom Column Names

```dart
_config = CrudConfig<ProductModel>(
  // ...
  idColumn: 'product_id', // Default: 'id'
  updatedAtColumn: 'last_modified', // Default: 'updated_at'
);
```

## 🎯 Benefits

✅ **100% Clean Architecture** - All methods use abstractions  
✅ **84% fewer parameters** (from 13 to 2)  
✅ **Transaction safety** - cache operations outside DB transactions  
✅ **Testable** - mock interfaces easily (ICacheStore, IDatabaseAdapter)  
✅ **Reusable config** - create once, use everywhere  
✅ **Type-safe** - compile-time errors  
✅ **All bugs fixed** - Hive transaction issues, race conditions resolved

## 📋 Available Methods

### Regular Tables (CrudConfig)

- `insert(config, model)` - Insert single record
- `update(config, model)` - Update single record
- `upsert(config, model)` - Insert or update with timestamp validation
- `delete(config, id)` - Delete by ID
- `deleteBulk(config, models)` - Delete multiple records
- `deleteAll(config)` - Delete all records
- `getById(config, id)` - Get single record by ID
- `getList(config)` - Get all records

### Pivot Tables (PivotCrudConfig)

- `upsertPivot(config, model)` - Upsert with composite key
- `deletePivot(config, compositeKey, keyColumns)` - Delete by composite key
- `deleteBulkPivot(config, models)` - Delete multiple pivot records
- `deleteByColumnName(config, columnName, value)` - Delete by column match
- `getByIdPivot(config, compositeKey, pivotElements)` - Get by composite key
- `getListPivot(config)` - Get all pivot records

## ❓ FAQs

**Q: What happened to the old methods?**  
A: They're removed! Clean architecture only. All repositories must migrate to the new pattern.

**Q: Why HiveCacheStore instead of HiveSyncHelper?**  
A: `HiveCacheStore` implements `ICacheStore` interface for abstraction. You can test with mock cache and swap implementations. `HiveSyncHelper` is used internally by `HiveCacheStore`.

**Q: Can I use both patterns?**  
A: No - old methods are removed. This ensures clean, consistent code across your codebase.

**Q: What about pivot tables?**  
A: Use `PivotCrudConfig` - same clean pattern, works perfectly!

**Q: Does this affect performance?**  
A: **Improves it!** Cache operations no longer block database transactions.

**Q: Do I need to refactor everything at once?**  
A: Yes, since old methods are removed. But the migration is straightforward - just create config objects in repository constructors.
