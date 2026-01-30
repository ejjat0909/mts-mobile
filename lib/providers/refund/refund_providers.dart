import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/home_receipt_navigator_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/enum/receipt_status_enum.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/services/receipt_printer_service.dart';
import 'package:mts/domain/repositories/local/printer_setting_repository.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/refund/refund_state.dart';
import 'package:mts/providers/shift/shift_providers.dart';

/// StateNotifier for Refund domain
///
/// Handles complex refund business logic with proper state management
/// Orchestrates multiple facades (Receipt, ReceiptItem, Shift) and repositories
///
/// All business logic moved to provider for better state management and UI reactivity
class RefundNotifier extends StateNotifier<RefundState> {
  final LocalPrinterSettingRepository _localPrinterSettingRepository;
  final Ref _ref;

  RefundNotifier({
    required LocalPrinterSettingRepository localPrinterSettingRepository,
    required Ref ref,
  }) : _localPrinterSettingRepository = localPrinterSettingRepository,
       _ref = ref,
       super(const RefundState());

  /// Handle the complete refund process with state management
  ///
  /// Creates refund receipt, updates original items, updates shift cash,
  /// handles navigation and printing with real-time UI updates
  Future<void> handleOnRefund({
    required Function() closeLoading,
    required Function() onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final receiptNotifier = _ref.read(receiptProvider.notifier);
      final receiptItemNotifier = _ref.read(receiptItemProvider.notifier);
      final shiftNotifier = _ref.read(shiftProvider.notifier);

      receiptNotifier.addBulkInitialListReceiptItems([]);
      List<ReceiptItemModel> refundItems = state.refundItems;
      List<ReceiptItemModel> newRefundItems = [];

      /// [GENERATE NEW REFUND RECEIPT MODEL]
      ReceiptModel newRM = ReceiptModel();
      String newReceiptId = IdUtils.generateUUID();

      // Get receipt id from refund item
      String receiptId = refundItems.first.receiptId!;

      // Get receipt model from receipt id
      ReceiptModel? receiptModel = await receiptNotifier.getReceiptModelFromId(
        receiptId,
      );

      if (receiptModel != null) {
        double grossSales = refundItems.fold(
          0,
          (total, ri) => total = total + (ri.price ?? 0.00),
        );

        double cost = refundItems.fold(
          0,
          (total, ri) => total = total + (ri.cost ?? 0.00),
        );

        newRM = receiptModel.copyWith(
          id: newReceiptId,
          showUUID: await IdUtils.generateReceiptId(),
          refundedReceiptId: receiptModel.showUUID,
          receiptStatus: ReceiptStatusEnum.refunded,
          cash: state.totalAfterDiscountAndTax,
          totalTaxes: state.taxAfterDiscount,
          totalDiscount: state.totalDiscount,
          payableAmount: state.totalAfterDiscountAndTax,
          cost: receiptModel.cost!,
          grossSale: grossSales,
          netSale: state.totalAfterDiscountAndTax,
          totalCollected: state.totalAfterDiscountAndTax,
          grossProfit: double.parse(
            (state.totalAfterDiscountAndTax - cost).toStringAsFixed(2),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Update state: receipt created
        state = state.copyWith(currentReceiptId: newReceiptId);

        /// Generate new receipt model
        await receiptNotifier.insert(newRM);

        // Process each refund item
        for (ReceiptItemModel refItem in refundItems) {
          ReceiptItemModel? ri = await receiptItemNotifier.getReceiptItemById(
            refItem.id!,
          );

          if (ri != null) {
            ReceiptItemModel updateRI = ri.copyWith(
              totalRefunded:
                  ri.totalRefunded > 0
                      ? (ri.totalRefunded + refItem.quantity!)
                      : refItem.quantity,
            );

            ReceiptItemModel newRI = ri.copyWith(
              id: IdUtils.generateUUID(),
              receiptId: newReceiptId,
              totalRefunded: refItem.quantity,
              quantity: refItem.quantity,
              price: refItem.price,
              isRefunded: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await receiptItemNotifier.update(updateRI);
            await receiptItemNotifier.insert(newRI);

            newRefundItems.add(newRI);
          } else {
            prints('REFUND PROVIDER: receipt item not found');
          }
        }

        /// [UPDATE EXPECTED CASH SHIFT MODEL]
        await shiftNotifier.updateExpectedCash();

        // Update state: items processed
        state = state.copyWith(refundItemsCount: newRefundItems.length);
      } else {
        prints('REFUND PROVIDER: receipt model not found');
        state = state.copyWith(isLoading: false, error: 'Receipt not found');
        onError('Receipt not found');
        return;
      }

      if (newRM.id != null) {
        String tabTitle =
            '${newRM.showUUID!} | ${DateTimeUtils.getDateTimeFormat(newRM.createdAt)}';
        _ref
            .read(myNavigatorProvider.notifier)
            .setSelectedTab(newRM.receiptStatus!, tabTitle);
      }

      // Close loading dialogue first because context already changed when navigating
      closeLoading();

      /// Go back to receipt details and clear refund items and receipt items
      receiptNotifier.setPageIndex(HomeReceiptNavigatorEnum.receiptDetails);
      receiptNotifier.clearAll();
      clearAll();
      await Future.delayed(const Duration(milliseconds: 500));

      receiptNotifier.refreshPagingController();

      // Set selected receipt page index
      if (newRM.id != null) {
        receiptNotifier.clearTempReceiptId();
        receiptNotifier.setTempReceiptModel(newRM);
        receiptNotifier.setSelectedReceiptIndex(0); // set to first receipt
        receiptNotifier.addBulkInitialListReceiptItems(newRefundItems);
      }

      // Print on refund
      state = state.copyWith(isLoading: false);
      await printOnRefund(newReceiptId, onSuccess: onSuccess, onError: onError);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      prints('REFUND PROVIDER ERROR: $e');
      onError(e.toString());
    }
  }

  /// Print refund receipt with state management
  ///
  /// Handles printing to multiple printers with real-time error tracking
  Future<void> printOnRefund(
    String receiptId, {
    required Function() onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      state = state.copyWith(isPrinting: true, printErrors: []);

      final receiptNotifier = _ref.read(receiptProvider.notifier);

      List<PrinterSettingModel> listPsm =
          await _localPrinterSettingRepository.getListPrinterSetting();

      if (listPsm.isEmpty) {
        state = state.copyWith(isPrinting: false);
        onSuccess();
        return;
      }

      List<String> errorIps = [];
      int completedTask = 0;

      for (PrinterSettingModel psm in listPsm) {
        prints('Current ip ${psm.identifierAddress}');

        Future<void> printTask;

        if (psm.interface == PrinterSettingEnum.bluetooth) {
          printTask = receiptNotifier.printSalesReceipt(
            receiptId,
            isInterfaceBluetooth: true,
            ipAddress: psm.identifierAddress ?? '',
            paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
            onError: (message, ipAd) {
              if (!errorIps.contains(ipAd)) {
                errorIps.add(ipAd);
                // Update state with new error
                state = state.copyWith(printErrors: List.from(errorIps));
              }
            },
            isShouldOpenCashDrawer: true,
            listPrinterSettings: listPsm,
            isAutomaticPrint: true,
          );
        } else if (psm.interface == PrinterSettingEnum.ethernet &&
            psm.identifierAddress != null) {
          printTask = receiptNotifier.printSalesReceipt(
            receiptId,
            isInterfaceBluetooth: false,
            ipAddress: psm.identifierAddress!,
            paperWidth: ReceiptPrinterService.getPaperWidth(psm.paperWidth),
            onError: (message, ipAd) {
              if (!errorIps.contains(ipAd)) {
                errorIps.add(ipAd);
                // Update state with new error
                state = state.copyWith(printErrors: List.from(errorIps));
              }
            },
            isShouldOpenCashDrawer: true,
            listPrinterSettings: listPsm,
            isAutomaticPrint: true,
          );
        } else {
          continue;
        }

        await printTask;
        completedTask++;

        // Update state with progress
        state = state.copyWith(
          printersCompleted: completedTask,
          printersTotal: listPsm.length,
        );
      }

      state = state.copyWith(isPrinting: false);

      if (completedTask == listPsm.length) {
        if (errorIps.isNotEmpty) {
          prints('All printers attempted, but some failed.');
          onError(errorIps.join(', '));
        } else {
          prints('All printers attempted successfully.');
          onSuccess();
        }
      } else {
        onSuccess();
      }
    } catch (e) {
      state = state.copyWith(isPrinting: false, error: e.toString());
      prints('PRINT REFUND ERROR: $e');
      onError(e.toString());
    }
  }

  /// Add or update an item to the refund list
  void addItemToRefund(ReceiptItemModel refundItem, ReceiptItemModel originRI) {
    final List<ReceiptItemModel> currentItems = List.from(state.refundItems);
    final index = currentItems.indexWhere(
      (element) => element.id == refundItem.id,
    );

    if (index != -1) {
      currentItems[index] = refundItem;
    } else {
      currentItems.add(refundItem);
    }

    // Add to origin items
    final List<ReceiptItemModel> originItems = List.from(
      state.originRefundItems,
    );
    final originIndex = originItems.indexWhere((ri) => ri.id == originRI.id);
    if (originIndex == -1) {
      originItems.add(originRI);
    }

    state = state.copyWith(
      refundItems: currentItems,
      originRefundItems: originItems,
    );

    _recalculateTotals();
  }

  /// Remove an item from the refund list
  void removeItemFromRefund(String itemId) {
    final List<ReceiptItemModel> currentItems = List.from(state.refundItems);
    currentItems.removeWhere((element) => element.id == itemId);

    state = state.copyWith(refundItems: currentItems);
    _recalculateTotals();
  }

  /// Clear all refund items and reset calculations
  void clearAll() {
    state = const RefundState();
  }

  // ============================================================================
  // OLD NOTIFIER METHODS - For UI backward compatibility
  // ============================================================================

  // Getters
  List<ReceiptItemModel> get getRefundItems => state.refundItems;
  List<ReceiptItemModel> get getOriginRefundItems => state.originRefundItems;
  List<Map<String, dynamic>> get getListTotalDiscount =>
      state.listTotalDiscount;
  double get getTotalDiscount => state.totalDiscount;
  List<Map<String, dynamic>> get getListTaxAfterDiscount =>
      state.listTaxAfterDiscount;
  double get getTaxAfterDiscount => state.taxAfterDiscount;
  List<Map<String, dynamic>> get getListTaxIncludedAfterDiscount =>
      state.listTaxIncludedAfterDiscount;
  double get getTaxIncludedAfterDiscount => state.taxIncludedAfterDiscount;
  double get getTotalAfterDiscountAndTax => state.totalAfterDiscountAndTax;
  List<Map<String, dynamic>> get getListTotalAfterDiscAndTax =>
      state.listTotalAfterDiscAndTax;

  // State setters
  void addOrUpdateOriginRefundItems(ReceiptItemModel originRI) {
    final List<ReceiptItemModel> originItems = List.from(
      state.originRefundItems,
    );
    final originIndex = originItems.indexWhere((ri) => ri.id == originRI.id);
    if (originIndex != -1) {
      originItems[originIndex] = originRI;
    } else {
      originItems.add(originRI);
    }
    state = state.copyWith(originRefundItems: originItems);
  }

  void calcTotalAfterDiscountAndTax() {
    double total = state.listTotalAfterDiscAndTax.fold(0, (total, map) {
      total += map['totalAfterDiscAndTax'] ?? 0;
      return total;
    });
    state = state.copyWith(totalAfterDiscountAndTax: total);
  }

  void calcTotalDiscount() {
    double total = state.listTotalDiscount.fold(0, (total, discountMap) {
      total += discountMap['discountTotal'] ?? 0;
      return total;
    });
    state = state.copyWith(totalDiscount: total);
  }

  void calcTaxAfterDiscount() {
    double total = state.listTaxAfterDiscount.fold(0, (total, taxMap) {
      total += taxMap['taxAfterDiscount'] ?? 0;
      return total;
    });
    state = state.copyWith(taxAfterDiscount: total);
  }

  void calcTaxIncludedAfterDiscount() {
    double total = state.listTaxIncludedAfterDiscount.fold(0, (total, taxMap) {
      total += taxMap['taxIncludedAfterDiscount'] ?? 0;
      return total;
    });
    state = state.copyWith(taxIncludedAfterDiscount: total);
  }

  void clearAllOldNotifier() {
    state = state.copyWith(
      listTotalDiscount: [],
      listTaxAfterDiscount: [],
      listTotalAfterDiscAndTax: [],
      listTaxIncludedAfterDiscount: [],
      refundItems: [],
      originRefundItems: [],
    );

    calcTaxAfterDiscount();
    calcTaxIncludedAfterDiscount();
    calcTotalAfterDiscountAndTax();
    calcTotalDiscount();
  }

  void removeRefundItemFromNotifier(String receiptItemId, DateTime updatedAt) {
    final items = List<ReceiptItemModel>.from(state.refundItems);
    items.removeWhere(
      (element) =>
          element.id == receiptItemId && element.updatedAt == updatedAt,
    );
    state = state.copyWith(refundItems: items);
  }

  void reCalculateAllTotal(String receiptItemId, DateTime updatedAt) {
    removeDiscountTaxAndTotal(receiptItemId, updatedAt);

    calcTaxAfterDiscount();
    calcTaxIncludedAfterDiscount();
    calcTotalAfterDiscountAndTax();
    calcTotalDiscount();
  }

  void removeDiscountTaxAndTotal(String receiptItemId, DateTime updatedAt) {
    final listTotalDisc = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDisc = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDisc = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    listTotalDisc.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTaxAfterDisc.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTaxIncludedAfterDisc.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTotalAfterDiscAndTax.removeWhere(
      (element) =>
          element['receiptItemId'] == receiptItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );

    state = state.copyWith(
      listTotalDiscount: listTotalDisc,
      listTaxAfterDiscount: listTaxAfterDisc,
      listTaxIncludedAfterDiscount: listTaxIncludedAfterDisc,
      listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
    );
  }

  double calcEachTotalAfterDiscountAndTax(ReceiptItemModel receiptItem) {
    double total =
        (receiptItem.price!) +
        receiptItem.totalTax! -
        receiptItem.totalDiscount!;

    return total;
  }

  // Complex old notifier methods with full calculation logic
  void addItemToRefundOldNotifier(
    ReceiptItemModel refundItem,
    ReceiptItemModel originRI,
  ) {
    final refundItems = List<ReceiptItemModel>.from(state.refundItems);
    final originRefundItems = List<ReceiptItemModel>.from(
      state.originRefundItems,
    );
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    ReceiptItemModel selectedRI = refundItems.firstWhere(
      (element) => element.id == refundItem.id,
      orElse: () => ReceiptItemModel(),
    );

    ReceiptItemModel oriRI = originRefundItems.firstWhere(
      (element) => element.id == refundItem.id,
      orElse: () => ReceiptItemModel(),
    );

    if (selectedRI.id != null) {
      // means refund item is exist, update qty, price, discountTotal, totalAfterDiscAndTax, taxAfterDiscount, taxIncludedAfterDiscount
      double perPrice =
          selectedRI.soldBy == ItemSoldByEnum.item
              ? (selectedRI.grossAmount! / selectedRI.quantity!)
              : selectedRI.grossAmount!;

      prints('ORIGIN TOTAL DISCOUNT: ${oriRI.totalDiscount}');
      prints('REFUND TOTAL DISCOUNT: ${refundItem.totalDiscount}');
      double newTotalDiscounts =
          oriRI.totalDiscount! - refundItem.totalDiscount!;

      double newTaxAfterDiscount = oriRI.totalTax! - refundItem.totalTax!;
      double newTaxIncludedAfterDiscount =
          oriRI.taxIncludedAfterDiscount! -
          refundItem.taxIncludedAfterDiscount!;
      if (selectedRI.soldBy == ItemSoldByEnum.item) {
        selectedRI.quantity = selectedRI.quantity! + 1;
      } else if (selectedRI.soldBy == ItemSoldByEnum.measurement) {
        selectedRI.quantity = refundItem.quantity!;
      }
      selectedRI.grossAmount = perPrice * selectedRI.quantity!;
      selectedRI.price = selectedRI.price! + perPrice;
      selectedRI.totalDiscount = newTotalDiscounts;
      selectedRI.totalTax = newTaxAfterDiscount;
      selectedRI.taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;

      /// update the [discountTotal] and [taxAfterDiscount] and [taxIncludedAfterDiscount] and [totalAfterDiscAndTax]
      /// find [discountTotal]
      final discountMap = listTotalDiscount.firstWhere(
        (element) =>
            element['receiptItemId'] == selectedRI.id &&
            element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
        orElse: () => {},
      );

      /// find [taxAfterDiscount]
      final taxAfterDiscountMap = listTaxAfterDiscount.firstWhere(
        (element) =>
            element['receiptItemId'] == selectedRI.id &&
            element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
        orElse: () => {},
      );

      /// find [taxIncludedAfterDiscount]
      final taxIncludedAfterDiscountMap = listTaxIncludedAfterDiscount
          .firstWhere(
            (element) =>
                element['receiptItemId'] == selectedRI.id &&
                element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
            orElse: () => {},
          );

      /// find [totalAfterDiscAndTax]
      final totalAfterDiscAndTaxMap = listTotalAfterDiscAndTax.firstWhere(
        (element) =>
            element['receiptItemId'] == selectedRI.id &&
            element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
        orElse: () => {},
      );

      /// assign new values to the [discountTotal] and [totalAfterDiscAndTax]  and [taxAfterDiscount]
      if (discountMap.isNotEmpty) {
        double discountTotal = newTotalDiscounts;
        discountMap['receiptItemId'] = selectedRI.id;
        discountMap['updatedAt'] = selectedRI.updatedAt!.toIso8601String();
        discountMap['discountTotal'] = discountTotal;

        selectedRI.totalDiscount = discountTotal;
      } else {
        prints('FX addItemToRefund discountTotal is null');
      }

      if (taxAfterDiscountMap.isNotEmpty) {
        double taxAfterDiscount = newTaxAfterDiscount; // 5 * 1.90
        taxAfterDiscountMap['receiptItemId'] = selectedRI.id;
        taxAfterDiscountMap['updatedAt'] =
            selectedRI.updatedAt!.toIso8601String();
        taxAfterDiscountMap['taxAfterDiscount'] = taxAfterDiscount;

        // continue update the selectedSI
        selectedRI.totalTax = taxAfterDiscount;
      } else {
        prints('FX addItemToRefund taxAfterDiscount is null');
      }

      if (taxIncludedAfterDiscountMap.isNotEmpty) {
        double taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;
        taxIncludedAfterDiscountMap['receiptItemId'] = selectedRI.id;
        taxIncludedAfterDiscountMap['updatedAt'] =
            selectedRI.updatedAt!.toIso8601String();
        taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'] =
            taxIncludedAfterDiscount;

        selectedRI.taxIncludedAfterDiscount = taxIncludedAfterDiscount;
      } else {
        prints('FX addItemToRefund taxIncludedAfterDiscount is null');
      }

      if (totalAfterDiscAndTaxMap.isNotEmpty) {
        double totalAfterDiscAndTax = calcEachTotalAfterDiscountAndTax(
          selectedRI,
        );

        totalAfterDiscAndTaxMap['receiptItemId'] = selectedRI.id;
        totalAfterDiscAndTaxMap['updatedAt'] =
            selectedRI.updatedAt!.toIso8601String();
        totalAfterDiscAndTaxMap['totalAfterDiscAndTax'] = totalAfterDiscAndTax;

        // continue update the selectedRI
        // selectedRI.totalAfterDiscAndTax =
        //     totalAfterDiscAndTaxMap['totalAfterDiscAndTax'];
      } else {
        prints('FX addItemToRefund totalAfterDiscAndTax is null');
      }

      // find index of the saleItem to update it
      int indexSaleItem = refundItems.indexWhere(
        (element) =>
            element.id == selectedRI.id &&
            element.updatedAt == selectedRI.updatedAt,
      );

      if (indexSaleItem != -1) {
        refundItems[indexSaleItem] = selectedRI;
      } else {
        prints('FX addItemToRefund indexSaleItem is null');
      }

      state = state.copyWith(
        refundItems: refundItems,
        originRefundItems: originRefundItems,
        listTotalDiscount: listTotalDiscount,
        listTaxAfterDiscount: listTaxAfterDiscount,
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );

      calcTotalAfterDiscountAndTax();
      calcTaxAfterDiscount();
      calcTaxIncludedAfterDiscount();
      calcTotalDiscount();
    } else {
      // add origin RI to originRefundItems
      if (oriRI.id == null) {
        originRefundItems.add(originRI);
      }
      // means refund item is not exist, add to list
      double perPrice =
          refundItem.soldBy == ItemSoldByEnum.item
              ? (refundItem.grossAmount! / refundItem.quantity!)
              : refundItem.grossAmount!;

      // prints('ORIGIN TOTAL DISCOUNT: ${originRI.totalDiscount}');
      // prints('REFUND TOTAL DISCOUNT: ${refundItem.totalDiscount}');
      double newTotalDiscount =
          originRI.totalDiscount! - refundItem.totalDiscount!;

      double newTaxAfterDiscount = originRI.totalTax! - refundItem.totalTax!;
      double newTaxIncludedAfterDiscount =
          originRI.taxIncludedAfterDiscount! -
          refundItem.taxIncludedAfterDiscount!;
      double newTotalPrice = perPrice + newTaxAfterDiscount - newTotalDiscount;
      // prints('newTaxAfterDiscount: $newTaxAfterDiscount');
      // prints('newTotalDiscount: $newTotalDiscount');
      // prints('PER PRICE: $perPrice');
      // prints('refundItem.quantity!: ${refundItem.quantity}');
      // prints('refundItem.price!: ${refundItem.price}');
      // prints('TOTAL ALL: $newTotalPrice');
      // generate new discountTotal, TotalAfterDiscAndTax, TaxAfterDiscount
      /// get [discountTotal]
      Map<String, dynamic> totalDiscountMap = {
        'discountTotal': newTotalDiscount,
        'receiptItemId': refundItem.id,
        'updatedAt': refundItem.updatedAt!.toIso8601String(),
      };

      /// get [taxAfterDiscount]
      double taxAfterDiscount = newTaxAfterDiscount;
      Map<String, dynamic> taxAfterDiscountMap = {
        'taxAfterDiscount': taxAfterDiscount,
        'receiptItemId': refundItem.id,
        'updatedAt': refundItem.updatedAt!.toIso8601String(),
      };

      double taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;
      Map<String, dynamic> taxIncludedAfterDiscountMap = {
        'taxIncludedAfterDiscount': taxIncludedAfterDiscount,
        'receiptItemId': refundItem.id,
        'updatedAt': refundItem.updatedAt!.toIso8601String(),
      };

      /// get [totalAfterDiscAndTax]
      double newTotalAfterDiscAndTax = newTotalPrice;

      Map<String, dynamic> totalAfterDiscAndTaxMap = {
        'totalAfterDiscAndTax': newTotalAfterDiscAndTax,
        'receiptItemId': refundItem.id,
        'updatedAt': refundItem.updatedAt!.toIso8601String(),
      };

      ReceiptItemModel newRI = refundItem.copyWith(
        quantity:
            refundItem.soldBy == ItemSoldByEnum.item ? 1 : refundItem.quantity,
        grossAmount: perPrice,
        price: perPrice,
        totalTax: newTaxAfterDiscount,
        taxIncludedAfterDiscount: newTaxIncludedAfterDiscount,
        totalDiscount: newTotalDiscount,
      );

      listTotalDiscount.add(totalDiscountMap);
      listTaxAfterDiscount.add(taxAfterDiscountMap);
      listTaxIncludedAfterDiscount.add(taxIncludedAfterDiscountMap);
      listTotalAfterDiscAndTax.add(totalAfterDiscAndTaxMap);

      refundItems.add(newRI);

      state = state.copyWith(
        refundItems: refundItems,
        originRefundItems: originRefundItems,
        listTotalDiscount: listTotalDiscount,
        listTaxAfterDiscount: listTaxAfterDiscount,
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );

      calcTotalAfterDiscountAndTax();
      calcTaxAfterDiscount();
      calcTaxIncludedAfterDiscount();
      calcTotalDiscount();
    }
  }

  void removeItemFromRefundAndMoveToReceipt(
    BuildContext context,
    ReceiptItemModel refundItem,
  ) {
    final refundItems = List<ReceiptItemModel>.from(state.refundItems);
    final originRefundItems = List<ReceiptItemModel>.from(
      state.originRefundItems,
    );
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    // find selected refund item
    ReceiptItemModel selectedRI = refundItems.firstWhere(
      (element) => element.id == refundItem.id,
      orElse: () => ReceiptItemModel(),
    );

    ReceiptItemModel oriRI = originRefundItems.firstWhere(
      (element) => element.id == refundItem.id,
      orElse: () => ReceiptItemModel(),
    );

    if (selectedRI.id != null) {
      double perPrice =
          selectedRI.soldBy == ItemSoldByEnum.item
              ? (selectedRI.grossAmount! / selectedRI.quantity!)
              : selectedRI.grossAmount!;
      // to get the price per tax to re calculate the new tax after discount
      prints(
        'SELECTED REFUND ITEM TOTAL DISCOUNT: ${selectedRI.totalDiscount}',
      );
      prints('SELECTED REFUND ITEM TOTAL QTY: ${selectedRI.quantity}');
      double pricePerTax = selectedRI.totalTax! / selectedRI.quantity!; // =1.90
      double pricePerTaxIncluded =
          selectedRI.taxIncludedAfterDiscount! / selectedRI.quantity!;
      double perDiscount = selectedRI.totalDiscount! / selectedRI.quantity!;
      if (selectedRI.quantity! > 1 &&
          selectedRI.soldBy == ItemSoldByEnum.item) {
        // minus one qty
        selectedRI.quantity = selectedRI.quantity! - 1;
        selectedRI.price = selectedRI.price! - perPrice;
        selectedRI.grossAmount = perPrice * selectedRI.quantity!;
        selectedRI.totalDiscount = selectedRI.totalDiscount! - perDiscount;
        selectedRI.totalTax = selectedRI.totalTax! - pricePerTax;
        selectedRI.taxIncludedAfterDiscount =
            selectedRI.taxIncludedAfterDiscount! - pricePerTaxIncluded;

        double newTotalDiscount = selectedRI.totalDiscount!;
        double newTotalTax = selectedRI.totalTax!;
        double newTaxIncludedAfterDiscount =
            selectedRI.taxIncludedAfterDiscount!;

        /// update the [discountTotal] and [taxAfterDiscount] and [taxIncludedAfterDiscount] and [totalAfterDiscAndTax]
        /// find [discountTotal]
        final discountMap = listTotalDiscount.firstWhere(
          (element) =>
              element['receiptItemId'] == selectedRI.id &&
              element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
          orElse: () => {},
        );

        /// find [taxAfterDiscount]
        final taxAfterDiscountMap = listTaxAfterDiscount.firstWhere(
          (element) =>
              element['receiptItemId'] == selectedRI.id &&
              element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
          orElse: () => {},
        );

        /// find [taxIncludedAfterDiscount]
        final taxIncludedAfterDiscountMap = listTaxIncludedAfterDiscount
            .firstWhere(
              (element) =>
                  element['receiptItemId'] == selectedRI.id &&
                  element['updatedAt'] ==
                      selectedRI.updatedAt!.toIso8601String(),
              orElse: () => {},
            );

        /// find [totalAfterDiscAndTax]
        final totalAfterDiscAndTaxMap = listTotalAfterDiscAndTax.firstWhere(
          (element) =>
              element['receiptItemId'] == selectedRI.id &&
              element['updatedAt'] == selectedRI.updatedAt!.toIso8601String(),
          orElse: () => {},
        );

        /// assign new values to the [discountTotal] and [taxAfterDiscount] and [taxIncludedAfterDiscount] and [totalAfterDiscAndTax]
        if (discountMap.isNotEmpty) {
          double totalDiscount = newTotalDiscount;
          discountMap['receiptItemId'] = selectedRI.id;
          discountMap['updatedAt'] = selectedRI.updatedAt!.toIso8601String();
          discountMap['discountTotal'] = totalDiscount;

          // continue update the selectedRI
          selectedRI.totalDiscount = totalDiscount;
        } else {
          prints(
            'FX removeItemFromRefundAndMoveToReceipt discountMap is empty',
          );
        }

        if (taxAfterDiscountMap.isNotEmpty) {
          double taxAfterDiscount = newTotalTax;
          taxAfterDiscountMap['receiptItemId'] = selectedRI.id;
          taxAfterDiscountMap['updatedAt'] =
              selectedRI.updatedAt!.toIso8601String();
          taxAfterDiscountMap['taxAfterDiscount'] = taxAfterDiscount;

          // continue update the selectedRI
          selectedRI.totalTax = taxAfterDiscount;
        } else {
          prints(
            'FX removeItemFromRefundAndMoveToReceipt taxAfterDiscountMap is empty',
          );
        }

        if (taxIncludedAfterDiscountMap.isNotEmpty) {
          double taxIncludedAfterDiscount = newTaxIncludedAfterDiscount;
          taxIncludedAfterDiscountMap['receiptItemId'] = selectedRI.id;
          taxIncludedAfterDiscountMap['updatedAt'] =
              selectedRI.updatedAt!.toIso8601String();
          taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'] =
              taxIncludedAfterDiscount;

          // continue update the selectedRI
          selectedRI.taxIncludedAfterDiscount = taxIncludedAfterDiscount;
        } else {
          prints(
            'FX removeItemFromRefundAndMoveToReceipt taxIncludedAfterDiscountMap is empty',
          );
        }

        if (totalAfterDiscAndTaxMap.isNotEmpty) {
          double totalAfterDiscAndTax = calcEachTotalAfterDiscountAndTax(
            selectedRI,
          );

          totalAfterDiscAndTaxMap['receiptItemId'] = selectedRI.id;
          totalAfterDiscAndTaxMap['updatedAt'] =
              selectedRI.updatedAt!.toIso8601String();
          totalAfterDiscAndTaxMap['totalAfterDiscAndTax'] =
              totalAfterDiscAndTax;

          // continue update the selectedRI
          // selectedRI.totalAfterDiscAndTax =
          //     totalAfterDiscAndTaxMap['totalAfterDiscAndTax'];
        } else {
          prints(
            'FX removeItemFromRefundAndMoveToReceipt totalAfterDiscAndTax is null',
          );
        }

        // find the index of the refund item to update
        int indexRefundItem = refundItems.indexWhere(
          (element) =>
              element.id == selectedRI.id &&
              element.updatedAt == selectedRI.updatedAt,
        );

        if (indexRefundItem != -1) {
          refundItems[indexRefundItem] = selectedRI;
        } else {
          prints(
            'FX removeItemFromRefundAndMoveToReceipt indexRefundItem is -1',
          );
        }

        state = state.copyWith(
          refundItems: refundItems,
          originRefundItems: originRefundItems,
          listTotalDiscount: listTotalDiscount,
          listTaxAfterDiscount: listTaxAfterDiscount,
          listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
          listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
        );

        calcTotalAfterDiscountAndTax();
        calcTaxAfterDiscount();
        calcTaxIncludedAfterDiscount();
        calcTotalDiscount();

        /// [PROCESS ADD ITEM TO RECEIPT NOTIFIER]

        _ref.read(receiptProvider.notifier).addItemToReceipt(selectedRI, oriRI);
      } else {
        selectedRI.totalDiscount = selectedRI.totalDiscount! - perDiscount;
        selectedRI.totalTax = selectedRI.totalTax! - pricePerTax;
        selectedRI.taxIncludedAfterDiscount =
            selectedRI.taxIncludedAfterDiscount! - pricePerTaxIncluded;
        _ref.read(receiptProvider.notifier).addItemToReceipt(selectedRI, oriRI);
        selectedRI.quantity = selectedRI.quantity! - 1;
        selectedRI.price = selectedRI.price! - perPrice;
        selectedRI.grossAmount = perPrice * selectedRI.quantity!;
        // remove from refund list because qty left 1

        removeRefundItemFromNotifier(selectedRI.id!, selectedRI.updatedAt!);
        reCalculateAllTotal(selectedRI.id!, selectedRI.updatedAt!);
      }
    }
  }

  // ============================================================================
  // END OLD NOTIFIER METHODS
  // ============================================================================

  /// Recalculate all totals based on current refund items
  void _recalculateTotals() {
    double totalDisc = 0.0;
    double totalTax = 0.0;
    double totalTaxIncluded = 0.0;
    double totalAfterDiscAndTax = 0.0;

    for (final item in state.refundItems) {
      // Sum up pre-calculated values from receipt items
      totalDisc += item.totalDiscount ?? 0.0;
      totalTax += item.totalTax ?? 0.0;
      totalTaxIncluded += item.taxIncludedAfterDiscount ?? 0.0;
      // Use price as the final amount
      totalAfterDiscAndTax += item.price ?? 0.0;
    }

    state = state.copyWith(
      totalDiscount: totalDisc,
      taxAfterDiscount: totalTax,
      taxIncludedAfterDiscount: totalTaxIncluded,
      totalAfterDiscountAndTax: totalAfterDiscAndTax,
    );
  }
}

/// Provider for refund domain
final refundProvider = StateNotifierProvider<RefundNotifier, RefundState>((
  ref,
) {
  return RefundNotifier(
    localPrinterSettingRepository:
        ServiceLocator.get<LocalPrinterSettingRepository>(),
    ref: ref,
  );
});
