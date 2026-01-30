import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secured_storage_key.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/models/sync_check/sync_check_response_model.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';
import 'package:mts/providers/sync_real_time/sync_real_time_state.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/data/models/deleted/deleted_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/supplier/supplier_model.dart';
import 'package:mts/data/models/sync_check/sync_check_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/repositories/local/local_cash_management_repository_impl.dart';
import 'package:mts/data/repositories/local/local_category_repository_impl.dart';
import 'package:mts/data/repositories/local/local_division_repository_impl.dart';
import 'package:mts/data/repositories/local/local_customer_repository_impl.dart';
import 'package:mts/data/repositories/local/local_department_printer_repository_impl.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_repository_impl.dart';
import 'package:mts/data/repositories/local/local_downloaded_file_repository_impl.dart';
import 'package:mts/data/repositories/local/local_error_log_repository_impl.dart';
import 'package:mts/data/repositories/local/local_feature_company_repository_impl.dart';
import 'package:mts/data/repositories/local/local_feature_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_representation_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_inventory_repository_impl.dart';
import 'package:mts/data/repositories/local/local_inventory_transaction_repository_impl.dart';
import 'package:mts/data/repositories/local/local_modifier_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_order_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_order_option_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_payment_type_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_page_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_page_repository_impl.dart';
import 'package:mts/data/repositories/local/local_payment_type_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_permission_repository_impl.dart';
import 'package:mts/data/repositories/local/local_predefined_order_repository_impl.dart';
import 'package:mts/data/repositories/local/local_printer_setting_repository_impl.dart';
import 'package:mts/data/repositories/local/local_receipt_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_receipt_repository_impl.dart';
import 'package:mts/data/repositories/local/local_receipt_settings_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_modifier_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_variant_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/data/repositories/local/local_slideshow_repository_impl.dart';
import 'package:mts/data/repositories/local/local_staff_repository_impl.dart';
import 'package:mts/data/repositories/local/local_supplier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_table_repository_impl.dart';
import 'package:mts/data/repositories/local/local_table_section_repository_impl.dart';
import 'package:mts/data/repositories/local/local_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_timecard_repository_impl.dart';
import 'package:mts/data/repositories/local/local_user_repository_impl.dart';
import 'package:mts/domain/services/media/asset_download_service.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
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
import 'package:mts/providers/error_log/error_log_providers.dart';
import 'package:mts/providers/feature/feature_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/inventory_transaction/inventory_transaction_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/item_modifier/item_modifier_providers.dart';
import 'package:mts/providers/item_representation/item_representation_providers.dart';
import 'package:mts/providers/item_tax/item_tax_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';
import 'package:mts/providers/category/category_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
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

class SyncRealTimeNotifier extends StateNotifier<SyncRealTimeState> {
  final Ref _ref;
  final SecureStorageApi _secureStorageApi;
  final SyncRepository _syncRepository;
  final IWebService _webService;

  // Concurrent task management
  static const int _maxConcurrentTasks = isolateMaxConcurrent;
  static int _currentConcurrentTasks = 0;
  static final List<_PendingFetchTask> _pendingFetchTasks = [];

  final NotifierUpdateThrottler _notifierThrottler = NotifierUpdateThrottler();

  SyncRealTimeNotifier({
    required Ref ref,
    required SecureStorageApi secureStorageApi,
    required SyncRepository syncRepository,
    required IWebService webService,
  }) : _ref = ref,
       _secureStorageApi = secureStorageApi,
       _syncRepository = syncRepository,
       _webService = webService,
       super(const SyncRealTimeState());

  /// Generic method to fetch and insert data
  ///
  /// This method handles the common pattern of fetching data from an API and inserting it into the database
  /// with concurrent task limiting (max 4 concurrent tasks)
  ///
  /// Parameters:
  /// - [entityName]: Name of the entity being synced (for logging)
  /// - [fetchFunction]: Function that fetches data from the API
  /// - [insertFunction]: Function that inserts data into the database
  ///
  /// Returns a Future<bool> indicating success or failure
  /// ✅ FIXED: Optimized method to fetch and insert data with background processing
  /// ✅ FIXED: Limited concurrent isolates to max 4
  Future<bool> _fetchAndInsertData<T>(
    String entityName,
    Future<List<T>> Function() fetchFunction,
    Future<bool> Function(List<T>, {bool isInsertToPending, bool isQueue})
    insertFunction,
    String facadeType, {
    bool needToDownloadImage = false,
  }) async {
    // Queue the task if we've hit the max concurrent limit
    if (_currentConcurrentTasks >= _maxConcurrentTasks) {
      final completer = Completer<bool>();
      _pendingFetchTasks.add(
        _PendingFetchTask(
          executionFunction:
              () => _executeFetchAndInsertData<T>(
                entityName,
                fetchFunction,
                insertFunction,
                facadeType,
                needToDownloadImage: needToDownloadImage,
              ),
          completer: completer,
        ),
      );
      // Wait for this task to be executed from queue
      return completer.future;
    }

    _currentConcurrentTasks++;

    try {
      return await _executeFetchAndInsertData<T>(
        entityName,
        fetchFunction,
        insertFunction,
        facadeType,
        needToDownloadImage: needToDownloadImage,
      );
    } finally {
      _currentConcurrentTasks--;
      // Process any pending tasks
      _processPendingFetchTasks();
    }
  }

  /// Internal method that executes the fetch and insert operation
  Future<bool> _executeFetchAndInsertData<T>(
    String entityName,
    Future<List<T>> Function() fetchFunction,
    Future<bool> Function(List<T>, {bool isInsertToPending, bool isQueue})
    insertFunction,
    String facadeType, {
    bool needToDownloadImage = false,
  }) async {
    try {
      prints('Fetching $entityName');

      final List<T> items = await fetchFunction();

      if (items.isNotEmpty) {
        bool isQueue =
            (items is! List<ItemModel>) &&
            (items is! List<ItemRepresentationModel>) &&
            (items is! List<ReceiptModel>) &&
            (items is! List<ReceiptItemModel>) &&
            (items is! List<UserModel>) &&
            (items is! List<StaffModel>);
        await insertFunction(items, isInsertToPending: false, isQueue: isQueue);

        _notifierThrottler.scheduleUpdate(() {
          _updateNotifiersOnMainThread(items, facadeType);
        });

        if (needToDownloadImage) {
          final assetService = _ref.read(assetDownloadServiceProvider);
          await assetService.downloadPendingAssets();

          if (items is List<ItemRepresentationModel>) {
            final listItemsRep = items as List<ItemRepresentationModel>;
            await _ref
                .read(itemRepresentationProvider.notifier)
                .upsertBulk(listItemsRep, isInsertToPending: false);
          }
        }

        prints('Successfully synced $entityName: ${items.length} items');
      } else {
        prints('No $entityName returned from API');
      }

      MetaModel metaModel = MetaModel(lastSync: DateTime.now().toUtc());
      _secureStorageApi.saveObject(facadeType, metaModel);

      return true;
    } catch (e) {
      prints('Error fetching $entityName: $e');
      return false;
    }
  }

  /// Process pending fetch tasks from queue
  static void _processPendingFetchTasks() {
    while (_pendingFetchTasks.isNotEmpty &&
        _currentConcurrentTasks < _maxConcurrentTasks) {
      final task = _pendingFetchTasks.removeAt(0);
      _currentConcurrentTasks++;

      // Execute the pending task asynchronously
      unawaited(
        task
            .execute()
            .then((result) {
              _currentConcurrentTasks--;
              task.completer.complete(result);
              _processPendingFetchTasks();
            })
            .catchError((e) {
              _currentConcurrentTasks--;
              task.completer.completeError(e);
              _processPendingFetchTasks();
            }),
      );
    }
  }

  void _updateNotifiersOnMainThread<T>(List<T> items, String facadeType) {
    try {
      switch (facadeType) {
        case ItemRepresentationModel.modelName:
          // ServiceLocator.get<ItemNotifier>().addOrUpdateListIR(
          //   items as List<ItemRepresentationModel>,
          // );

          // no need to call, because already call upsert in _processDataInBackground
          break;
        case ItemModel.modelName:
          ServiceLocator.get<ItemNotifier>().initializeForSecondScreen(
            items as List<ItemModel>,
          );

          break;
        case CategoryModel.modelName:
          // ServiceLocator.get<CategoryNotifier>().addOrUpdateList(
          //   items as List<CategoryModel>,
          // );
          // no need to call, because already call upsert in _processDataInBackground
          break;
        case PaymentTypeModel.modelName:
          break;
        case OrderOptionModel.modelName:
          List<OrderOptionModel> orderOptions = items as List<OrderOptionModel>;
          if (orderOptions.isNotEmpty) {
            _ref
                .read(saleItemProvider.notifier)
                .setOrderOptionModel(orderOptions.first);
          }
          break;
        case PageModel.modelName:
          final pageItems = items as List<PageModel>;

          if (pageItems.isNotEmpty) {
            final pageItemNotifier = ServiceLocator.get<PageItemNotifier>();
            pageItemNotifier.setCurrentPageId(pageItems.first.id);
            pageItemNotifier.setLastPageId(pageItems.first.id!);
          }

          break;
        case PageItemModel.modelName:
          break;

        case ItemModifierModel.modelName:
          ServiceLocator.get<ItemModifierNotifier>().addOrUpdateList(
            items as List<ItemModifierModel>,
          );
          break;

        case TaxModel.modelName:
          ServiceLocator.get<TaxNotifier>().addOrUpdateList(
            items as List<TaxModel>,
          );
          break;
        case ItemTaxModel.modelName:
          ServiceLocator.get<ItemTaxNotifier>().addOrUpdateList(
            items as List<ItemTaxModel>,
          );
          break;

        case OutletTaxModel.modelName:
          ServiceLocator.get<OutletTaxNotifier>().addOrUpdateList(
            items as List<OutletTaxModel>,
          );
          break;
        case OrderOptionTaxModel.modelName:
          ServiceLocator.get<OrderOptionTaxNotifier>().addOrUpdateList(
            items as List<OrderOptionTaxModel>,
          );
          break;
        case ModifierModel.modelName:
          final modifierNotifier = ServiceLocator.get<ModifierNotifier>();

          _ref
              .read(saleItemProvider.notifier)
              .addOrUpdateModifierList(modifierNotifier.getListModifiers());
          break;
        case ModifierOptionModel.modelName:
          final modifierOptionItems = items as List<ModifierOptionModel>;
          final modifierOptionNotifier =
              ServiceLocator.get<ModifierOptionNotifier>();

          modifierOptionNotifier.initializeForSecondScreen(
            modifierOptionItems,
            reInitializeCache: true,
          );
          _ref
              .read(saleItemProvider.notifier)
              .addOrUpdateModifierOptionList(
                modifierOptionNotifier.getModifierOptionList,
              );
          break;
        case DiscountModel.modelName:
          ServiceLocator.get<DiscountNotifier>().addOrUpdateList(
            items as List<DiscountModel>,
          );
          break;
        case DiscountItemModel.modelName:
          ServiceLocator.get<DiscountItemNotifier>().addOrUpdateList(
            items as List<DiscountItemModel>,
          );
          break;
        case DiscountOutletModel.modelName:
          ServiceLocator.get<DiscountOutletNotifier>().addOrUpdateList(
            items as List<DiscountOutletModel>,
          );
          break;
        case StaffModel.modelName:
          break;
        case UserModel.modelName:
          UserModel currentUser = ServiceLocator.get<UserModel>();
          PermissionNotifier permissionNotifier =
              ServiceLocator.get<PermissionNotifier>();
          List<UserModel> incomingUsers = items as List<UserModel>;
          for (UserModel user in incomingUsers) {
            if (currentUser.id == user.id) {
              permissionNotifier.assignStaffPermission(user, false);
            }
          }
          // ServiceLocator.get<UserNotifier>().addOrUpdateList(
          //   items as List<UserModel>,
          // );
          break;
        case PermissionModel.modelName:
          break;
        case PrintReceiptCacheModel.modelName:
          ServiceLocator.get<PrintReceiptCacheNotifier>()
              .setListPrintReceiptCache(items as List<PrintReceiptCacheModel>);
          break;
        case FeatureModel.modelName:
          ServiceLocator.get<FeatureNotifier>().addOrUpdateList(
            items as List<FeatureModel>,
          );
          break;
        case FeatureCompanyModel.modelName:
          ServiceLocator.get<FeatureCompanyNotifier>().addOrUpdateList(
            items as List<FeatureCompanyModel>,
          );
          break;
        case CustomerModel.modelName:
          // ServiceLocator.get<CustomerNotifier>().addOrUpdateList(
          //   items as List<CustomerModel>,
          // );
          break;
        case SupplierModel.modelName:
          ServiceLocator.get<SupplierNotifier>().addOrUpdateList(
            items as List<SupplierModel>,
          );
          break;
        case TableModel.modelName:
          _ref
              .read(tableLayoutProvider.notifier)
              .addOrUpdateListTable(items as List<TableModel>);
          break;
        case TableSectionModel.modelName:
          _ref
              .read(tableLayoutProvider.notifier)
              .addOrUpdateListSections(items as List<TableSectionModel>);
          break;
        case PosDeviceModel.modelName:
          break;
        case SaleModel.modelName:
          break;
        case OutletModel.modelName:
          ServiceLocator.get<OutletNotifier>().addOrUpdateList(
            items as List<OutletModel>,
          );
          break;

        case OutletPaymentTypeModel.modelName:
          ServiceLocator.get<OutletPaymentTypeNotifier>().addOrUpdateList(
            items as List<OutletPaymentTypeModel>,
          );
          break;
        // Add other cases as needed
        default:
          prints('No notifier update defined for $facadeType');
          break;
      }
    } catch (e) {
      prints('Error updating notifiers for $facadeType: $e');
    }
  }

  Future<void> seedingProcess(
    String executeName,
    Function(bool p1) isLoading, {
    required bool needToDownloadImage,
    bool isInitData = false,
  }) async {
    var logger = Logger(printer: PrettyPrinter());

    isLoading(true);
    // await HiveInitHelper.initializeAllBoxes();

    // Start continuous background sync from Hive to SQLite
    // This runs every 500ms to sync cached data without blocking UI
    // await HiveSyncHelper.startContinuousSync();
    bool results = false;

    // Check if there are any new tables to create
    prints("SEBELUM GET ALL SHIFT");
    await _secureStorageApi.checkAccessToken();

    List<ShiftModel> listShift =
        await _ref.read(shiftProvider.notifier).syncFromRemote();

    prints("SELEPAS GET ALL SHIFT");
    await _secureStorageApi.checkAccessToken();
    if (listShift.isEmpty) {
      prints('NO SHIFT');
      await onSyncOrder(
        null,
        false,
        manuallyClick: false,
        isSuccess: (isSuccess, errorMessage) async {
          results = isSuccess;
        },
        isAfterActivateLicense: true,
        needToDownloadImage: needToDownloadImage,
        onlyCheckPendingChanges: false,
      );
    } else {
      // when have shift
      prints('✅✅✅✅✅ HAVE SHIFTS $isInitData');
      await onSyncOrder(
        null,
        false,
        manuallyClick: false,
        isSuccess: (isSuccess, errorMessage) async {
          results = isSuccess;
        },
        isAfterActivateLicense: isInitData,
        needToDownloadImage: needToDownloadImage,
        onlyCheckPendingChanges: false,
      );
    }

    if (results) {
      logger.i('DONE SEEDING');
    } else {
      logger.e('FAIL SEEDING', 'Seeding failed while executing $executeName');
      LogUtils.error(
        'Fail SEEDING Seeding failed while executing $executeName',
      );
    }

    isLoading(false);
  }

  /// Checks if the database has new tables by comparing the tables from the device
  /// with the list of tables from the _createTables method in DatabaseHelpers.
  ///
  /// Returns a map containing:
  /// - hasNewTables: Boolean indicating if there are new tables to be created
  /// - missingTables: List of table names that are missing from the device database
  /// - existingTables: List of table names that already exist in the device database

  Future<Map<String, dynamic>> checkForNewTables() async {
    prints('Checking for new tables in the database');

    // Get a database instance
    final db = await ServiceLocator.get<IDatabaseHelpers>().database;

    // Get all existing table names from the device database
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );

    // Extract table names from the query result
    final existingTables =
        tables.map((table) => table['name'] as String).toList();

    // Define the expected tables based on the _createTables method in DatabaseHelpers
    // This list should match the tables created in DatabaseHelpers._createTables
    final expectedTables = [
      // downloaded files
      LocalDownloadedFileRepositoryImpl.tableName,
      // error logs
      LocalErrorLogRepositoryImpl.tableName,

      // Pending changes
      LocalPendingChangesRepositoryImpl.tableName,
      // Cash management
      LocalCashManagementRepositoryImpl.tableName, //
      // Features
      LocalFeatureRepositoryImpl.tableName, //
      LocalFeatureCompanyRepositoryImpl.tableName, //
      // Categories
      LocalCategoryRepositoryImpl.tableName, //
      // Customers
      LocalCustomerRepositoryImpl.tableName, //
      // Divisions
      LocalDivisionRepositoryImpl.tableName, //
      // Discounts
      LocalDiscountRepositoryImpl.tableName, //
      LocalDiscountItemRepositoryImpl.tableName, //
      // Items and related tables
      LocalItemRepositoryImpl.tableName, //
      LocalItemRepresentationRepositoryImpl.tableName, //
      LocalItemTaxRepositoryImpl.tableName, //
      LocalOrderOptionTaxRepositoryImpl.tableName,
      LocalItemModifierRepositoryImpl.tableName, //
      LocalInventoryRepositoryImpl.tableName, //
      LocalInventoryTransactionRepositoryImpl.tableName, //
      // Modifiers
      LocalModifierRepositoryImpl.tableName, //
      LocalModifierOptionRepositoryImpl.tableName, //
      // Order options
      LocalOrderOptionRepositoryImpl.tableName, //
      // Pages
      LocalPageRepositoryImpl.tableName, //
      LocalPageItemRepositoryImpl.tableName, //
      // Payments
      LocalPaymentTypeRepositoryImpl.tableName, //
      LocalOutletPaymentTypeRepositoryImpl.tableName, //
      // Predefined orders
      LocalPredefinedOrderRepositoryImpl.tableName, //
      // Printers
      LocalPrinterSettingRepositoryImpl.tableName, //
      LocalDepartmentPrinterRepositoryImpl.tableName, //
      // Receipts
      LocalReceiptRepositoryImpl.tableName, //
      LocalReceiptItemRepositoryImpl.tableName, //
      LocalReceiptSettingsRepositoryImpl.tableName, //
      // Sales
      LocalSaleRepositoryImpl.tableName, //
      LocalSaleItemRepositoryImpl.tableName, //
      LocalSaleModifierRepositoryImpl.tableName, //
      LocalSaleModifierOptionRepositoryImpl.tableName, //
      LocalSaleVariantOptionRepositoryImpl.tableName,

      // Staff and users
      LocalStaffRepositoryImpl.tableName, //
      LocalUserRepositoryImpl.tableName, //
      LocalPermissionRepositoryImpl.tableName,
      // Suppliers
      LocalSupplierRepositoryImpl.tableName,

      // Taxes
      LocalTaxRepositoryImpl.tableName, //
      // Outlet and devices
      LocalOutletRepositoryImpl.tableName, //
      LocalDeviceRepositoryImpl.tableName, //
      // Shifts and timecards
      LocalShiftRepositoryImpl.tableName, //
      LocalTimecardRepositoryImpl.tableName, //
      // Display
      LocalSlideshowRepositoryImpl.tableName,

      // Tables
      LocalTableRepositoryImpl.tableName, //
      LocalTableSectionRepositoryImpl.tableName, //

      LocalInventoryRepositoryImpl.tableName,
      LocalInventoryTransactionRepositoryImpl.tableName,
      LocalSupplierRepositoryImpl.tableName,
    ];

    // Find tables that are expected but don't exist in the database
    final missingTables =
        expectedTables
            .where((table) => !existingTables.contains(table))
            .toList();

    // Log the results
    LogUtils.info('Existing tables: ${existingTables.join(', ')}');
    LogUtils.info('Missing tables: ${missingTables.join(', ')}');

    return {
      'hasNewTables': missingTables.isNotEmpty,
      'missingTables': missingTables,
      'existingTables': existingTables,
    };
  }

  /// Creates sync futures for only the models specified in [modelsToSync]
  List<Future<bool>> _createSelectiveSyncFutures(
    List<String> modelsToSync,
    bool needToDownloadImage,
  ) {
    final List<Future<bool>> futures = [];

    // Map model names to their corresponding sync futures
    final modelMap = {
      ItemRepresentationModel.modelName:
          () => _fetchAndInsertData<ItemRepresentationModel>(
            'Item Representations',
            () =>
                _ref
                    .read(itemRepresentationProvider.notifier)
                    .getAllItemRepresentationsFromAPIWithPagination(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(itemRepresentationProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ItemRepresentationModel.modelName,
            needToDownloadImage: needToDownloadImage,
          ),
      OrderOptionModel.modelName:
          () => _fetchAndInsertData<OrderOptionModel>(
            'Order Options',
            () => _ref.read(orderOptionProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(orderOptionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            OrderOptionModel.modelName,
          ),
      PageItemModel.modelName:
          () => _fetchAndInsertData<PageItemModel>(
            'Page Items',
            () => _ref.read(pageItemProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(pageItemProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PageItemModel.modelName,
          ),
      ItemModel.modelName:
          () => _fetchAndInsertData<ItemModel>(
            'Items',
            () => _ref.read(itemProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(itemProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ItemModel.modelName,
          ),
      ItemModifierModel.modelName:
          () => _fetchAndInsertData<ItemModifierModel>(
            'Item Modifiers',
            () => _ref.read(itemModifierProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(itemModifierProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            ItemModifierModel.modelName,
          ),
      CategoryModel.modelName:
          () => _fetchAndInsertData<CategoryModel>(
            'Categories',
            () => _ref.read(categoryProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(categoryProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            CategoryModel.modelName,
          ),
      TaxModel.modelName:
          () => _fetchAndInsertData<TaxModel>(
            'Taxes',
            () => _ref.read(taxProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(taxProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            TaxModel.modelName,
          ),
      ItemTaxModel.modelName:
          () => _fetchAndInsertData<ItemTaxModel>(
            'Item Taxes',
            () => _ref.read(itemTaxProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(itemTaxProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            ItemTaxModel.modelName,
          ),
      InventoryModel.modelName:
          () => _fetchAndInsertData<InventoryModel>(
            'Inventories',
            () => _ref.read(inventoryProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(inventoryProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            InventoryModel.modelName,
          ),
      InventoryTransactionModel.modelName:
          () => _fetchAndInsertData<InventoryTransactionModel>(
            'Inventory Transactions',
            () =>
                _ref
                    .read(inventoryTransactionProvider.notifier)
                    .syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(inventoryTransactionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            InventoryTransactionModel.modelName,
          ),
      CategoryTaxModel.modelName:
          () => _fetchAndInsertData<CategoryTaxModel>(
            'Category Taxes',
            () => _ref.read(categoryTaxProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(categoryTaxProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            CategoryTaxModel.modelName,
          ),
      CategoryDiscountModel.modelName:
          () => _fetchAndInsertData<CategoryDiscountModel>(
            'Category Discounts',
            () => _ref.read(categoryDiscountProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(categoryDiscountProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            CategoryDiscountModel.modelName,
          ),
      OutletTaxModel.modelName:
          () => _fetchAndInsertData<OutletTaxModel>(
            'Outlet Taxes',
            () => _ref.read(outletTaxProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(outletTaxProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            OutletTaxModel.modelName,
          ),
      PaymentTypeModel.modelName:
          () => _fetchAndInsertData<PaymentTypeModel>(
            'Payment Types',
            () => _ref.read(paymentTypeProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(paymentTypeProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PaymentTypeModel.modelName,
          ),
      OutletPaymentTypeModel.modelName:
          () => _fetchAndInsertData<OutletPaymentTypeModel>(
            'Outlet Payment Types',
            () =>
                _ref.read(outletPaymentTypeProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(outletPaymentTypeProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            OutletPaymentTypeModel.modelName,
          ),
      OrderOptionTaxModel.modelName:
          () => _fetchAndInsertData<OrderOptionTaxModel>(
            'Order Option Taxes',
            () => _ref.read(orderOptionTaxProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(orderOptionTaxProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            OrderOptionTaxModel.modelName,
          ),
      ModifierModel.modelName:
          () => _fetchAndInsertData<ModifierModel>(
            'Modifiers',
            () => _ref.read(modifierProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(modifierProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ModifierModel.modelName,
          ),
      ModifierOptionModel.modelName:
          () => _fetchAndInsertData<ModifierOptionModel>(
            'Modifier Options',
            () => _ref.read(modifierOptionProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(modifierOptionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ModifierOptionModel.modelName,
          ),
      DiscountModel.modelName:
          () => _fetchAndInsertData<DiscountModel>(
            'Discounts',
            () => _ref.read(discountProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(discountProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            DiscountModel.modelName,
          ),
      DiscountItemModel.modelName:
          () => _fetchAndInsertData<DiscountItemModel>(
            'Discount Items',
            () => _ref.read(discountItemProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(discountItemProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            DiscountItemModel.modelName,
          ),
      DiscountOutletModel.modelName:
          () => _fetchAndInsertData<DiscountOutletModel>(
            'Discount Outlet',
            () => _ref.read(discountOutletProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(discountOutletProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            DiscountOutletModel.modelName,
          ),
      StaffModel.modelName:
          () => _fetchAndInsertData<StaffModel>(
            'Staff',
            () => _ref.read(staffProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(staffProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            StaffModel.modelName,
          ),
      UserModel.modelName:
          () => _fetchAndInsertData<UserModel>(
            'Users',
            () => _ref.read(userProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(userProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            UserModel.modelName,
          ),
      PermissionModel.modelName:
          () => _fetchAndInsertData<PermissionModel>(
            'Permissions',
            () => _ref.read(permissionProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(permissionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PermissionModel.modelName,
          ),
      FeatureModel.modelName:
          () => _fetchAndInsertData<FeatureModel>(
            'Feature',
            () => _ref.read(featureProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(featureProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            FeatureModel.modelName,
          ),
      FeatureCompanyModel.modelName:
          () => _fetchAndInsertData<FeatureCompanyModel>(
            'Feature Company',
            () => _ref.read(featureCompanyProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(featureCompanyProvider.notifier)
                .insertBulk(items), // direct to sql because its pivot
            FeatureCompanyModel.modelName,
          ),
      CityModel.modelName:
          () => _fetchAndInsertData<CityModel>(
            'Cities',
            () => _ref.read(cityProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(cityProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            CityModel.modelName,
          ),
      CountryModel.modelName:
          () => _fetchAndInsertData<CountryModel>(
            'Countries',
            () => _ref.read(countryProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(countryProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            CountryModel.modelName,
          ),
      DivisionModel.modelName:
          () => _fetchAndInsertData<DivisionModel>(
            'Divisions',
            () => _ref.read(divisionProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(divisionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            DivisionModel.modelName,
          ),
      CustomerModel.modelName:
          () => _fetchAndInsertData<CustomerModel>(
            'Customers',
            () => _ref.read(customerProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(customerProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            CustomerModel.modelName,
          ),
      TableModel.modelName:
          () => _fetchAndInsertData<TableModel>(
            'Tables',
            () => _ref.read(tableProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(tableProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            TableModel.modelName,
          ),
      PosDeviceModel.modelName:
          () => _fetchAndInsertData<PosDeviceModel>(
            'Devices',
            () => _ref.read(deviceProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(deviceProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PosDeviceModel.modelName,
          ),

      SaleItemModel.modelName:
          () => _fetchAndInsertData<SaleItemModel>(
            'Sale Items',
            () => _ref.read(saleItemProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(saleItemProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            SaleItemModel.modelName,
          ),
      SaleModifierModel.modelName:
          () => _fetchAndInsertData<SaleModifierModel>(
            'Sale Modifiers',
            () => _ref.read(saleModifierProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(saleModifierProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            SaleModifierModel.modelName,
          ),
      SaleModifierOptionModel.modelName:
          () => _fetchAndInsertData<SaleModifierOptionModel>(
            'Sale Modifier Options',
            () =>
                _ref.read(saleModifierOptionProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(saleModifierOptionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            SaleModifierOptionModel.modelName,
          ),
      SaleModel.modelName:
          () => _fetchAndInsertData<SaleModel>(
            'Sale',
            () => _ref.read(saleProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(saleProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            SaleModel.modelName,
          ),
      // To just trigger the function to update meta data for now. need to do all the method if need to sync
      CashManagementModel.modelName:
          () => _fetchAndInsertData<CashManagementModel>(
            'Cash Management',
            () => _ref.read(cashManagementProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(cashManagementProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            CashManagementModel.modelName,
          ),
      DepartmentPrinterModel.modelName:
          () => _fetchAndInsertData<DepartmentPrinterModel>(
            'Department Printer',
            () =>
                _ref.read(departmentPrinterProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(departmentPrinterProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            DepartmentPrinterModel.modelName,
          ),

      OutletModel.modelName:
          () => _fetchAndInsertData<OutletModel>(
            'Outlets',
            () => _ref.read(outletProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(outletProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            OutletModel.modelName,
          ),
      ReceiptItemModel.modelName:
          () => _fetchAndInsertData<ReceiptItemModel>(
            'Receipt Items',
            () => _ref.read(receiptItemProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(receiptItemProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ReceiptItemModel.modelName,
          ),
      PageModel.modelName:
          () => _fetchAndInsertData<PageModel>(
            'Pages',
            () => _ref.read(pageProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(pageProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PageModel.modelName,
          ),
      PredefinedOrderModel.modelName:
          () => _fetchAndInsertData<PredefinedOrderModel>(
            'Predefined Orders',
            () => _ref.read(predefinedOrderProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(predefinedOrderProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PredefinedOrderModel.modelName,
          ),
      PrinterSettingModel.modelName:
          () => _fetchAndInsertData<PrinterSettingModel>(
            'Printer Settings',
            () => _ref.read(printerSettingProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(printerSettingProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PrinterSettingModel.modelName,
          ),
      PrintReceiptCacheModel.modelName:
          () => _fetchAndInsertData<PrintReceiptCacheModel>(
            'Print Receipt Caches',
            () =>
                _ref.read(printReceiptCacheProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(printReceiptCacheProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            PrintReceiptCacheModel.modelName,
          ),
      ReceiptModel.modelName:
          () => _fetchAndInsertData<ReceiptModel>(
            'Receipts',
            () => _ref.read(receiptProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(receiptProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ReceiptModel.modelName,
          ),
      ReceiptSettingsModel.modelName:
          () => _fetchAndInsertData<ReceiptSettingsModel>(
            'Receipt Settings',
            () => _ref.read(receiptSettingsProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(receiptSettingsProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ReceiptSettingsModel.modelName,
            needToDownloadImage: needToDownloadImage,
          ),
      ShiftModel.modelName:
          () => _fetchAndInsertData<ShiftModel>(
            'Shifts',
            () => _ref.read(shiftProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(shiftProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            ShiftModel.modelName,
          ),
      SlideshowModel.modelName:
          () => _fetchAndInsertData<SlideshowModel>(
            'Slideshows',
            () => _ref.read(slideshowProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(slideshowProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            SlideshowModel.modelName,
          ),
      TableSectionModel.modelName:
          () => _fetchAndInsertData<TableSectionModel>(
            'Table Sections',
            () => _ref.read(tableSectionProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(tableSectionProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            TableSectionModel.modelName,
          ),
      TimecardModel.modelName:
          () => _fetchAndInsertData<TimecardModel>(
            'Timecards',
            () => _ref.read(timecardProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(timecardProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            TimecardModel.modelName,
          ),
      // VariantOptionModel.modelName:
      //     () => _fetchAndInsertData<VariantOptionModel>(
      //       'Variant Options',
      //       () => _variantOption.getAllVariantOptionsFromAPIWithPagination(),
      //       _itemFacade.refreshBulkHiveBoxVariantOptions,
      //       VariantOptionModel.modelName,
      //     ),
      SupplierModel.modelName:
          () => _fetchAndInsertData<SupplierModel>(
            'Suppliers',
            () => _ref.read(supplierProvider.notifier).syncFromRemote(),
            (items, {isInsertToPending = false, isQueue = false}) => _ref
                .read(supplierProvider.notifier)
                .upsertBulk(items, isInsertToPending: isInsertToPending),
            SupplierModel.modelName,
          ),
    };

    // Add futures for models that need to be synced
    for (final modelName in modelsToSync) {
      final future = modelMap[modelName];
      if (future != null) {
        futures.add(future());
      }
    }

    return futures;
  }

  Future<void> syncSelectedModels({
    required List<String> modelsToSync,
    required Function(bool, String?) isSuccess,
    required bool needToDownloadImage,
    required bool result,
    required List<String> failedOperations,
  }) async {
    try {
      // takkan masuk result false
      // if (!result) {
      //   failedOperations.add('Failed to sync pending changes');
      // }

      _ref.read(appProvider.notifier).updateSyncProgress(3.0, '');

      if (result && modelsToSync.isNotEmpty) {
        List<Future<bool>> syncFutures = _createSelectiveSyncFutures(
          modelsToSync,
          needToDownloadImage,
        );

        final totalOperations = syncFutures.length;
        final completedOperations = <int>[0];

        _ref.read(appProvider.notifier).updateSyncProgress(5.0, '');

        syncFutures.asMap().entries.map((entry) {
          final index = entry.key;
          final future = entry.value;

          return future
              .then((result) {
                completedOperations[0]++;
                final completed = completedOperations[0];

                final progress = 5.0 + (completed / totalOperations) * 90.0;
                prints(
                  'Sync progress: $progress% - $completed/$totalOperations',
                );
                _ref
                    .read(appProvider.notifier)
                    .updateSyncProgress(progress, '');

                if (!result) {
                  failedOperations.add("Failed sync operation at index $index");
                }

                return result;
              })
              .catchError((e) {
                completedOperations[0]++;
                final completed = completedOperations[0];
                failedOperations.add(
                  "Error in sync operation at index $index: $e",
                );

                final progress = 5.0 + (completed / totalOperations) * 90.0;
                _ref
                    .read(appProvider.notifier)
                    .updateSyncProgress(progress, '');
                return false;
              });
        }).toList();

        _ref
            .read(appProvider.notifier)
            .updateSyncProgress(95.0, 'Finalizing sync...');

        _ref.read(appProvider.notifier).updateSyncProgress(100.0, '');
        _ref.read(appProvider.notifier).setEverDontHaveInternet(false);
      } else {
        _ref.read(appProvider.notifier).updateSyncProgress(100.0, '');
        prints(
          '⚠️ Selective sync completed (result: $result, modelsCount: ${modelsToSync.length})',
        );
      }

      final bool allSuccess = failedOperations.isEmpty;
      prints(
        allSuccess
            ? 'Successfully synchronized selected models'
            : 'Some sync operations failed: ${failedOperations.join(", ")}',
      );
      prints(allSuccess ? '✅ Sync completed successfully' : '❌ Sync failed');

      // Close the dialog by setting isSyncing to false after reaching 100%
      _ref.read(appProvider.notifier).setIsSyncing(false);
      isSuccess(allSuccess, allSuccess ? null : failedOperations.join(', '));
    } catch (e) {
      prints('Error in syncSelectedModels: $e');
      prints('❌ Error in syncSelectedModels: $e');
      _ref.read(appProvider.notifier).setIsSyncing(false);
      isSuccess(false, 'Sync error: $e');
    }
  }

  Future<void> onSyncOrder(
    BuildContext? context,
    bool mounted, {
    required bool manuallyClick,
    required bool isAfterActivateLicense,
    required Function(bool, String?) isSuccess,
    required bool needToDownloadImage,
    required bool onlyCheckPendingChanges,
    bool isForce = false,
  }) async {
    if (await NetworkUtils.hasInternetConnection()) {
      final List<String> failedOperations = [];
      _ref.read(appProvider.notifier).setIsSyncing(true);

      _ref.read(appProvider.notifier).updateSyncProgress(0.0, '');
      // Sync pending changes first with timeout
      final deleteWhereModelIdNull =
          await _ref
              .read(pendingChangesProvider.notifier)
              .deleteWhereModelIdIsNull();
      prints('✅ Deleted where model_id is null: $deleteWhereModelIdNull');

      bool result = false;
      try {
        result = await _ref
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
        result = false;
      }
      if (!result) {
        _ref.read(appProvider.notifier).updateSyncProgress(100.0, '');
        _ref.read(appProvider.notifier).setIsSyncing(false);
        int pcCount =
            (await _ref
                    .read(pendingChangesProvider.notifier)
                    .getListPendingChanges())
                .length;
        failedOperations.add('Failed to sync $pcCount pending changes');
        // only check for pending changes
        final bool allSuccess = failedOperations.isEmpty;
        prints(
          allSuccess
              ? 'Successfully sync pending changes'
              : 'Some sync operations failed: ${failedOperations.join(", ")}',
        );
        prints(allSuccess ? '✅ Sync completed successfully' : '❌ Sync failed');

        isSuccess(allSuccess, allSuccess ? null : failedOperations.join(', '));
      } else if (result) {
        if (!onlyCheckPendingChanges) {
          final checkNewTableMap = await checkForNewTables();
          bool hasNewTables = checkNewTableMap['hasNewTables'] ?? false;
          List<String> missingTables = checkNewTableMap['missingTables'];
          if (manuallyClick) {
            if (hasNewTables) {
              if (mounted && context != null) {
                ThemeSnackBar.showSnackBar(
                  context,
                  'Failed to sync, please log out and login again.',
                );
                await _ref
                    .read(errorLogProvider.notifier)
                    .createAndInsertErrorLog(
                      'New tables detected (${missingTables.join(', ')}), please close shift and logout and login again.',
                    );
              }
              return;
            }
          }
          SyncCheckModel syncCheckModel = SyncCheckModel();
          try {
            if (!isAfterActivateLicense) {
              // CALL DELETED ORDER
              _ref.read(appProvider.notifier).updateSyncProgress(3.0, '');
              await _ref.read(deletedProvider.notifier).syncFromRemote();

              _ref.read(appProvider.notifier).updateSyncProgress(4.5, '');
              // Check which models need to be synced
              syncCheckModel =
                  !isForce
                      ? await checkModelsToSync()
                      : await forceCheckModelsToSync();

              if (syncCheckModel.changesDetected != null &&
                  !syncCheckModel.changesDetected!) {
                if (mounted && context != null) {
                  ThemeSnackBar.showSnackBar(
                    context,
                    'No changes detected on the server',
                  );
                }
                // Close the loading dialog and notify completion
                _ref.read(appProvider.notifier).updateSyncProgress(100.0, '');
                _ref.read(appProvider.notifier).setIsSyncing(false);

                // Check for any failed operations
                final bool allSuccess = failedOperations.isEmpty;
                prints(
                  allSuccess
                      ? '✅ Sync completed successfully'
                      : '❌ Sync failed',
                );

                isSuccess(
                  allSuccess,
                  allSuccess ? null : failedOperations.join(', '),
                );
                return;
              }
            } else {
              syncCheckModel = SyncCheckModel(
                modelsToSync: [
                  PosDeviceModel.modelName,
                  ShiftModel.modelName,
                  TimecardModel.modelName,
                  FeatureModel.modelName,
                  FeatureCompanyModel.modelName,
                  OutletModel.modelName,
                  StaffModel.modelName,
                  UserModel.modelName,
                  PermissionModel.modelName,
                  DivisionModel.modelName,
                  CountryModel.modelName,
                  CityModel.modelName,
                ],
                changesDetected: true,
              );
            }
            // prints('🔄 Models to sync: ${syncCheckModel.modelsToSync.join(', ')}');
            MetaModel meta = MetaModel(lastSync: DateTime.now().toUtc());
            await SyncService.saveMetaData(DeletedModel.modelName, meta);
            // Sync only the models that have changes
            List<String> modelsToSync =
                syncCheckModel.modelsToSync != null
                    ? syncCheckModel.modelsToSync!
                    : [];
            await syncSelectedModels(
              modelsToSync: modelsToSync,
              needToDownloadImage: needToDownloadImage,
              failedOperations: failedOperations,
              result: result,
              isSuccess: (isSuccesss, errorMessage) async {
                prints(errorMessage ?? 'ERROR MESSAGE NULL');
                isSuccess(isSuccesss, errorMessage);
                // check if mounted because user can go to another page
                // while sync is running
                if (mounted && context != null) {
                  ThemeSnackBar.showSnackBar(
                    context,
                    isSuccesss
                        ? 'Success sync'
                        : (errorMessage ?? 'failed to sync'),
                  );
                }
              },
            );
          } catch (e) {
            prints('❌ Error checking sync models: $e');

            if (mounted && context != null) {
              ThemeSnackBar.showSnackBar(
                context,
                'Error checking sync updates: $e',
              );
            }
            failedOperations.addAll(['Error checking sync updates: $e']);
          }

          _ref.read(appProvider.notifier).updateSyncProgress(100.0, '');
          _ref.read(appProvider.notifier).setIsSyncing(false);

          // only check for pending changes
          final bool allSuccess = failedOperations.isEmpty;

          prints(
            allSuccess ? '✅ Sync completed successfully' : '❌ Sync failed',
          );

          isSuccess(
            allSuccess,
            allSuccess ? null : failedOperations.join(', '),
          );
        } else {
          // if want to logout, so we put onlyPending changes to true
          _ref.read(appProvider.notifier).updateSyncProgress(100.0, '');
          _ref.read(appProvider.notifier).setIsSyncing(false);

          // only check for pending changes
          final bool allSuccess = failedOperations.isEmpty;
          prints(
            allSuccess
                ? 'Successfully sync pending changes'
                : 'Some sync operations failed: ${failedOperations.join(", ")}',
          );
          prints(
            allSuccess ? '✅ Sync completed successfully' : '❌ Sync failed',
          );

          isSuccess(
            allSuccess,
            allSuccess ? null : failedOperations.join(', '),
          );
        }
      }
    } else {
      if (mounted && context != null) {
        NetworkUtils.noInternetDialog(context);
      }
    }
  }

  Future<SyncCheckModel> checkModelsToSync() async {
    try {
      // Get last sync timestamp from secure storage
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
        prints(response.data!.modelsToSync!.map((model) => model).join(', '));
        return response.data!;
      } else {
        prints(
          '❌ SyncCheck failed - message: ${response.message}, statusCode: ${response.statusCode}',
        );
        throw Exception(response.message);
      }
    } catch (e) {
      prints('🚨 SyncCheck threw exception: $e');
      prints('   Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<SyncCheckModel> forceCheckModelsToSync() async {
    try {
      // Get last sync timestamp from secure storage
      Map<String, dynamic> data = {};
      for (String key in SSKey.allKeys) {
        data[key] = DateTimeUtils.formatToISO8601(DateTime.parse("2000-01-01"));
      }

      SyncCheckResponseModel response = await _webService.post(
        _syncRepository.syncCheck(data: data),
      );

      prints(
        '🔍 SyncCheck response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}',
      );

      if (response.isSuccess && response.data != null) {
        prints(response.data!.modelsToSync!.map((model) => model).join(', '));
        return response.data!;
      } else {
        prints(
          '❌ SyncCheck failed - message: ${response.message}, statusCode: ${response.statusCode}',
        );
        throw Exception(response.message);
      }
    } catch (e) {
      prints('🚨 SyncCheck threw exception: $e');
      prints('   Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

/// Provider for predefinedOrder domain
final syncRealTimeProvider =
    StateNotifierProvider<SyncRealTimeNotifier, SyncRealTimeState>((ref) {
      return SyncRealTimeNotifier(
        ref: ref,
        secureStorageApi: ServiceLocator.get<SecureStorageApi>(),
        webService: ServiceLocator.get<IWebService>(),
        syncRepository: ServiceLocator.get<SyncRepository>(),
      );
    });

/// A class to hold pending fetch tasks for concurrent execution
class _PendingFetchTask {
  final Future<bool> Function() executionFunction;
  final Completer<bool> completer;

  _PendingFetchTask({required this.executionFunction, required this.completer});

  /// Execute this task by calling the stored execution function
  Future<bool> execute() => executionFunction();
}

class NotifierUpdateThrottler {
  Timer? _timer;
  final Duration _throttleDuration;
  final List<Function> _pendingUpdates = [];

  NotifierUpdateThrottler({Duration? throttleDuration})
    : _throttleDuration =
          throttleDuration ?? const Duration(milliseconds: 2000);

  void scheduleUpdate(Function updateFunction) {
    _pendingUpdates.add(updateFunction);

    if (_timer == null || !_timer!.isActive) {
      _timer = Timer(_throttleDuration, () {
        _executePendingUpdates();
      });
    }
  }

  void _executePendingUpdates() {
    if (_pendingUpdates.isNotEmpty) {
      for (var update in _pendingUpdates) {
        try {
          update();
        } catch (e) {
          prints('Error executing throttled update: $e');
        }
      }
      _pendingUpdates.clear();
    }
  }

  void dispose() {
    _timer?.cancel();
    _pendingUpdates.clear();
  }
}
