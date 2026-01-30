# Provider Refactoring Checklist & Guide

## Overview

This guide helps you evaluate and refactor Riverpod providers following best practices. Based on the category provider refactoring completed on Dec 29, 2025.

---

## 🎯 Evaluation Criteria

### ✅ Good Patterns to Look For

- [ ] Uses `AsyncNotifier` for state management
- [ ] Immutable state with Freezed
- [ ] Repository pattern properly implemented
- [ ] Mutation operations use the `AsyncNotifierMutationMixin`
- [ ] Computed providers for derived state
- [ ] Clean separation of concerns
- [ ] Not over-engineered

### ⚠️ Issues to Watch For

1. **State Model Issues**

   - Redundant `error` and `isLoading` fields (AsyncValue handles this)
   - Mutable state objects
   - Unnecessary complexity

2. **Mutation Mixin Issues**

   - Calling `onSuccess` with potentially null state
   - Not handling errors with previous state
   - Missing `ref.invalidateSelf()` when state is null

3. **Error Handling Issues**

   - Swallowing errors (returning empty lists/null instead of throwing)
   - Inconsistent error propagation
   - Missing error logs

4. **Return Type Issues**
   - Using `.then()` chains instead of awaiting directly
   - Inconsistent return patterns

---

## 📋 Step-by-Step Refactoring Process

### Step 1: Evaluate the State Model

**Check for:**

```dart
// ❌ BAD - Redundant fields
@freezed
class MyState with _$MyState {
  const factory MyState({
    @Default([]) List<MyModel> items,
    String? error,           // ❌ Remove - AsyncValue handles this
    @Default(false) bool isLoading,  // ❌ Remove - AsyncValue handles this
  }) = _MyState;
}

// ✅ GOOD - Clean and minimal
@freezed
class MyState with _$MyState {
  const factory MyState({
    @Default([]) List<MyModel> items,
  }) = _MyState;
}
```

**Action:**

- Remove `error` field
- Remove `isLoading` field
- Keep only domain-specific data

### Step 2: Review the AsyncNotifierMutationMixin

**Check your mixin implementation:**

```dart
// ✅ CORRECT Implementation
mixin AsyncNotifierMutationMixin<T> on AsyncNotifier<T> {
  Future<R> mutate<R>(
    Future<R> Function() action,
    T Function(T currentState) onSuccess,
  ) async {
    final previous = state.value;

    // Set loading state
    state = previous != null
        ? AsyncValue<T>.loading().copyWithPrevious(AsyncValue.data(previous))
        : const AsyncValue.loading();

    try {
      final result = await action();

      // Only update if previous state exists
      if (previous != null) {
        state = AsyncValue.data(onSuccess(previous));
      } else {
        // Trigger rebuild to fetch fresh data
        ref.invalidateSelf();
      }

      return result;
    } catch (e, stackTrace) {
      // Restore previous state on error if available
      if (previous != null) {
        state = AsyncValue<T>.error(e, stackTrace).copyWithPrevious(
          AsyncValue.data(previous),
        );
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }
}
```

**Key Points:**

- ✅ Use `AsyncValue<T>.error()` not `AsyncValue.error()`
- ✅ Call `ref.invalidateSelf()` when previous is null
- ✅ Preserve previous state on error
- ✅ Always rethrow errors

### Step 3: Review Provider Operations

#### Delete Operations

```dart
// ❌ BAD - Using .then() chain
Future<bool> delete(String id) async {
  return mutate(
    () => _localRepository.delete(id),
    (current) => current.copyWith(
      items: current.items.where((item) => item.id != id).toList(),
    ),
  ).then((r) => r > 0);
}

// ✅ GOOD - Await and return directly
Future<bool> delete(String id) async {
  final result = await mutate(
    () => _localRepository.delete(id),
    (current) => current.copyWith(
      items: current.items.where((item) => item.id != id).toList(),
    ),
  );
  return result > 0;
}
```

#### Sync Operations

```dart
// ❌ BAD - Swallowing errors
Future<List<MyModel>> syncFromRemote() async {
  try {
    final data = await _remoteRepository.fetchAll();
    await mutate(/* ... */);
    return data;
  } catch (e) {
    await LogUtils.error('Sync failed', e);
    return []; // ❌ Swallows error
  }
}

// ✅ GOOD - Propagate errors
Future<List<MyModel>> syncFromRemote() async {
  prints('Starting sync...');

  final data = await _remoteRepository.fetchAll();

  if (data.isEmpty) {
    prints('No data to sync');
    return [];
  }

  final saved = await mutate(
    () => _localRepository.upsertBulk(data, isInsertToPending: false),
    (current) {
      final map = {for (final item in current.items) item.id!: item};
      for (final item in data) {
        map[item.id!] = item;
      }
      return current.copyWith(items: map.values.toList());
    },
  );

  if (!saved) {
    await LogUtils.error('Failed to save synced data', null);
    throw Exception('Failed to save synced data'); // ✅ Throws error
  }

  prints('Successfully synced ${data.length} items');
  return data;
}
```

#### Bulk Operations

```dart
// ✅ GOOD Pattern
Future<bool> upsertBulk(
  List<MyModel> list, {
  bool isInsertToPending = true,
}) async {
  return mutate(
    () => _localRepository.upsertBulk(list, isInsertToPending: isInsertToPending),
    (current) {
      final map = {for (final item in current.items.where((i) => i.id != null)) item.id!: item};
      for (final item in list) {
        if (item.id != null) {
          map[item.id!] = item;
        }
      }
      return current.copyWith(items: map.values.toList());
    },
  );
}
```

### Step 4: Add Computed Providers

```dart
// ✅ GOOD - Add useful computed providers

// Sorted provider
final sortedItemsProvider = Provider<List<MyModel>>((ref) {
  final state = ref.watch(myProvider).value;
  if (state == null) return [];

  final sorted = [...state.items];
  sorted.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
  return sorted;
});

// By ID provider (family)
final itemByIdProvider = Provider.family<MyModel?, String>((ref, id) {
  final state = ref.watch(myProvider).value;
  if (state == null) return null;

  try {
    return state.items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});
```

### Step 5: Rebuild Freezed Files

After modifying state models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🔍 Common Issues & Solutions

### Issue 1: Type Error in Mutation Mixin

```dart
// ❌ Error: Can't assign AsyncValue<dynamic> to AsyncValue<T>
state = AsyncValue.error(e, stackTrace).copyWithPrevious(/*...*/);

// ✅ Solution: Specify type explicitly
state = AsyncValue<T>.error(e, stackTrace).copyWithPrevious(/*...*/);
```

### Issue 2: Null State Handling

```dart
// ❌ BAD - May pass null to onSuccess
if (previous != null) {
  state = AsyncValue.data(onSuccess(previous));
}
// State never updates if previous is null!

// ✅ GOOD - Invalidate to trigger rebuild
if (previous != null) {
  state = AsyncValue.data(onSuccess(previous));
} else {
  ref.invalidateSelf();
}
```

### Issue 3: Getter Method in Notifier

```dart
// ✅ GOOD - Keep simple getters in notifier for convenience
MyModel? getItemById(String id) {
  final current = state.value;
  if (current == null) return null;

  try {
    final item = current.items.firstWhere((i) => i.id == id);
    return item.id != null ? item : null;
  } catch (_) {
    return null;
  }
}
```

---

## 📝 Complete Refactoring Checklist

### State Model

- [ ] Remove `error` field
- [ ] Remove `isLoading` field
- [ ] Keep only domain data
- [ ] Using Freezed for immutability
- [ ] Run build_runner after changes

### Mutation Mixin

- [ ] Handles null state correctly
- [ ] Uses `AsyncValue<T>.error()` with explicit type
- [ ] Calls `ref.invalidateSelf()` when previous is null
- [ ] Preserves previous state on errors
- [ ] Rethrows errors

### Provider Operations

- [ ] Delete: Returns bool directly (no `.then()`)
- [ ] Sync: Throws errors instead of returning empty list
- [ ] Bulk operations: Use map for efficient upserts
- [ ] All operations use `mutate()` for state updates

### Computed Providers

- [ ] Add sorted provider if needed
- [ ] Add by-id provider (family) if needed
- [ ] Add filtered providers if needed
- [ ] Handle null state safely

### Error Handling

- [ ] Logs errors appropriately
- [ ] Propagates errors to UI
- [ ] Provides meaningful error messages
- [ ] No silent failures

### Code Quality

- [ ] Consistent formatting
- [ ] Clear documentation comments
- [ ] No code duplication
- [ ] Follows Dart/Flutter conventions

---

## 🎓 Example: Complete Provider Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/async_notifier_mutation_mixin.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/my_model.dart';
import 'package:mts/data/repositories/local/local_my_repository_impl.dart';
import 'package:mts/data/repositories/remote/my_repository_impl.dart';
import 'package:mts/domain/repositories/local/my_repository.dart';
import 'package:mts/domain/repositories/remote/my_repository.dart';
import 'package:mts/providers/my/my_state.dart';

/// AsyncNotifier for My domain
class MyNotifier extends AsyncNotifier<MyState>
    with AsyncNotifierMutationMixin<MyState> {
  late final LocalMyRepository _localRepository;
  late final MyRepository _remoteRepository;

  @override
  Future<MyState> build() async {
    _localRepository = ref.read(myLocalRepoProvider);
    _remoteRepository = ref.read(myRemoteRepoProvider);

    final items = await _localRepository.getList();
    return MyState(items: items);
  }

  /// Insert or update multiple items
  Future<bool> upsertBulk(
    List<MyModel> list, {
    bool isInsertToPending = true,
  }) async {
    return mutate(
      () => _localRepository.upsertBulk(list, isInsertToPending: isInsertToPending),
      (current) {
        final map = {for (final item in current.items.where((i) => i.id != null)) item.id!: item};
        for (final item in list) {
          if (item.id != null) {
            map[item.id!] = item;
          }
        }
        return current.copyWith(items: map.values.toList());
      },
    );
  }

  /// Delete single item
  Future<bool> delete(String id, {bool isInsertToPending = true}) async {
    final result = await mutate(
      () => _localRepository.delete(id, isInsertToPending: isInsertToPending),
      (current) => current.copyWith(
        items: current.items.where((item) => item.id != id).toList(),
      ),
    );
    return result > 0;
  }

  /// Delete all items
  Future<bool> deleteAll() async {
    return mutate(
      () => _localRepository.deleteAll(),
      (_) => const MyState(items: []),
    );
  }

  /// Replace all local data
  Future<bool> replaceAllData(
    List<MyModel> newData, {
    bool isInsertToPending = false,
  }) async {
    return mutate(
      () => _localRepository.replaceAllData(newData, isInsertToPending: isInsertToPending),
      (_) => MyState(items: newData),
    );
  }

  /// Sync from remote API
  Future<List<MyModel>> syncFromRemote() async {
    prints('Starting sync for ${MyModel.modelName}...');

    final allItems = await _remoteRepository.fetchAllPaginated();
    prints('Fetched ${allItems.length} ${MyModel.modelName} from remote');

    if (allItems.isEmpty) {
      prints('No ${MyModel.modelName} to sync');
      return [];
    }

    final saved = await mutate(
      () => _localRepository.upsertBulk(allItems, isInsertToPending: false),
      (current) {
        final map = {for (final item in current.items.where((i) => i.id != null)) item.id!: item};
        for (final item in allItems.where((i) => i.id != null)) {
          map[item.id!] = item;
        }
        return current.copyWith(items: map.values.toList());
      },
    );

    if (!saved) {
      await LogUtils.error('Failed to save synced ${MyModel.modelName}', null);
      throw Exception('Failed to save synced data to local storage');
    }

    prints('Successfully synced ${allItems.length} items');
    return allItems;
  }

  /// Get a single item by ID (from state)
  MyModel? getItemById(String id) {
    final current = state.value;
    if (current == null) return null;

    try {
      final item = current.items.firstWhere((i) => i.id == id);
      return item.id != null ? item : null;
    } catch (_) {
      return null;
    }
  }
}

/// Main provider
final myProvider = AsyncNotifierProvider<MyNotifier, MyState>(
  () => MyNotifier(),
);

/// Computed provider for sorted items
final sortedItemsProvider = Provider<List<MyModel>>((ref) {
  final state = ref.watch(myProvider).value;
  if (state == null) return [];

  final sorted = [...state.items];
  sorted.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
  return sorted;
});

/// Provider for item by ID (family)
final itemByIdProvider = Provider.family<MyModel?, String>((ref, id) {
  final state = ref.watch(myProvider).value;
  if (state == null) return null;

  try {
    final item = state.items.firstWhere((i) => i.id == id);
    return item.id != null ? item : null;
  } catch (_) {
    return null;
  }
});
```

---

## 🚀 Quick Start

1. **Evaluate**: Check current provider against criteria
2. **Plan**: Identify issues using this checklist
3. **State**: Clean up state model first
4. **Mixin**: Verify mutation mixin is correct
5. **Operations**: Refactor each operation
6. **Providers**: Add computed providers
7. **Build**: Run build_runner
8. **Test**: Verify all operations work

---

## 📚 References

- [Riverpod Documentation](https://riverpod.dev)
- [AsyncNotifier Best Practices](https://riverpod.dev/docs/concepts/about_code_generation#asyncnotifier)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- Category Provider Refactoring (Dec 29, 2025)

---

_Last Updated: December 29, 2025_
