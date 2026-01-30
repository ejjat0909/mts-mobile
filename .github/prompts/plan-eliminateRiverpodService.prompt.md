# Plan: Eliminate RiverpodService & Simplify DI

**Overview**: Remove the `RiverpodService` singleton bridge entirely by converting all non-widget code that needs provider access into either Riverpod providers themselves or by refactoring widgets to use `ref` directly. This eliminates ServiceLocator-Riverpod coupling and simplifies the dependency chain.

## Analysis of Current Usage

**Current usages found (11+ files):**

- `sale_facade_impl.dart` (7 usages)
- `deleted_sale_item_facade_impl.dart` (2 usages)
- `receipt_facade_impl.dart` (2+ usages)
- `discount_form_bloc.dart` (1 usage)
- `close_shift.dart` (1 usage)
- `assign_order_dialogue.dart` (1 usage)
- `variation_and_modifier_dialogue.dart` (1 usage, commented out)
- `global_riverpod_container.dart` (initialization)

## Steps

### 1. Extract facade business logic into Riverpod providers

Convert 3 main facades to providers:

- `SaleFacadeImpl` → `saleProvider` (StateNotifierProvider) that reads `saleItemsProvider` internally
- `DeletedSaleItemFacadeImpl` → `deletedSaleItemProvider`
- `ReceiptFacadeImpl` → `receiptProvider`
- **Pattern**: Move `_riverpodService.read()` calls into provider logic; use `ref.watch(saleItemsProvider)` instead

**Key Changes:**

- Create new provider files in `lib/providers/riverpod/` for each domain
- Each provider injects its dependencies via `ref` parameter in the notifier
- Facade methods become provider methods/computations
- Delete `_riverpodService` field from facades once providers are ready

### 2. Refactor form_bloc & non-widget classes

Convert RiverpodService access to provider parameters:

- `DiscountFormBloc` → Inject `saleItemsProvider` as constructor dependency (instead of reading via RiverpodService)
- Create adapter/wrapper if FormBloc can't be refactored; keep separate from widgets
- Store provider value in state, not querying dynamically

**Key Changes:**

- Update FormBloc constructor to accept required provider values
- Update FormBloc instantiation in service locator to pass provider values from GlobalRiverpodContainer
- Remove `ServiceLocator.get<RiverpodService>()` calls

### 3. Convert StatefulWidget → ConsumerStatefulWidget

Enable direct `ref` access (high priority):

- `CloseShift` → Already `ConsumerStatefulWidget`; swap `RiverpodService.get()` → `ref.watch()`
- `AssignOrderDialogue` → Same conversion
- `VariationAndModifierDialogue` → Same conversion
- Removes need for `ServiceLocator.get<RiverpodService>()`

**Key Changes:**

- Change `final _riverpodService = ServiceLocator.get<RiverpodService>();` to nothing
- Replace `_riverpodService.read(provider)` with `ref.read(provider)`
- Replace `_riverpodService.listen(provider, ...)` with `ref.listen(provider, ...)`

### 4. Delete RiverpodService initialization

Clean up DI:

- Remove from `global_riverpod_container.dart`:
  - `_initRiverpodService()` method
  - `RiverpodService.instance.setContainer(_container)` call
- Remove from `service_locator.dart`:
  - RiverpodService registration (`_getIt.registerLazySingleton<RiverpodService>(...)`)
  - Import statement: `import 'package:mts/app/di/riverpod_service.dart';`

**Key Changes:**

- Simplify GlobalRiverpodContainer to only manage ProviderContainer
- Remove RiverpodService from ServiceLocator registration

### 5. Delete RiverpodService file

Final cleanup:

- Delete `lib/app/di/riverpod_service.dart`
- Search for any remaining imports: `grep -r "riverpod_service" lib/`
- Search for any remaining usages: `grep -r "RiverpodService" lib/`
- Verify app builds and runs with no errors

## Implementation Order

1. **Convert ConsumerStatefulWidgets** (easiest, low risk):
   - `close_shift.dart`
   - `assign_order_dialogue.dart`
   - `variation_and_modifier_dialogue.dart`
2. **Update Facades to remove RiverpodService**:
   - Create provider wrappers for `SaleFacadeImpl`, `DeletedSaleItemFacadeImpl`, `ReceiptFacadeImpl`
   - Move `_riverpodService.read()` calls into providers
   - Remove `_riverpodService` field from facades
3. **Refactor FormBloc**:
   - Update `DiscountFormBloc` to accept provider values as constructor args
   - Update ServiceLocator registration to pass provider values
4. **Update Service Locator & DI**:
   - Remove RiverpodService registration from `service_locator.dart`
   - Remove RiverpodService initialization from `global_riverpod_container.dart`
5. **Delete RiverpodService**:
   - Delete `lib/app/di/riverpod_service.dart`
   - Verify no remaining imports or usages
   - Test app build and functionality

## Detailed File Changes

### `lib/app/di/global_riverpod_container.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Remove: `_initRiverpodService()` method
- Remove: Call to `RiverpodService.instance.setContainer(_container)` in `instance` getter

**Before:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/riverpod_service.dart';

class GlobalRiverpodContainer {
  static final ProviderContainer _container = ProviderContainer();

  static void _initRiverpodService() {
    RiverpodService.instance.setContainer(_container);
  }

  static ProviderContainer get instance {
    _initRiverpodService();
    return _container;
  }
  ...
}
```

**After:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalRiverpodContainer {
  static final ProviderContainer _container = ProviderContainer();

  static ProviderContainer get instance {
    return _container;
  }
  ...
}
```

### `lib/app/di/service_locator.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Remove: Registration block for RiverpodService in `init()` method

**Before:**

```dart
static void init() {
  // Register RiverpodService
  _getIt.registerLazySingleton<RiverpodService>(
    () => RiverpodService.instance,
  );

  // Register SecureStorageApi
  ...
}
```

**After:**

```dart
static void init() {
  // Register SecureStorageApi
  ...
}
```

### `lib/presentation/features/shift_screen/components/close_shift.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Remove: Line `final RiverpodService riverpodService = ServiceLocator.get<RiverpodService>();`
- Replace: `riverpodService.read(saleItemsProvider)` → `ref.read(saleItemsProvider)`
- Replace: `riverpodService.listen(...)` → `ref.listen(...)`

**Before:**

```dart
final RiverpodService riverpodService =
    ServiceLocator.get<RiverpodService>();
final saleItemsNotifier = riverpodService.read(
  saleItemsProvider.notifier,
);
```

**After:**

```dart
final saleItemsNotifier = ref.read(saleItemsProvider.notifier);
```

### `lib/presentation/features/assign_order/assign_order_dialogue.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Remove: `final _riverpodService = ServiceLocator.get<RiverpodService>();`
- Replace: All `_riverpodService.read(provider)` → `ref.read(provider)`

### `lib/presentation/features/variation_and_modifier/variation_and_modifier_dialogue.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Remove: `final RiverpodService _riverpodService = ServiceLocator.get<RiverpodService>();`
- Replace: All `_riverpodService.read(provider)` → `ref.read(provider)`

### `lib/form_bloc/discount_form_bloc.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Refactor: Instead of `ServiceLocator.get<RiverpodService>().read(saleItemsProvider)`, inject saleItemsState as constructor parameter

**Before:**

```dart
final riverpodService = ServiceLocator.get<RiverpodService>();
final saleItemsState = riverpodService.read(saleItemsProvider);
```

**After:**

```dart
// Constructor:
final SaleItemsState saleItemsState;
DiscountFormBloc({required this.saleItemsState, ...}) : super(...);

// Or if in initState of widget:
// Move to ConsumerWidget parent and pass down
```

### `lib/data/facades/sale_facade_impl.dart`

- Remove: `import 'package:mts/app/di/riverpod_service.dart';`
- Remove: `final RiverpodService _riverpodService;` field
- Remove: `required RiverpodService riverpodService` from constructor
- Remove: `_riverpodService = riverpodService,` from constructor initialization
- Remove: `riverpodService: ServiceLocator.get<RiverpodService>(),` from factory
- Replace: All `_riverpodService.read(provider)` calls with direct logic or move to providers

**Before:**

```dart
final RiverpodService _riverpodService;

SaleFacadeImpl({
  required LocalSaleRepository localRepository,
  required RiverpodService riverpodService,
  ...
}) : _riverpodService = riverpodService, ...

factory SaleFacadeImpl.fromServiceLocator() {
  return SaleFacadeImpl(
    localRepository: ServiceLocator.get<LocalSaleRepository>(),
    riverpodService: ServiceLocator.get<RiverpodService>(),
    ...
  );
}

void someMethod() {
  final saleItemsState = _riverpodService.read(saleItemsProvider);
}
```

**After:**

```dart
// Remove _riverpodService field and constructor parameter

factory SaleFacadeImpl.fromServiceLocator() {
  return SaleFacadeImpl(
    localRepository: ServiceLocator.get<LocalSaleRepository>(),
    ...
  );
}

// For methods that need saleItemsProvider data:
// Option 1: Create provider wrapper for this facade
// Option 2: Accept saleItemsState as parameter from caller
// Option 3: Keep local repositories; don't access providers
```

### `lib/data/facades/deleted_sale_item_facade_impl.dart`

- Same changes as `sale_facade_impl.dart`

### `lib/data/facades/receipt_facade_impl.dart`

- Same changes as `sale_facade_impl.dart`

## Verification Checklist

After all changes:

- [ ] No imports of `riverpod_service.dart` exist
- [ ] No references to `RiverpodService` exist in codebase
- [ ] App builds without errors: `flutter pub get && flutter build apk --debug` (or `flutter run`)
- [ ] No compilation warnings related to removed imports
- [ ] All screens that previously used RiverpodService still function correctly
- [ ] Shift open/close operations work
- [ ] Sale item modifications work
- [ ] Form bloc operations work
- [ ] All dialogs display and function correctly
- [ ] File `lib/app/di/riverpod_service.dart` is deleted

## Further Considerations

### 1. Facade dependencies on Riverpod

Do you want to:

- **Option A** (Recommended now, keep facades for Phase 3 of full migration): Keep facades as thin wrappers that call providers internally. After RiverpodService is gone, you can later convert facades themselves to providers in Phase 3.
- **Option B**: Completely eliminate facades now (combines this with facade removal). Riskier; do after RiverpodService is gone if you want to pursue full Riverpod migration.

### 2. FormBloc complexity

`DiscountFormBloc` is used in form widgets:

- If it's in a Form context with `FormBlocBuilder`, converting to Riverpod provider is complex
- Alternative: Keep FormBloc but pass provider values as constructor args (cleaner than RiverpodService hack)
- Or: Convert parent widget to `ConsumerWidget` and pass provider values down

### 3. Testing improvements

After RiverpodService removal:

- All provider access goes through `ref` in widgets or provider parameters in non-widgets
- Unit testing becomes easier: create `ProviderContainer` + override providers with mocks
- No need to manage global RiverpodService state in tests

### 4. Migration path

This change:

- **Eliminates one entire DI layer** (RiverpodService)
- **Simplifies from**: ServiceLocator → RiverpodService → providers
- **Simplifies to**: ServiceLocator → providers (or eventually just providers after Phase 1 of full migration)
- **Prepares for**: Phase 1 of full Riverpod migration where ServiceLocator itself will be replaced

## Risk Assessment

**Low Risk:**

- ConsumerStatefulWidget conversions (isolated to 3 files)
- Removal of RiverpodService initialization from DI

**Medium Risk:**

- FormBloc refactoring (depends on how tightly coupled it is)
- Facade refactoring (10+ methods using RiverpodService across 3 facades)

**Mitigation:**

- Convert widgets first (testing ground)
- Test each facade method individually after refactoring
- Have version control ready to rollback if needed
- Consider feature flag if refactoring facades to bypass them and use old path if needed

## Timeline Estimate

- **Step 1** (Convert ConsumerStatefulWidgets): 30 minutes
- **Step 2** (Refactor Facades): 1-2 hours
- **Step 3** (Refactor FormBloc): 30 minutes
- **Step 4** (Update Service Locator & DI): 15 minutes
- **Step 5** (Delete & Verify): 30 minutes
- **Testing**: 1-2 hours

**Total: 3-5 hours**
