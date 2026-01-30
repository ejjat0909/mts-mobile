import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/print_cache_status_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_list_response_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/domain/repositories/local/print_receipt_cache_repository.dart';
import 'package:mts/domain/repositories/remote/print_receipt_cache_repository.dart';
import 'package:mts/providers/print_receipt_cache/print_receipt_cache_state.dart';
import 'dart:convert';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_data_payload.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/domain/repositories/local/department_printer_repository.dart';
import 'package:mts/domain/repositories/local/printer_setting_repository.dart';
import 'package:mts/providers/shift/shift_providers.dart';

/// StateNotifier for PrintReceiptCache domain
///
/// Migrated from: print_receipt_cache_facade_impl.dart
class PrintReceiptCacheNotifier extends StateNotifier<PrintReceiptCacheState> {
  final LocalPrintReceiptCacheRepository _localRepository;
  final PrintReceiptCacheRepository _remoteRepository;
  final LocalPrinterSettingRepository _localPrinterSettingRepository;
  final IWebService _webService;
  final LocalDepartmentPrinterRepository _localDepartmentPrinterRepository;
  final Ref _ref;

  PrintReceiptCacheNotifier({
    required LocalPrintReceiptCacheRepository localRepository,
    required PrintReceiptCacheRepository remoteRepository,
    required IWebService webService,
    required LocalPrinterSettingRepository localPrinterSettingRepository,
    required LocalDepartmentPrinterRepository localDepartmentPrinterRepository,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _localPrinterSettingRepository = localPrinterSettingRepository,
       _localDepartmentPrinterRepository = localDepartmentPrinterRepository,
       _ref = ref,
       super(const PrintReceiptCacheState());

  // ============================================================
  // API Methods (migrated from print_receipt_cache_facade_impl.dart)
  // ============================================================
  /// Fetch all print receipt cache from API with pagination and filtering
  Future<List<PrintReceiptCacheModel>> syncFromRemote() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      PosDeviceModel posDeviceModel = ServiceLocator.get<PosDeviceModel>();
      List<PrintReceiptCacheModel> allPrintReceiptCache = [];
      int currentPage = 1;
      int? lastPage;

      do {
        PrintReceiptCacheListResponseModel responseModel = await _webService
            .get(
              _remoteRepository.getPrintReceiptCacheListPaginated(
                currentPage.toString(),
              ),
            );

        if (responseModel.isSuccess && responseModel.data != null) {
          final List<PrintReceiptCacheModel> filteredListPRC =
              responseModel.data!.where((element) {
                return element.posDeviceId == posDeviceModel.id &&
                    element.status == PrintCacheStatusEnum.pending &&
                    element.printData?.printerSettingModel?.printOrders == true;
              }).toList();
          allPrintReceiptCache.addAll(filteredListPRC);
          if (responseModel.paginator != null) {
            lastPage = responseModel.paginator!.lastPage;
          } else {
            break;
          }
          currentPage++;
        } else {
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      state = state.copyWith(isLoading: false);
      return allPrintReceiptCache;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Get paginated print receipt cache resource
  Resource getListPrintReceiptCacheWithPagination(String page) {
    return _remoteRepository.getPrintReceiptCacheListPaginated(page);
  }

  // ============================================================
  // CRUD Methods
  // ============================================================

  /// Insert multiple items into local storage
  Future<bool> insertBulk(
    List<PrintReceiptCacheModel> list, {
    bool isInsertToPending = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get all items from local storage
  Future<List<PrintReceiptCacheModel>> getListPrintReceiptCacheModel() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _localRepository.getListPrintReceiptCacheModel();
      state = state.copyWith(items: items, isLoading: false);
      return items;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  /// Delete multiple items from local storage
  Future<bool> deleteBulk(List<PrintReceiptCacheModel> list) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteBulk(list, true);

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete all items from local storage
  Future<bool> deleteAll() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.deleteAll();

      if (result) {
        state = state.copyWith(items: [], itemsFromHive: []);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a single item by ID
  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.delete(
        id,
        isInsertToPending: isInsertToPending,
      );

      if (result > 0) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Find an item by its ID
  Future<PrintReceiptCacheModel?> getPrintReceiptCacheModelById(
    String itemId,
  ) async {
    try {
      final items = await _localRepository.getListPrintReceiptCacheModel();

      try {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => PrintReceiptCacheModel(),
        );
        return item.id != null ? item : null;
      } catch (e) {
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<PrintReceiptCacheModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.replaceAllData(
        newData,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        state = state.copyWith(items: newData);
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upsert bulk items to Hive box without replacing all items
  Future<bool> upsertBulk(
    List<PrintReceiptCacheModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        await _loadItems();
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Internal helper to load items and update state
  Future<void> _loadItems() async {
    try {
      final items = await _localRepository.getListPrintReceiptCacheModel();

      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // Old ChangeNotifier Methods (Compatibility)
  // ========================================

  /// Get print receipt cache list (old notifier getter)
  List<PrintReceiptCacheModel> get getPrintReceiptCacheList => state.items;

  /// Set the list of print receipt caches (old notifier method)
  void setListPrintReceiptCache(List<PrintReceiptCacheModel> list) {
    state = state.copyWith(items: list);
  }

  /// Get list of print receipt caches in processing status (old notifier method)
  List<PrintReceiptCacheModel> listPrcProcessing() {
    return getPrintReceiptCacheList
        .where((e) => e.status == PrintCacheStatusEnum.processing)
        .toList();
  }

  /// Add or update list of print receipt caches (old notifier method)
  void addOrUpdateList(List<PrintReceiptCacheModel> list) {
    final currentItems = List<PrintReceiptCacheModel>.from(state.items);

    for (PrintReceiptCacheModel printReceiptCache in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == printReceiptCache.id,
      );

      if (index != -1) {
        currentItems[index] = printReceiptCache;
      } else {
        currentItems.add(printReceiptCache);
      }
    }
    state = state.copyWith(items: currentItems);
  }

  /// Add or update a single print receipt cache (old notifier method)
  void addOrUpdate(PrintReceiptCacheModel printReceiptCache) {
    final currentItems = List<PrintReceiptCacheModel>.from(state.items);
    int index = currentItems.indexWhere((p) => p.id == printReceiptCache.id);

    if (index != -1) {
      currentItems[index] = printReceiptCache;
    } else {
      currentItems.add(printReceiptCache);
    }
    state = state.copyWith(items: currentItems);
  }

  /// Remove a print receipt cache by ID (old notifier method)
  void remove(String id) {
    final updatedItems =
        state.items
            .where((printReceiptCache) => printReceiptCache.id != id)
            .toList();
    state = state.copyWith(items: updatedItems);
  }

  Future<int> insert(
    PrintReceiptCacheModel model, {
    required bool isInsertToPending,
  }) async {
    return await _localRepository.insert(
      model,
      isInsertToPending: isInsertToPending,
    );
  }

  Future<int> update(PrintReceiptCacheModel printReceiptCacheModel) async {
    return await _localRepository.update(printReceiptCacheModel, true);
  }

  List<PrintReceiptCacheModel> getListPrintReceiptCacheFromHive() {
    return _localRepository.getListPrintReceiptCacheFromHive();
  }

  Future<bool> syncWithServerData(
    List<PrintReceiptCacheModel> serverData, {
    bool isInsertToPending = false,
  }) async {
    return await _localRepository.upsertBulk(
      serverData,
      isInsertToPending: isInsertToPending,
    );
  }

  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithPendingOrFailed() async {
    return await _localRepository.getListPrintReceiptCacheWithPendingOrFailed();
  }

  Future<PrintReceiptCacheModel?> getModelBySaleId(String saleId) async {
    return await _localRepository.getModelBySaleId(saleId);
  }

  Future<void> insertDetailsPrintCache({
    required SaleModel saleModel,
    required List<SaleItemModel> listSaleItemModel,
    required List<SaleModifierModel> listSM,
    required List<SaleModifierOptionModel> listSMO,
    required OrderOptionModel orderOptionModel,
    required PredefinedOrderModel pom,
    required String printType,
    required bool isForThisDevice,
  }) async {
    final outletModel = ServiceLocator.get<OutletModel>();
    final shiftNotifier = _ref.read(shiftProvider.notifier);
    ShiftModel shiftModel = await shiftNotifier.getLatestShift();

    final listPrinterSetting = await _localPrinterSettingRepository
        .getListPrinterSettingByDevice(isForThisDevice: isForThisDevice);
    prints('Printer settings count: ${listPrinterSetting.length}');

    final futures = <Future<void>>[];
    for (int i = 0; i < listPrinterSetting.length; i++) {
      PrinterSettingModel psm = listPrinterSetting[i];
      LogUtils.info(
        'Processing printer ${i + 1}/${listPrinterSetting.length}: ${psm.id}',
      );

      if (psm.printOrders == false) {
        continue;
      }

      if (pom.id == null) {
        prints('⚠️⚠️⚠️⚠️⚠️⚠️⚠️Predefined order ID is null. Skipping...');
        continue;
      }

      List<String> dpmIds = [];
      try {
        dpmIds = List<String>.from(
          json.decode(psm.departmentPrinterJson ?? '[]'),
        );
      } catch (e) {
        prints(
          '⚠️ Could not parse department printer JSON for printer ${psm.name}: $e',
        );
      }

      if (dpmIds.isEmpty) {
        prints('⚠️ No department printers configured for printer: ${psm.name}');
        continue;
      }

      List<DepartmentPrinterModel> listDpm =
          await _localDepartmentPrinterRepository
              .getListDepartmentPrintersFromIds(dpmIds);

      List<List<String>> categoryGroup =
          listDpm.map((dpm) {
            try {
              return List<String>.from(json.decode(dpm.categories ?? '[]'));
            } catch (e) {
              prints('⚠️ Could not parse categories for DPM ${dpm.name}: $e');
              return <String>[];
            }
          }).toList();

      for (var (index, dpm) in listDpm.indexed) {
        List<SaleItemModel> filteredSaleItems =
            listSaleItemModel
                .where(
                  (element) =>
                      categoryGroup[index].contains(element.categoryId),
                )
                .toList();

        if (filteredSaleItems.isEmpty) {
          prints('No sale items found for DPM ${dpm.name}, skipping...');
          continue;
        }

        futures.add(
          Future<void>(() async {
            try {
              PrintDataPayload payLoad = PrintDataPayload(
                saleModel: saleModel,
                listSaleItems: filteredSaleItems,
                listSM: listSM,
                listSMO: listSMO,
                orderOptionModel:
                    orderOptionModel.id != null ? orderOptionModel : null,
                printerSettingModel: psm,
                dpm: dpm,
                predefinedOrderModel: pom,
              );
              String newID = IdUtils.generateUUID();
              PrintReceiptCacheModel model = PrintReceiptCacheModel(
                id: newID,
                printedAttempts: 0,
                saleId: saleModel.id,
                outletId: outletModel.id,
                shiftId: shiftModel.id,
                printData: payLoad,
                status: PrintCacheStatusEnum.pending,
                printType: printType,
                posDeviceId: psm.posDeviceId,
                printerSettingId: psm.id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              if (isForThisDevice) {
                await insert(model, false);
              } else {
                if (psm.printOrders == true) {
                  await onlyInsertToPending(model);
                }
              }
              prints(
                'Successfully inserted print cache for printer: ${psm.id}',
              );
            } catch (e) {
              prints(
                '❌❌❌❌❌❌❌❌❌❌❌❌Failed to insert print cache for printer ${psm.id}',
              );
            }
          }),
        );
      }
    }
    await Future.wait(futures, eagerError: false);
  }

  Future<bool> deleteBySuccessAndCancelStatusAndFailed() async {
    return await _localRepository.deleteBySuccessAndCancelStatusAndFailed();
  }

  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithPendingStatus() async {
    return await _localRepository.getListPrintReceiptCacheWithPendingStatus();
  }

  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithProcessingStatus() async {
    return await _localRepository
        .getListPrintReceiptCacheWithProcessingStatus();
  }

  Future<bool> onlyInsertToPending(PrintReceiptCacheModel model) async {
    return await _localRepository.onlyInsertToPending(model);
  }
}

/// Provider for sorted items (computed provider)
final sortedPrintReceiptCachesProvider = Provider<List<PrintReceiptCacheModel>>(
  (ref) {
    final items = ref.watch(printReceiptCacheProvider).items;
    final sorted = List<PrintReceiptCacheModel>.from(items);
    sorted.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.toString().compareTo(bTime.toString());
    });
    return sorted;
  },
);

/// Provider for printReceiptCache domain
final printReceiptCacheProvider =
    StateNotifierProvider<PrintReceiptCacheNotifier, PrintReceiptCacheState>((
      ref,
    ) {
      return PrintReceiptCacheNotifier(
        localRepository: ServiceLocator.get<LocalPrintReceiptCacheRepository>(),
        remoteRepository: ServiceLocator.get<PrintReceiptCacheRepository>(),
        webService: ServiceLocator.get<IWebService>(),
        localPrinterSettingRepository:
            ServiceLocator.get<LocalPrinterSettingRepository>(),
        localDepartmentPrinterRepository:
            ServiceLocator.get<LocalDepartmentPrinterRepository>(),
        ref: ref,
      );
    });

/// Provider for printReceiptCache by ID (family provider for indexed lookups)
final printReceiptCacheByIdProvider =
    FutureProvider.family<PrintReceiptCacheModel?, String>((ref, id) async {
      final notifier = ref.watch(printReceiptCacheProvider.notifier);
      return notifier.getPrintReceiptCacheModelById(id);
    });

/// Provider for printReceiptCache by ID (sync version - computed provider)
final printReceiptCacheByIdSyncProvider =
    Provider.family<PrintReceiptCacheModel?, String>((ref, id) {
      final items = ref.watch(printReceiptCacheProvider).items;
      try {
        return items.firstWhere((item) => item.id == id);
      } catch (e) {
        return null;
      }
    });

/// Provider for print receipt caches with processing status
final printReceiptCachesProcessingProvider =
    Provider<List<PrintReceiptCacheModel>>((ref) {
      final items = ref.watch(printReceiptCacheProvider).items;
      return items
          .where((e) => e.status == PrintCacheStatusEnum.processing)
          .toList();
    });

/// Provider for print receipt caches with pending status
final printReceiptCachesPendingProvider =
    FutureProvider<List<PrintReceiptCacheModel>>((ref) async {
      final notifier = ref.read(printReceiptCacheProvider.notifier);
      return notifier.getListPrintReceiptCacheWithPendingStatus();
    });

/// Provider for print receipt caches with pending or failed status
final printReceiptCachesPendingOrFailedProvider =
    FutureProvider<List<PrintReceiptCacheModel>>((ref) async {
      final notifier = ref.read(printReceiptCacheProvider.notifier);
      return notifier.getListPrintReceiptCacheWithPendingOrFailed();
    });

/// Provider for print receipt cache by sale ID
final printReceiptCacheBySaleIdProvider =
    FutureProvider.family<PrintReceiptCacheModel?, String>((ref, saleId) async {
      final notifier = ref.read(printReceiptCacheProvider.notifier);
      return notifier.getModelBySaleId(saleId);
    });

/// Provider for print receipt caches from Hive (sync)
final printReceiptCachesFromHiveProvider =
    Provider<List<PrintReceiptCacheModel>>((ref) {
      final notifier = ref.read(printReceiptCacheProvider.notifier);
      return notifier.getListPrintReceiptCacheFromHive();
    });

/// Provider for print receipt caches count
final printReceiptCachesCountProvider = Provider<int>((ref) {
  final items = ref.watch(printReceiptCacheProvider).items;
  return items.length;
});
