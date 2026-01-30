# Repository Refactoring Guide

**Best Practices for Local Repository Implementation**

## Overview

This guide provides a standardized approach to refactoring local repositories for optimal performance, data integrity, and Hive/SQLite synchronization.

## Reference Implementations

- **Regular Tables**: `lib/data/repositories/local/local_cash_drawer_log_repository_impl.dart`
- **Pivot Tables**: `lib/data/repositories/local/local_category_discount_repository_impl.dart`
- **All-in-One Service**: `lib/core/services/repository_crud_service.dart`

---

## Core Principles

### 1. **Dual Storage Strategy**

- **SQLite**: Source of truth, persistent storage
- **Hive**: In-memory cache for fast reads

### 2. **Data Consistency**

- Always sync both storages atomically
- Only update when incoming data is newer (timestamp validation)
- Populate cache on read misses

### 3. **Performance Optimization**

- Use chunking for bulk operations (500 records per chunk)
- Query only necessary columns for timestamp checks
- Minimize Hive writes (only changed records)

### 4. **Accurate Change Tracking**

- Only track pending changes for records that actually change
- Distinguish between 'created' and 'updated' operations

---

## Method-by-Method Refactoring

### 1. INSERT Method ✅

**Current State**: Usually already correct
**Requirements**:

- Generate ID if null
- Set createdAt and updatedAt to now
- Write to SQLite first, then Hive
- Track pending if requested

**No changes needed** if following this pattern.

---

### 2. UPDATE Method ✅

**Current State**: Usually already correct
**Requirements**:

- Update updatedAt to now
- Write to SQLite first, then Hive
- Track pending if requested

**No changes needed** if following this pattern.

---

### 3. DELETE Method ✅

**Current State**: Usually already correct
**Requirements**:

- Fetch model from Hive (or create minimal model with ID)
- Delete from SQLite first, then Hive
- Track pending if requested

**No changes needed** if following this pattern.

---

### 4. INSERT BULK Method ⚠️ **NEEDS REFACTORING**

#### Current Issues:

❌ No chunking (hits SQL limits with large datasets)
❌ Always replaces data regardless of timestamp
❌ Inaccurate pending tracking (tracks all items, not just changed ones)
❌ Hive out of sync when older data is rejected by SQL

#### Refactored Template:

```dart
@override
Future<bool> insertBulk(
  List<YourModel> list,
  bool isInsertToPending,
) async {
  if (list.isEmpty) return true;

  try {
    final db = await _dbHelper.database;
    const chunkSize = 500; // Process in chunks to avoid SQL limits
    final List<PendingChangesModel> allPendingChanges = [];

    // Process in chunks for better memory management and performance
    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.sublist(
        i,
        (i + chunkSize) > list.length ? list.length : i + chunkSize,
      );

      // Query existing records with timestamps to determine actual changes
      // This ensures Hive stays in sync with SQL by only updating newer records
      final chunkIds = chunk.map((m) => m.id).whereType<String>().toList();
      final Map<String, DateTime?> existingTimestamps = {};

      if (chunkIds.isNotEmpty) {
        final placeholders = List.filled(chunkIds.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$cId IN ($placeholders)',
          whereArgs: chunkIds,
          columns: [cId, cUpdatedAt],
        );

        for (var record in existingRecords) {
          final id = record[cId] as String;
          final updatedAtStr = record[cUpdatedAt] as String?;
          existingTimestamps[id] =
              updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null;
        }
      }

      // Track which models will actually be updated (for Hive sync)
      final List<YourModel> modelsToSync = [];

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (var model in chunk) {
          if (model.id == null) continue;

          model.createdAt ??= DateTime.now();
          model.updatedAt ??= DateTime.now();

          final modelJson = model.toJson();
          final columns = modelJson.keys.join(',');
          final placeholders = List.filled(modelJson.length, '?').join(',');

          // Determine if this record will actually change
          final existingTimestamp = existingTimestamps[model.id];
          final willChange =
              existingTimestamp == null || // New record
              model.updatedAt!.isAfter(existingTimestamp); // Newer data

          if (willChange) {
            // Only sync to Hive if record will actually be updated in SQL
            modelsToSync.add(model);

            // Track pending changes
            if (isInsertToPending) {
              allPendingChanges.add(
                PendingChangesModel(
                  operation: existingTimestamp == null ? 'created' : 'updated',
                  modelName: YourModel.modelName,
                  modelId: model.id!,
                  data: jsonEncode(modelJson),
                ),
              );
            }
          }

          // Upsert with timestamp check - only updates if incoming data is newer
          batch.rawInsert(
            '''INSERT INTO $tableName ($columns)
               VALUES ($placeholders)
               ON CONFLICT($cId) DO UPDATE SET
                 ${modelJson.keys.where((k) => k != cId).map((k) => '$k = excluded.$k').join(', ')}
               WHERE excluded.$cUpdatedAt > $tableName.$cUpdatedAt
                  OR $tableName.$cUpdatedAt IS NULL''',
            modelJson.values.toList(),
          );
        }

        await batch.commit(noResult: true);
      });

      // Sync ONLY the changed records to Hive after successful transaction
      if (modelsToSync.isNotEmpty) {
        final dataMap = HiveSyncHelper.buildBulkDataMap(
          list: modelsToSync,
          getId: (model) => model.id,
          toJson: (model) => model.toJson(),
        );
        await _hiveBox.putAll(dataMap);
      }
    }

    // Track all pending changes after all chunks are committed
    if (isInsertToPending && allPendingChanges.isNotEmpty) {
      await Future.wait(
        allPendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );
    }

    return true;
  } catch (e) {
    await LogUtils.error('Error bulk inserting [model name]', e);
    return false;
  }
}
```

#### Key Changes:

1. ✅ Chunking (500 records per batch)
2. ✅ Timestamp validation (query existing records)
3. ✅ Accurate pending tracking (only changed records)
4. ✅ Perfect Hive/SQL sync (only update newer records)
5. ✅ Transaction per chunk (better error handling)

---

### 5. GET LIST Method ⚠️ **NEEDS REFACTORING**

#### Current Issue:

❌ Doesn't populate Hive cache on miss → every subsequent read still hits SQLite

#### Before:

```dart
@override
Future<List<YourModel>> getList() async {
  // Try Hive cache first
  final hiveList = HiveSyncHelper.getListFromBox(
    box: _hiveBox,
    fromJson: (json) => YourModel.fromJson(json),
  );
  if (hiveList.isNotEmpty) {
    return hiveList;
  }

  // Fallback to SQLite
  final maps = await _dbHelper.readDb(tableName);
  return maps.map((json) => YourModel.fromJson(json)).toList();
}
```

#### After:

```dart
@override
Future<List<YourModel>> getList() async {
  // Try Hive cache first
  final hiveList = HiveSyncHelper.getListFromBox(
    box: _hiveBox,
    fromJson: (json) => YourModel.fromJson(json),
  );
  if (hiveList.isNotEmpty) {
    return hiveList;
  }

  // Fallback to SQLite and populate Hive cache for future reads
  final maps = await _dbHelper.readDb(tableName);
  final models = maps.map((json) => YourModel.fromJson(json)).toList();

  // Populate Hive cache to avoid future SQLite queries
  if (models.isNotEmpty) {
    final dataMap = HiveSyncHelper.buildBulkDataMap(
      list: models,
      getId: (model) => model.id,
      toJson: (model) => model.toJson(),
    );
    await _hiveBox.putAll(dataMap);
  }

  return models;
}
```

---

### 6. GET BY ID Method ⚠️ **NEEDS REFACTORING**

#### Current Issue:

❌ Doesn't populate Hive cache on miss → every subsequent read still hits SQLite

#### Before:

```dart
Future<YourModel?> getById(String id) async {
  // Try Hive cache first
  final hiveModel = HiveSyncHelper.getById(
    box: _hiveBox,
    id: id,
    fromJson: (json) => YourModel.fromJson(json),
  );

  if (hiveModel != null) {
    return hiveModel;
  }

  // Fallback to SQLite
  final map = await _dbHelper.readDbById(tableName, id);
  if (map != null) {
    return YourModel.fromJson(map);
  }
  return null;
}
```

#### After:

```dart
Future<YourModel?> getById(String id) async {
  // Try Hive cache first
  final hiveModel = HiveSyncHelper.getById(
    box: _hiveBox,
    id: id,
    fromJson: (json) => YourModel.fromJson(json),
  );

  if (hiveModel != null) {
    return hiveModel;
  }

  // Fallback to SQLite and populate Hive cache for future reads
  final map = await _dbHelper.readDbById(tableName, id);
  if (map != null) {
    final model = YourModel.fromJson(map);
    // Populate Hive cache to avoid future SQLite queries
    await _hiveBox.put(id, model.toJson());
    return model;
  }
  return null;
}
```

---

### 7. REPLACE ALL DATA Method ✅

**Current State**: Usually already correct if it uses insertBulk

```dart
@override
Future<bool> replaceAllData(
  List<YourModel> newData, {
  bool isInsertToPending = false,
}) async {
  try {
    final db = await _dbHelper.database;
    await db.delete(tableName); // Delete all rows from SQLite
    await _hiveBox.clear(); // Clear Hive
    return await insertBulk(newData, isInsertToPending: isInsertToPending);
  } catch (e) {
    await LogUtils.error('Error replacing all [model name]', e);
    return false;
  }
}
```

**No changes needed** if following this pattern.

---

### 8. DELETE ALL Method ✅

**Current State**: Usually already correct

```dart
@override
Future<bool> deleteAll() async {
  try {
    // Delete from SQLite
    final db = await _dbHelper.database;
    await db.delete(tableName);

    // Delete from Hive
    await _hiveBox.clear();

    return true;
  } catch (e) {
    await LogUtils.error('Error deleting all [model name]', e);
    return false;
  }
}
```

**No changes needed** if following this pattern.

---

## Required Imports

Make sure these imports are present:

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:sqflite/sqflite.dart';
```

---

## Checklist for Each Repository

### Before Refactoring:

- [ ] Identify all CRUD methods
- [ ] Check if model has `id`, `createdAt`, `updatedAt` fields
- [ ] Verify Hive box is injected in constructor
- [ ] Verify pending changes repository is injected

### Methods to Refactor:

- [ ] `insertBulk()` - Add chunking, timestamp validation, accurate tracking
- [ ] `getList()` - Add Hive cache population on miss
- [ ] `getById()` - Add Hive cache population on miss

### After Refactoring:

- [ ] Test with small dataset (100 records)
- [ ] Test with large dataset (5000+ records)
- [ ] Verify Hive/SQL stay in sync
- [ ] Verify pending changes are accurate
- [ ] Verify older data doesn't overwrite newer data
- [ ] Run `dart fix --apply`

---

## Performance Expectations

After refactoring:

### Write Operations (5000 records):

- **Time**: 650ms - 2 seconds
- **Memory**: Only 500 records in memory at a time
- **Accuracy**: 100% (only tracks actual changes)

### Read Operations:

- **First read**: 50-200ms (SQLite + cache population)
- **Subsequent reads**: 1-5ms (Hive cache)
- **By ID**: <1ms (Hive cache)

---

## Common Pitfalls to Avoid

❌ **Don't** query timestamps only when `isInsertToPending = true`
✅ **Do** always query timestamps to keep Hive in sync

❌ **Don't** use `ConflictAlgorithm.replace` without timestamp check
✅ **Do** use `ON CONFLICT ... WHERE` with timestamp comparison

❌ **Don't** sync all records to Hive in bulk operations
✅ **Do** only sync records that actually changed

❌ **Don't** forget to populate cache on read misses
✅ **Do** always populate Hive when falling back to SQLite

❌ **Don't** process all records at once
✅ **Do** use chunking for datasets > 100 records

---

## Example Refactoring Workflow

### For Regular Tables (Single ID Column):

1. **Open repository file**
2. **Find `insertBulk()` method** → Use `RepositoryCrudService.upsertBulk()`
3. **Find `getList()` method** → Add cache population with `RepositoryCrudService.populateHiveCache()`
4. **Find `getById()` method** → Use `RepositoryCrudService.getById()`
5. **Find single CRUD methods** → Use `RepositoryCrudService.insert()`, `update()`, `delete()`
6. **Update model names in error messages**
7. **Run `dart fix --apply`**
8. **Test with various data scenarios**

### For Pivot Tables (Composite Keys):

1. **Open repository file**
2. **Find `upsertBulk()` method** → Use `RepositoryCrudService.upsertBulkPivot()`
3. **Find `getList()` method** → Add cache population with `RepositoryCrudService.populateHiveCachePivot()`
4. **Find single CRUD methods** → Use `RepositoryCrudService.upsertPivot()`, `deletePivot()`
5. **Update composite key generation logic**
6. **Run `dart fix --apply`**
7. **Test with various data scenarios**

---

## Using RepositoryCrudService (NEW!)

The `RepositoryCrudService` provides reusable implementations for ALL common CRUD operations, making repositories even simpler and more maintainable.

### Available Operations:

#### For Regular Tables:

- `insert()` - Insert single record with ID generation and timestamps
- `update()` - Update single record with timestamp
- `upsert()` - Insert or update single record (checks if exists)
- `upsertBulk()` - Bulk upsert with chunking and timestamp validation
- `delete()` - Delete single record
- `deleteBulk()` - Delete multiple records
- `deleteAll()` - Delete all records from table
- `getById()` - Get single record with cache population
- `populateHiveCache()` - Populate cache for list of models

#### For Pivot Tables:

- `upsertPivot()` - Upsert single pivot record
- `upsertBulkPivot()` - Bulk upsert for pivot tables with chunking
- `deletePivot()` - Delete single pivot record
- `deleteBulkPivot()` - Delete multiple pivot records
- `deleteByColumnName()` - Delete pivot records by column
- `populateHiveCachePivot()` - Populate cache for pivot models

### Example Usage:

#### Regular Table - Insert:

```dart
@override
Future<int> insert(
  CashDrawerLogModel model, {
  required bool isInsertToPending,
}) async {
  final db = await _dbHelper.database;

  return await RepositoryCrudService.insert<CashDrawerLogModel>(
    db: db,
    tableName: tableName,
    model: model,
    getId: (model) => model.id,
    toJson: (model) => model.toJson(),
    modelName: CashDrawerLogModel.modelName,
    hiveBox: _hiveBox,
    pendingChangesRepository: _pendingChangesRepository,
    isInsertToPending: isInsertToPending,
    setId: (model, id) => model.id = id,
    setTimestamps: (model) {
      model.createdAt = DateTime.now();
      model.updatedAt = DateTime.now();
    },
  );
}
```

#### Regular Table - Update:

```dart
@override
Future<int> update(
  CashDrawerLogModel model, {
  required bool isInsertToPending,
}) async {
  final db = await _dbHelper.database;

  return await RepositoryCrudService.update<CashDrawerLogModel>(
    db: db,
    tableName: tableName,
    model: model,
    getId: (model) => model.id,
    toJson: (model) => model.toJson(),
    modelName: CashDrawerLogModel.modelName,
    hiveBox: _hiveBox,
    pendingChangesRepository: _pendingChangesRepository,
    isInsertToPending: isInsertToPending,
    updateTimestamp: (model) => model.updatedAt = DateTime.now(),
    idColumn: cId,
  );
}
```

#### Regular Table - Upsert:

```dart
@override
Future<int> upsert(
  CashDrawerLogModel model, {
  required bool isInsertToPending,
}) async {
  final db = await _dbHelper.database;

  return await RepositoryCrudService.upsert<CashDrawerLogModel>(
    db: db,
    tableName: tableName,
    model: model,
    getId: (model) => model.id,
    toJson: (model) => model.toJson(),
    modelName: CashDrawerLogModel.modelName,
    hiveBox: _hiveBox,
    pendingChangesRepository: _pendingChangesRepository,
    isInsertToPending: isInsertToPending,
    setId: (model, id) => model.id = id,
    setTimestamps: (model) {
      model.createdAt = DateTime.now();
      model.updatedAt = DateTime.now();
    },
    updateTimestamp: (model) => model.updatedAt = DateTime.now(),
    idColumn: cId,
  );
}
```

#### Regular Table - Delete:

```dart
@override
Future<int> delete(String id, {required bool isInsertToPending}) async {
  final db = await _dbHelper.database;

  // Get model from cache for pending changes tracking
  final model = HiveSyncHelper.getById(
    box: _hiveBox,
    id: id,
    fromJson: (json) => CashDrawerLogModel.fromJson(json),
  );

  return await RepositoryCrudService.delete<CashDrawerLogModel>(
    db: db,
    tableName: tableName,
    id: id,
    model: model,
    toJson: (model) => model.toJson(),
    modelName: CashDrawerLogModel.modelName,
    hiveBox: _hiveBox,
    pendingChangesRepository: _pendingChangesRepository,
    isInsertToPending: isInsertToPending,
    idColumn: cId,
  );
}
```

#### Pivot Table - Upsert:

```dart
@override
Future<int> upsert(
  CategoryDiscountModel model, {
  required bool isInsertToPending,
}) async {
  final db = await _dbHelper.database;

  return await RepositoryCrudService.upsertPivot<CategoryDiscountModel>(
    db: db,
    tableName: tableName,
    model: model,
    getCompositeKey: (model) => '${model.categoryId}_${model.discountId}',
    getKeyColumns: (model) => {
      categoryId: model.categoryId,
      discountId: model.discountId,
    },
    toJson: (model) => model.toJson(),
    modelName: CategoryDiscountModel.modelName,
    hiveBox: _hiveBox,
    pendingChangesRepository: _pendingChangesRepository,
    isInsertToPending: isInsertToPending,
    setTimestamps: (model) {
      model.createdAt ??= DateTime.now();
      model.updatedAt = DateTime.now();
    },
    updatedAtColumn: updatedAt,
  );
}
```

#### Pivot Table - Delete:

```dart
@override
Future<int> deletePivot(
  CategoryDiscountModel model, {
  required bool isInsertToPending,
}) async {
  final db = await _dbHelper.database;

  return await RepositoryCrudService.deletePivot<CategoryDiscountModel>(
    db: db,
    tableName: tableName,
    model: model,
    getCompositeKey: (model) => '${model.categoryId}_${model.discountId}',
    getKeyColumns: (model) => {
      categoryId: model.categoryId,
      discountId: model.discountId,
    },
    toJson: (model) => model.toJson(),
    modelName: CategoryDiscountModel.modelName,
    hiveBox: _hiveBox,
    pendingChangesRepository: _pendingChangesRepository,
    isInsertToPending: isInsertToPending,
  );
}
```

### Benefits:

✅ **Maximum code reuse** - All CRUD logic centralized in one service
✅ **Consistency** - Same behavior across all repositories
✅ **Less boilerplate** - Repositories become thin wrappers
✅ **Easier testing** - Test service once, not every repository
✅ **Better maintainability** - Fix bugs in one place
✅ **Type-safe** - Full type checking with generics
✅ **Single source of truth** - One service for all operations (including bulk)

---

## Pivot Table Specific Considerations

Pivot tables (many-to-many relationships) have unique requirements:

### Composite Keys:

- Use concatenated keys: `"${firstId}_${secondId}"`
- Store in Hive using composite key as the key
- Query using both columns: `WHERE column1 = ? AND column2 = ?`

### ON CONFLICT Clause:

```sql
ON CONFLICT(column1, column2) DO UPDATE SET ...
```

### Example Pivot Implementation:

See [local_category_discount_repository_impl.dart](lib/data/repositories/local/local_category_discount_repository_impl.dart) for a complete pivot table implementation.

### Key Differences from Regular Tables:

| Aspect             | Regular Table     | Pivot Table                     |
| ------------------ | ----------------- | ------------------------------- |
| Primary Key        | Single ID column  | Composite key (2+ columns)      |
| Hive Key           | `model.id`        | `"${id1}_${id2}"`               |
| ON CONFLICT        | `ON CONFLICT(id)` | `ON CONFLICT(col1, col2)`       |
| Query Existing     | `WHERE id IN (?)` | Individual queries per key pair |
| Pending Changes ID | `model.id`        | Composite key string            |

---

## Questions?

Reference implementations:

- Regular tables: `local_cash_drawer_log_repository_impl.dart`
- Pivot tables: `local_category_discount_repository_impl.dart`

Single service for everything:

- **`RepositoryCrudService`** - All CRUD operations in one place
  - Single operations: `insert()`, `update()`, `upsert()`, `delete()`, etc.
  - Bulk operations: `upsertBulk()`, `upsertBulkPivot()`, `deleteBulk()`, etc.
  - Pivot operations: `upsertPivot()`, `deletePivot()`, etc.
  - Cache operations: `populateHiveCache()`, `populateHiveCachePivot()`, `getById()`

This refactoring ensures:
✅ Perfect data integrity
✅ Optimal performance
✅ Accurate change tracking
✅ Minimal code duplication
✅ Easy maintenance
✅ Single service for all operations
✅ Production-ready for large datasets
