import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/sync/sync_policy.dart';
import 'package:mts/core/sync/sync_reason.dart';
import 'package:mts/core/sync/sync_state.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/sync_check/sync_check_model.dart';
import 'package:mts/data/models/sync_check/sync_check_response_model.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secured_storage_key.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
import 'package:mts/providers/category/category_providers.dart';
import 'package:mts/providers/category_discount/category_discount_providers.dart';
import 'package:mts/providers/category_tax/category_tax_providers.dart';
import 'package:mts/providers/city/city_providers.dart';
import 'package:mts/providers/country/country_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/deleted/deleted_providers.dart';
import 'package:mts/providers/department_printer/department_printer_providers.dart';
import 'package:mts/providers/device/device_providers.dart';
import 'package:mts/providers/discount/discount_providers.dart';
import 'package:mts/providers/discount_item/discount_item_providers.dart';
import 'package:mts/providers/discount_outlet/discount_outlet_providers.dart';
import 'package:mts/providers/division/division_providers.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_providers.dart';
import 'package:mts/providers/feature/feature_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/inventory_transaction/inventory_transaction_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/item_modifier/item_modifier_providers.dart';
import 'package:mts/providers/item_representation/item_representation_providers.dart';
import 'package:mts/providers/item_tax/item_tax_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';
import 'package:mts/providers/order_option_tax/order_option_tax_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/outlet_payment_type/outlet_payment_type_providers.dart';
import 'package:mts/providers/outlet_tax/outlet_tax_providers.dart';
import 'package:mts/providers/page/page_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';
import 'package:mts/providers/pending_changes/pending_changes_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/sale_variant_option/sale_variant_option_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';
import 'package:mts/providers/supplier/supplier_providers.dart';
import 'package:mts/providers/table/table_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/table_section/table_section_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';
import 'package:mts/providers/timecard/timecard_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// Manages application sync with granular progress tracking and concurrency control
class AppSyncService extends StateNotifier<SyncState> {
  final Ref ref;
  final SecureStorageApi _secureStorageApi;
  final SyncRepository _syncRepository;
  final IWebService _webService;

  late final Map<String, Future<void> Function()> _syncRegistry;

  // Concurrent task management (similar to sync_real_time)
  static const int _maxConcurrentTasks = isolateMaxConcurrent;
  int _currentConcurrentTasks = 0;
  final List<_PendingSyncTask> _pendingSyncTasks = [];

  AppSyncService({
    required this.ref,
    required SecureStorageApi secureStorageApi,
    required SyncRepository syncRepository,
    required IWebService webService,
  }) : _secureStorageApi = secureStorageApi,
       _syncRepository = syncRepository,
       _webService = webService,
       super(const SyncState()) {
    _syncRegistry = {
      // Core data
      'items': () => ref.read(itemProvider.notifier).syncFromRemote(),
      'categories': () => ref.read(categoryProvider.notifier).syncFromRemote(),
      'pages': () => ref.read(pageProvider.notifier).syncFromRemote(),
      'pageItems': () => ref.read(pageItemProvider.notifier).syncFromRemote(),
      'itemRepresentation':
          () => ref.read(itemRepresentationProvider.notifier).syncFromRemote(),

      // Modifiers
      'modifiers': () => ref.read(modifierProvider.notifier).syncFromRemote(),
      'itemModifiers':
          () => ref.read(itemModifierProvider.notifier).syncFromRemote(),
      'modifierOptions':
          () => ref.read(modifierOptionProvider.notifier).syncFromRemote(),

      // Taxes & Discounts
      'taxes': () => ref.read(taxProvider.notifier).syncFromRemote(),
      'itemTaxes': () => ref.read(itemTaxProvider.notifier).syncFromRemote(),
      'categoryTaxes':
          () => ref.read(categoryTaxProvider.notifier).syncFromRemote(),
      'orderOptionTaxes':
          () => ref.read(orderOptionTaxProvider.notifier).syncFromRemote(),
      'outletTaxes':
          () => ref.read(outletTaxProvider.notifier).syncFromRemote(),
      'discounts': () => ref.read(discountProvider.notifier).syncFromRemote(),
      'discountItems':
          () => ref.read(discountItemProvider.notifier).syncFromRemote(),
      'categoryDiscounts':
          () => ref.read(categoryDiscountProvider.notifier).syncFromRemote(),
      'discountOutlets':
          () => ref.read(discountOutletProvider.notifier).syncFromRemote(),

      // Tables & Layout
      'tableLayout':
          () => ref.read(tableLayoutProvider.notifier).syncFromRemote(),
      'tables': () => ref.read(tableProvider.notifier).syncFromRemote(),
      'tableSections':
          () => ref.read(tableSectionProvider.notifier).syncFromRemote(),

      // Orders & Sales
      'orderOptions':
          () => ref.read(orderOptionProvider.notifier).syncFromRemote(),
      'predefinedOrders':
          () => ref.read(predefinedOrderProvider.notifier).syncFromRemote(),
      'sales': () => ref.read(saleProvider.notifier).syncFromRemote(),
      'saleItems': () => ref.read(saleItemProvider.notifier).syncFromRemote(),
      'saleModifiers':
          () => ref.read(saleModifierProvider.notifier).syncFromRemote(),
      'saleModifierOptions':
          () => ref.read(saleModifierOptionProvider.notifier).syncFromRemote(),
      'saleVariantOptions':
          () => ref.read(saleVariantOptionProvider.notifier).syncFromRemote(),

      // Receipts
      'receipts': () => ref.read(receiptProvider.notifier).syncFromRemote(),
      'receiptItems':
          () => ref.read(receiptItemProvider.notifier).syncFromRemote(),
      'receiptSettings':
          () => ref.read(receiptSettingsProvider.notifier).syncFromRemote(),

      // Users & Staff
      'users': () => ref.read(userProvider.notifier).syncFromRemote(),
      'staff': () => ref.read(staffProvider.notifier).syncFromRemote(),
      'customers': () => ref.read(customerProvider.notifier).syncFromRemote(),
      'permissions':
          () => ref.read(permissionProvider.notifier).syncFromRemote(),

      // Outlets & Devices
      'outlets': () => ref.read(outletProvider.notifier).syncFromRemote(),
      'devices': () => ref.read(deviceProvider.notifier).syncFromRemote(),
      'printers':
          () => ref.read(printerSettingProvider.notifier).syncFromRemote(),
      'departmentPrinters':
          () => ref.read(departmentPrinterProvider.notifier).syncFromRemote(),

      // Payment
      'paymentTypes':
          () => ref.read(paymentTypeProvider.notifier).syncFromRemote(),
      'outletPaymentTypes':
          () => ref.read(outletPaymentTypeProvider.notifier).syncFromRemote(),

      // Features & Settings
      'features': () => ref.read(featureProvider.notifier).syncFromRemote(),
      'featureCompanies':
          () => ref.read(featureCompanyProvider.notifier).syncFromRemote(),

      // Cash & Shifts
      'cashManagement':
          () => ref.read(cashManagementProvider.notifier).syncFromRemote(),
      'shifts': () => ref.read(shiftProvider.notifier).syncFromRemote(),
      'timecards': () => ref.read(timecardProvider.notifier).syncFromRemote(),

      // Media
      'slideshow': () => ref.read(slideshowProvider.notifier).syncFromRemote(),
      'downloadedFiles':
          () => ref.read(downloadedFileProvider.notifier).syncFromRemote(),

      // Geography
      'cities': () => ref.read(cityProvider.notifier).syncFromRemote(),
      'countries': () => ref.read(countryProvider.notifier).syncFromRemote(),
      'divisions': () => ref.read(divisionProvider.notifier).syncFromRemote(),

      // Inventory
      'inventory': () => ref.read(inventoryProvider.notifier).syncFromRemote(),
      'inventoryTransactions':
          () =>
              ref.read(inventoryTransactionProvider.notifier).syncFromRemote(),
      'suppliers': () => ref.read(supplierProvider.notifier).syncFromRemote(),

      // Print cache
      'printReceiptCache':
          () => ref.read(printReceiptCacheProvider.notifier).syncFromRemote(),

      // Deleted items tracking
      'deleted': () => ref.read(deletedProvider.notifier).syncFromRemote(),

      // Sync tracking
      'pendingChanges':
          () => ref.read(pendingChangesProvider.notifier).syncFromRemote(),
    };
  }

  Future<void> hydrateSession() async {
    // 1️⃣ ALWAYS load local first
    await Future.wait([
      ref.read(itemRepresentationProvider.notifier).loadFromLocal(),
    ]);
  }

  /// Main sync method - handles pending changes, sync checks, and entity syncing
  ///
  /// Features from sync_real_time:
  /// - Syncs pending changes first
  /// - Checks for server changes before syncing
  /// - Handles deleted items
  /// - Supports concurrency limiting
  /// - Progress tracking for each entity
  Future<void> syncAll({
    SyncReason reason = SyncReason.manualRefresh,
    BuildContext? context,
    bool needToDownloadImage = false,
    bool onlyCheckPendingChanges = false,
    bool isForce = false,
  }) async {
    if (!await NetworkUtils.hasInternetConnection()) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'No internet connection',
      );
      return;
    }

    state = SyncState(isSyncing: true, progress: 0.0);

    final failedOperations = <String>[];

    try {
      // Step 1: Sync pending changes first (critical - must happen before remote sync)
      prints('🔄 Step 1: Syncing pending changes...');
      state = state.copyWith(progress: 0.0);

      // Delete invalid pending changes
      final deleteWhereModelIdNull =
          await ref
              .read(pendingChangesProvider.notifier)
              .deleteWhereModelIdIsNull();
      prints('✅ Deleted where model_id is null: $deleteWhereModelIdNull');

      bool pendingChangesResult = false;
      try {
        pendingChangesResult = await ref
            .read(pendingChangesProvider.notifier)
            .syncPendingChangesList()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                prints('⚠️ Sync pending changes timed out after 30 seconds');
                return false;
              },
            );
      } catch (e) {
        prints('❌ Error syncing pending changes: $e');
        pendingChangesResult = false;
      }

      if (!pendingChangesResult) {
        final pcCount =
            (await ref
                    .read(pendingChangesProvider.notifier)
                    .getListPendingChanges())
                .length;
        failedOperations.add('Failed to sync $pcCount pending changes');

        state = state.copyWith(
          isSyncing: false,
          progress: 1.0,
          errorMessage: failedOperations.join(', '),
        );
        return;
      }

      // If only checking pending changes, stop here
      if (onlyCheckPendingChanges) {
        state = state.copyWith(
          isSyncing: false,
          progress: 1.0,
          errorMessage:
              failedOperations.isEmpty ? null : failedOperations.join(', '),
        );
        return;
      }

      // Step 2: Get deleted items
      prints('🔄 Step 2: Fetching deleted items...');
      state = state.copyWith(progress: 0.03);

      if (reason != SyncReason.licenseKeySuccess) {
        await ref.read(deletedProvider.notifier).syncFromRemote();
      }

      // Step 3: Check which models need syncing
      prints('🔄 Step 3: Checking which models need syncing...');
      state = state.copyWith(progress: 0.045);

      // Always use sync check - force it for license activation or manual force
      final shouldForceSync = isForce || reason == SyncReason.licenseKeySuccess;
      final syncCheckModel =
          shouldForceSync
              ? await _forceCheckModelsToSync()
              : await _checkModelsToSync();

      if (syncCheckModel.changesDetected != null &&
          !syncCheckModel.changesDetected!) {
        prints('ℹ️ No changes detected on the server');
        state = state.copyWith(isSyncing: false, progress: 1.0);
        return;
      }

      // Step 4: Sync entities based on policy and sync check
      prints('🔄 Step 4: Syncing entities...');
      final modelsToSync = syncCheckModel.modelsToSync ?? [];

      await _syncSelectedModels(
        modelsToSync: modelsToSync,
        reason: reason,
        needToDownloadImage: needToDownloadImage,
        failedOperations: failedOperations,
      );

      // Step 5: Complete
      prints(
        failedOperations.isEmpty
            ? '✅ Sync completed successfully'
            : '⚠️ Sync completed with errors',
      );

      state = state.copyWith(
        isSyncing: false,
        progress: 1.0,
        errorMessage:
            failedOperations.isEmpty ? null : failedOperations.join(', '),
      );
    } catch (e, stackTrace) {
      prints('❌ Sync error: $e');
      LogUtils.error('Sync error: $e\n$stackTrace');

      state = state.copyWith(isSyncing: false, errorMessage: 'Sync error: $e');
    }
  }

  /// Check which models need syncing from server
  Future<SyncCheckModel> _checkModelsToSync() async {
    try {
      Map<String, dynamic> data = {};
      for (String key in SSKey.allKeys) {
        data[key] = DateTimeUtils.formatToISO8601(
          await SyncService.getLastSyncTime(key),
        );
      }

      SyncCheckResponseModel response = await _webService.post(
        _syncRepository.syncCheck(data: data),
      );

      prints(
        '🔍 SyncCheck response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}',
      );

      if (response.isSuccess && response.data != null) {
        prints(
          'Models to sync: ${response.data!.modelsToSync!.map((model) => model).join(', ')}',
        );
        return response.data!;
      } else {
        prints(
          '❌ SyncCheck failed - message: ${response.message}, statusCode: ${response.statusCode}',
        );
        throw Exception(response.message);
      }
    } catch (e) {
      prints('🚨 SyncCheck threw exception: $e');
      rethrow;
    }
  }

  /// Force check all models (uses old date to force sync)
  Future<SyncCheckModel> _forceCheckModelsToSync() async {
    try {
      Map<String, dynamic> data = {};
      for (String key in SSKey.allKeys) {
        data[key] = DateTimeUtils.formatToISO8601(DateTime.parse("2000-01-01"));
      }

      SyncCheckResponseModel response = await _webService.post(
        _syncRepository.syncCheck(data: data),
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      prints('🚨 Force SyncCheck threw exception: $e');
      rethrow;
    }
  }

  /// Sync selected models with concurrency control and progress tracking
  Future<void> _syncSelectedModels({
    required List<String> modelsToSync,
    required SyncReason reason,
    required bool needToDownloadImage,
    required List<String> failedOperations,
  }) async {
    if (modelsToSync.isEmpty) {
      prints('ℹ️ No models to sync');
      return;
    }

    // Get policy to respect sync settings
    final policy = SyncPolicy.forReason(reason);
    final policyMap = policy.toMap();

    // Filter models based on policy and sync check
    final entitiesToSync = <String, SyncEntityState>{};
    for (final modelName in modelsToSync) {
      // Only sync if both policy allows it AND server says it needs syncing
      if (policyMap[modelName] == true) {
        entitiesToSync[modelName] = SyncEntityState(
          isLoading: true,
          startedAt: DateTime.now(),
        );
      }
    }

    if (entitiesToSync.isEmpty) {
      prints('ℹ️ No entities match policy');
      return;
    }

    state = state.copyWith(entities: entitiesToSync, progress: 0.05);

    final totalEntities = entitiesToSync.length;
    var completedCount = 0;

    // Sync entities with concurrency control
    final futures = <Future>[];
    for (final entry in entitiesToSync.entries) {
      final entityName = entry.key;
      final syncFn = _syncRegistry[entityName];

      if (syncFn != null) {
        futures.add(
          _executeSyncWithConcurrencyLimit(
            entityName: entityName,
            syncFunction: syncFn,
            onComplete: () {
              completedCount++;
              final progress = 0.05 + (completedCount / totalEntities) * 0.95;

              final updatedEntities = Map<String, SyncEntityState>.from(
                state.entities,
              );
              updatedEntities[entityName] = SyncEntityState(
                isDone: true,
                startedAt: state.entities[entityName]?.startedAt,
                completedAt: DateTime.now(),
              );

              state = state.copyWith(
                entities: updatedEntities,
                progress: progress,
              );

              prints(
                '✅ Completed $entityName ($completedCount/$totalEntities)',
              );
            },
            onError: (error) {
              completedCount++;
              final progress = 0.05 + (completedCount / totalEntities) * 0.95;

              final updatedEntities = Map<String, SyncEntityState>.from(
                state.entities,
              );
              updatedEntities[entityName] = SyncEntityState(
                error: error.toString(),
                startedAt: state.entities[entityName]?.startedAt,
                completedAt: DateTime.now(),
              );

              state = state.copyWith(
                entities: updatedEntities,
                progress: progress,
              );

              failedOperations.add('$entityName: $error');
              prints('❌ Failed $entityName: $error');
            },
          ),
        );
      } else {
        prints('⚠️ No sync function found for $entityName');
      }
    }

    await Future.wait(futures);
  }

  /// Execute sync with concurrency limit (similar to sync_real_time logic)
  Future<void> _executeSyncWithConcurrencyLimit({
    required String entityName,
    required Future<void> Function() syncFunction,
    required VoidCallback onComplete,
    required void Function(dynamic error) onError,
  }) async {
    // Queue the task if we've hit the max concurrent limit
    if (_currentConcurrentTasks >= _maxConcurrentTasks) {
      final completer = Completer<void>();
      _pendingSyncTasks.add(
        _PendingSyncTask(
          executionFunction:
              () => _executeSync(
                entityName: entityName,
                syncFunction: syncFunction,
                onComplete: onComplete,
                onError: onError,
              ),
          completer: completer,
        ),
      );
      return completer.future;
    }

    _currentConcurrentTasks++;

    try {
      await _executeSync(
        entityName: entityName,
        syncFunction: syncFunction,
        onComplete: onComplete,
        onError: onError,
      );
    } finally {
      _currentConcurrentTasks--;
      _processPendingSyncTasks();
    }
  }

  /// Execute the actual sync
  Future<void> _executeSync({
    required String entityName,
    required Future<void> Function() syncFunction,
    required VoidCallback onComplete,
    required void Function(dynamic error) onError,
  }) async {
    try {
      await syncFunction();
      onComplete();
    } catch (e) {
      onError(e);
    }
  }

  /// Process pending sync tasks from queue
  void _processPendingSyncTasks() {
    while (_pendingSyncTasks.isNotEmpty &&
        _currentConcurrentTasks < _maxConcurrentTasks) {
      final task = _pendingSyncTasks.removeAt(0);
      _currentConcurrentTasks++;

      unawaited(
        task
            .execute()
            .then((_) {
              _currentConcurrentTasks--;
              task.completer.complete();
              _processPendingSyncTasks();
            })
            .catchError((e) {
              _currentConcurrentTasks--;
              task.completer.completeError(e);
              _processPendingSyncTasks();
            }),
      );
    }
  }
}

/// Pending sync task for concurrency control
class _PendingSyncTask {
  final Future<void> Function() executionFunction;
  final Completer<void> completer;

  _PendingSyncTask({required this.executionFunction, required this.completer});

  Future<void> execute() => executionFunction();
}

/// Provider for the sync service
final appSyncServiceProvider = StateNotifierProvider<AppSyncService, SyncState>(
  (ref) {
    return AppSyncService(
      ref: ref,
      secureStorageApi: ref.read(secureStorageApiProvider),
      syncRepository: ServiceLocator.get<SyncRepository>(),
      webService: ServiceLocator.get<IWebService>(),
    );
  },
);
