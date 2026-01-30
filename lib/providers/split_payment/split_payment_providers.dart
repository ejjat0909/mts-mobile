import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/calc_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/split_payment/split_payment_state.dart';
import 'package:mts/providers/tax/tax_providers.dart';

class SplitPaymentNotifier extends StateNotifier<SplitPaymentState> {
  final Ref _ref;

  SplitPaymentNotifier(this._ref) : super(const SplitPaymentState());

  List<SaleItemModel> get getSaleItems => state.saleItems;
  List<SaleModifierModel> get getSaleModifiers => state.saleModifiers;
  List<SaleModifierOptionModel> get getSaleModifierOptions =>
      state.saleModifierOptions;
  List<Map<String, dynamic>> get getListTotalDiscount =>
      state.listTotalDiscount;
  List<Map<String, dynamic>> get getListTaxAfterDiscount =>
      state.listTaxAfterDiscount;
  List<Map<String, dynamic>> get getListTaxIncludedAfterDiscount =>
      state.listTaxIncludedAfterDiscount;
  List<Map<String, dynamic>> get getListTotalAfterDiscAndTax =>
      state.listTotalAfterDiscAndTax;
  double get getTotalDiscount => state.totalDiscount;
  double get getTaxAfterDiscount => state.taxAfterDiscount;
  double get getTaxIncludedAfterDiscount => state.taxIncludedAfterDiscount;
  double get getTotalAfterDiscountAndTax => state.totalAfterDiscountAndTax;
  double get getTotalWithAdjustedPrice => state.totalWithAdjustedPrice;
  double get getAdjustedPrice => state.adjustedPrice;
  String? get getPaymentTypeName => state.paymentTypeName;
  PaymentTypeModel? get getPaymentTypeModel => state.paymentTypeModel;
  double get getTotalAmountRemaining => state.totalAmountRemaining;
  double get getTotalAmountPaid => state.totalAmountPaid;
  SaleModel? get getCurrSaleModel => state.currSaleModel;

  void clearSelectedSaleItems() {
    state = state.copyWith(
      saleItems: [],
      saleModifiers: [],
      saleModifierOptions: [],
      listTotalDiscount: [],
      listTaxAfterDiscount: [],
      listTaxIncludedAfterDiscount: [],
      listTotalAfterDiscAndTax: [],
      adjustedPrice: 0,
      totalWithAdjustedPrice: 0,
    );
  }

  void setAdjustedPrice(double price) {
    state = state.copyWith(adjustedPrice: price);
    calcTotalWithAdjustedPrice();
  }

  void setCurrSaleModel(SaleModel? saleModel) {
    state = state.copyWith(currSaleModel: saleModel);
  }

  double getTotalCosts() {
    double totalCosts = state.saleItems
        .map((e) => e.cost ?? 0.0)
        .fold(0.0, (total, cost) => total + cost);

    prints('Total Costs: $totalCosts');
    return totalCosts;
  }

  double getGrossAmountPerSaleItem(SaleItemModel saleItem) {
    // double netSale = getNetSalePerSaleItem(saleItem);
    // double discount = saleItem.discountTotal ?? 0.0;
    // double tax = saleItem.taxAfterDiscount ?? 0.0;

    // return netSale + discount - tax;

    // version baru
    // sale item price dah mmg gross
    return saleItem.price!;
  }

  /// Calculate net sales for a specific sale item
  /// Net sales = gross sale per item - discount of that item
  /// RM 10 x 5 = 50
  /// RM 15 x 3 = 45
  /// Discount = RM 20
  /// Net sales = RM 75
  double getNetSalePerSaleItem(SaleItemModel saleItem) {
    // Return the item's totalAfterDiscAndTax directly
    return getGrossAmountPerSaleItem(saleItem) - saleItem.discountTotal!;
  }

  double getNetSales() {
    double netSales = getSaleItems.fold(0, (total, saleItem) {
      total += getNetSalePerSaleItem(saleItem);

      return total;
    });

    return netSales - getAdjustedPrice;
  }

  double getGrossSales() {
    final listSaleItem = getSaleItems;
    double grossSales = listSaleItem.fold(0, (total, saleItem) {
      total += getGrossAmountPerSaleItem(saleItem);
      return total;
    });
    return grossSales;
  }

  void setPaymentTypeName(PaymentTypeModel? model) {
    state = state.copyWith(
      paymentTypeName: model?.name,
      paymentTypeModel: model,
    );
  }

  void calcTotalWithAdjustedPrice() {
    double totalWithAdjustedPrice =
        state.totalAfterDiscountAndTax - getAdjustedPrice;

    if (totalWithAdjustedPrice <= 0) {
      totalWithAdjustedPrice = 0;
    }

    double afterCashRounding = CalcUtils.calcCashRounding(
      totalWithAdjustedPrice,
    );

    if (afterCashRounding < 0) {
      afterCashRounding = 0;
    }

    prints('afterCashRounding $afterCashRounding');

    if (getPaymentTypeModel != null && getPaymentTypeModel!.autoRounding!) {
      prints('payment type have auto rounding');
      setTotalAmountRemaining(afterCashRounding);
    } else {
      prints('payment type not cash');
      setTotalAmountRemaining(totalWithAdjustedPrice);
    }

    state = state.copyWith(totalWithAdjustedPrice: totalWithAdjustedPrice);
  }

  void setTotalAmountRemaining(double amount) {
    // preserve the previous value before updating
    final totalAmountPaid = state.totalAmountRemaining;
    // update the remaining amount
    state = state.copyWith(
      totalAmountRemaining: amount,
      totalAmountPaid: totalAmountPaid,
    );
  }

  void calcTotalDiscount() {
    final totalDiscount = state.listTotalDiscount.fold(0.0, (
      total,
      discountMap,
    ) {
      total += (discountMap['discountTotal'] ?? 0).toDouble();
      return total;
    });
    // prints(totalDiscount);
    // prints(state.listTotalDiscount);

    state = state.copyWith(totalDiscount: totalDiscount);
  }

  void calcTaxAfterDiscount() {
    // totalTax = (pricePerItem * taxID) * quantity

    final taxAfterDiscount = state.listTaxAfterDiscount.fold(0.0, (
      total,
      taxMap,
    ) {
      total += (taxMap['taxAfterDiscount'] ?? 0).toDouble();
      return total;
    });

    // prints(taxAfterDiscount);
    // prints(state.listTaxAfterDiscount);

    state = state.copyWith(taxAfterDiscount: taxAfterDiscount);
  }

  void calcTaxIncludedAfterDiscount() {
    final taxIncludedAfterDiscount = state.listTaxIncludedAfterDiscount.fold(
      0.0,
      (total, map) {
        total += (map['taxIncludedAfterDiscount'] ?? 0).toDouble();
        return total;
      },
    );

    state = state.copyWith(taxIncludedAfterDiscount: taxIncludedAfterDiscount);
  }

  void calcTotalAfterDiscountAndTax() {
    final totalAfterDiscountAndTax = state.listTotalAfterDiscAndTax.fold(0.0, (
      total,
      map,
    ) {
      total += (map['totalAfterDiscAndTax'] ?? 0).toDouble();
      return total;
    });

    state = state.copyWith(totalAfterDiscountAndTax: totalAfterDiscountAndTax);
  }

  Future<void> addItemToSplitPayment(
    SaleItemModel saleItem,
    ItemModel itemModel,
    List<TaxModel> taxModels,
    List<SaleModifierModel> listSM,
    List<SaleModifierOptionModel> listSMO,
  ) async {
    final saleItems = List<SaleItemModel>.from(state.saleItems);
    final saleModifiers = List<SaleModifierModel>.from(state.saleModifiers);
    final saleModifierOptions = List<SaleModifierOptionModel>.from(
      state.saleModifierOptions,
    );

    SaleItemModel selectedSI = saleItems.firstWhere(
      (si) => si.id == saleItem.id,
      orElse: () => SaleItemModel(),
    );

    if (selectedSI.id != null) {
      double perPrice = selectedSI.price! / selectedSI.quantity!;

      if (selectedSI.soldBy == ItemSoldByEnum.item) {
        selectedSI.quantity = selectedSI.quantity! + 1;
        selectedSI.price = perPrice * selectedSI.quantity!;
      } else if (selectedSI.soldBy == ItemSoldByEnum.measurement) {
        selectedSI.quantity = saleItem.quantity;
        selectedSI.price = selectedSI.price! * selectedSI.quantity!;
      }

      DateTime now = selectedSI.updatedAt!;
      String newSaleItemId = selectedSI.id!;
      double newQty = selectedSI.quantity!;
      double newPrice = selectedSI.price!;

      final discountTotalMap = _updateTotalDiscount(
        saleItemExisting: selectedSI,
        now: now,
        itemModel: itemModel,
        newSaleItemId: newSaleItemId,
        updatedQty: newQty,
        saleItemPrice: newPrice,
      );

      final taxAfterDiscountMap = _updateTaxAfterDiscount(
        saleItemExisting: selectedSI,
        now: now,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: newPrice,
        newSaleItemId: newSaleItemId,
        updatedQty: newQty,
        saleItemPrice: newPrice,
      );

      final taxIncludedAfterDiscountMap = _updateTaxIncludedAfterDiscount(
        saleItemExisting: selectedSI,
        priceUpdated: newPrice,
        taxModels: taxModels,
        now: now,
        itemModel: itemModel,
        newSaleItemId: newSaleItemId,
        updatedQty: newQty,
        saleItemPrice: newPrice,
      );

      final totalAfterDiscountAndTaxMap = _updateTotalAfterDiscountAndTax(
        saleItemExisting: selectedSI,
        now: now,
        itemModel: itemModel,
        taxModels: taxModels,
        saleItemPrice: newPrice,
        newSaleItemId: newSaleItemId,
        updatedQty: newQty,
      );

      int indexSaleItem = saleItems.indexWhere(
        (element) =>
            element.id == selectedSI.id &&
            element.updatedAt == selectedSI.updatedAt,
      );

      selectedSI = selectedSI.copyWith(
        discountTotal:
            discountTotalMap == null ? 0.00 : discountTotalMap['discountTotal'],
        taxAfterDiscount:
            taxAfterDiscountMap == null
                ? 0.00
                : taxAfterDiscountMap['taxAfterDiscount'],
        taxIncludedAfterDiscount:
            taxIncludedAfterDiscountMap == null
                ? 0.00
                : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
        totalAfterDiscAndTax:
            totalAfterDiscountAndTaxMap == null
                ? 0.00
                : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
      );

      if (indexSaleItem != -1) {
        saleItems[indexSaleItem] = selectedSI;
      } else {
        prints('FX addItemToSplitPayment indexSaleItem is null');
      }

      state = state.copyWith(saleItems: saleItems);
      calcTotalAfterDiscountAndTax();
      calcTaxAfterDiscount();
      calcTaxIncludedAfterDiscount();
      calcTotalDiscount();
    } else {
      double perPrice =
          saleItem.soldBy == ItemSoldByEnum.item
              ? (saleItem.price! / saleItem.quantity!)
              : saleItem.price!;

      double newQty =
          saleItem.soldBy == ItemSoldByEnum.item ? 1 : saleItem.quantity!;

      final totalDiscountMap = _updateTotalDiscount(
        saleItemExisting: null,
        now: saleItem.updatedAt!,
        itemModel: itemModel,
        newSaleItemId: saleItem.id,
        updatedQty: newQty,
        saleItemPrice: perPrice,
      );

      final taxAfterDiscountMap = _updateTaxAfterDiscount(
        saleItemExisting: null,
        now: saleItem.updatedAt!,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: perPrice * newQty,
        newSaleItemId: saleItem.id,
        updatedQty: newQty,
        saleItemPrice: perPrice,
      );

      final taxIncludedAfterDiscountMap = _updateTaxIncludedAfterDiscount(
        saleItemExisting: null,
        now: saleItem.updatedAt!,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: perPrice * newQty,
        newSaleItemId: saleItem.id,
        updatedQty: newQty,
        saleItemPrice: perPrice,
      );

      final totalAfterDiscountAndTaxMap = _updateTotalAfterDiscountAndTax(
        saleItemExisting: null,
        now: saleItem.updatedAt!,
        itemModel: itemModel,
        taxModels: taxModels,
        saleItemPrice: perPrice,
        newSaleItemId: saleItem.id,
        updatedQty: newQty,
      );

      SaleItemModel newSI = saleItem.copyWith(
        quantity: newQty,
        price: perPrice,
        discountTotal:
            totalDiscountMap == null ? 0 : totalDiscountMap['discountTotal'],
        taxAfterDiscount:
            taxAfterDiscountMap == null
                ? 0
                : taxAfterDiscountMap['taxAfterDiscount'],
        taxIncludedAfterDiscount:
            taxIncludedAfterDiscountMap == null
                ? 0
                : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
        totalAfterDiscAndTax:
            totalAfterDiscountAndTaxMap == null
                ? 0
                : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
      );

      saleItems.add(newSI);
      saleModifiers.addAll(listSM);
      saleModifierOptions.addAll(listSMO);

      state = state.copyWith(
        saleItems: saleItems,
        saleModifiers: saleModifiers,
        saleModifierOptions: saleModifierOptions,
      );
      calcTotalAfterDiscountAndTax();
      calcTaxAfterDiscount();
      calcTaxIncludedAfterDiscount();
      calcTotalDiscount();
    }
  }

  Future<SaleItemModel?> removeSaleItemAndMoveToOrder(
    SaleItemModel saleItem,
    ItemModel itemModel,
  ) async {
    final taxNotifier = _ref.read(taxProvider.notifier);
    final saleItemsNotifier = _ref.read(saleItemProvider.notifier);

    final saleItems = List<SaleItemModel>.from(state.saleItems);
    SaleItemModel selectedSI = saleItems.firstWhere(
      (si) => si.id == saleItem.id,
      orElse: () => SaleItemModel(),
    );

    List<TaxModel> taxModels = [];
    taxModels = taxNotifier.getAllTaxModelsForThatItem(itemModel, taxModels);

    if (selectedSI.id != null) {
      double perPrice =
          selectedSI.soldBy == ItemSoldByEnum.item
              ? (selectedSI.price! / selectedSI.quantity!)
              : selectedSI.price!;

      List<SaleModifierModel> listSM =
          state.saleModifiers
              .where((element) => element.saleItemId == selectedSI.id)
              .toList();

      List<String> listSMIds = listSM.map((e) => e.id!).toList();

      List<SaleModifierOptionModel> listSMO =
          state.saleModifierOptions
              .where((smo) => listSMIds.contains(smo.saleModifierId))
              .toList();

      if (selectedSI.quantity! > 1 &&
          selectedSI.soldBy == ItemSoldByEnum.item) {
        if (selectedSI.soldBy == ItemSoldByEnum.item) {
          selectedSI.quantity = selectedSI.quantity! - 1;
        } else {
          selectedSI.quantity = selectedSI.quantity! - saleItem.quantity!;
        }
        selectedSI.price = perPrice * selectedSI.quantity!;

        double newQty = selectedSI.quantity!;
        double newPrice = selectedSI.price!;

        final discountTotalMap = _updateTotalDiscount(
          saleItemExisting: selectedSI,
          now: selectedSI.updatedAt!,
          itemModel: itemModel,
          newSaleItemId: selectedSI.id,
          updatedQty: newQty,
          saleItemPrice: newPrice,
        );

        final taxAfterDiscountMap = _updateTaxAfterDiscount(
          saleItemExisting: selectedSI,
          now: selectedSI.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: newPrice,
          newSaleItemId: selectedSI.id,
          updatedQty: newQty,
          saleItemPrice: newPrice,
        );

        final taxIncludedAfterDiscountMap = _updateTaxIncludedAfterDiscount(
          saleItemExisting: selectedSI,
          now: selectedSI.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: newPrice,
          newSaleItemId: selectedSI.id,
          updatedQty: newQty,
          saleItemPrice: newPrice,
        );

        final totalAfterDiscountAndTaxMap = _updateTotalAfterDiscountAndTax(
          saleItemExisting: selectedSI,
          now: selectedSI.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: newPrice,
          newSaleItemId: selectedSI.id,
          updatedQty: newQty,
        );

        int indexSaleItem = saleItems.indexWhere(
          (element) =>
              element.id == selectedSI.id &&
              element.updatedAt == selectedSI.updatedAt,
        );

        selectedSI = selectedSI.copyWith(
          discountTotal:
              discountTotalMap == null
                  ? 0.00
                  : discountTotalMap['discountTotal'],
          taxAfterDiscount:
              taxAfterDiscountMap == null
                  ? 0.00
                  : taxAfterDiscountMap['taxAfterDiscount'],
          taxIncludedAfterDiscount:
              taxIncludedAfterDiscountMap == null
                  ? 0.00
                  : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
          totalAfterDiscAndTax:
              totalAfterDiscountAndTaxMap == null
                  ? 0.00
                  : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
        );

        if (indexSaleItem != -1) {
          saleItems[indexSaleItem] = selectedSI;
        } else {
          prints('FX remove saleItem indexSaleItem is null');
        }

        state = state.copyWith(saleItems: saleItems);
        calcTotalAfterDiscountAndTax();
        calcTaxAfterDiscount();
        calcTaxIncludedAfterDiscount();
        calcTotalDiscount();

        saleItemsNotifier.addItemToOrder(
          saleItem,
          itemModel,
          taxModels,
          listSM,
          listSMO,
        );
      } else {
        saleItemsNotifier.addItemToOrder(
          saleItem,
          itemModel,
          taxModels,
          listSM,
          listSMO,
        );

        deleteSaleModifierModelAndSaleModifierOptionModel(
          saleItem.id!,
          saleItem.updatedAt!,
        );

        removeSaleItemFromNotifier(saleItem.id!, saleItem.updatedAt!);

        reCalculateAllTotal(saleItem.id!, saleItem.updatedAt!);
      }
    }

    return null;
  }

  void reCalculateAllTotal(String saleItemId, DateTime updatedAt) {
    removeDiscountTaxAndTotal(saleItemId, updatedAt);

    calcTaxAfterDiscount();
    calcTotalAfterDiscountAndTax();
    calcTaxIncludedAfterDiscount();
    calcTotalDiscount();
  }

  void removeDiscountTaxAndTotal(String saleItemId, DateTime updatedAt) {
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

    listTotalDiscount.removeWhere(
      (element) =>
          element['saleItemId'] == saleItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTaxAfterDiscount.removeWhere(
      (element) =>
          element['saleItemId'] == saleItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTaxIncludedAfterDiscount.removeWhere(
      (element) =>
          element['saleItemId'] == saleItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );
    listTotalAfterDiscAndTax.removeWhere(
      (element) =>
          element['saleItemId'] == saleItemId &&
          element['updatedAt'] == updatedAt.toIso8601String(),
    );

    prints('AFTER _listTotalAfterDiscountAndTax');
    //  prints(listTotalAfterDiscAndTax);

    state = state.copyWith(
      listTotalDiscount: listTotalDiscount,
      listTaxAfterDiscount: listTaxAfterDiscount,
      listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
      listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
    );
  }

  void removeSaleItemFromNotifier(String saleItemId, DateTime updatedAt) {
    final saleItems = List<SaleItemModel>.from(state.saleItems);
    saleItems.removeWhere(
      (element) => element.id == saleItemId && element.updatedAt == updatedAt,
    );

    state = state.copyWith(saleItems: saleItems);
  }

  void deleteSaleModifierModelAndSaleModifierOptionModel(
    String saleItemModelId,
    DateTime updatedAt,
  ) {
    List<String> saleModifierIdsToRemove = [];

    final saleModifiers = List<SaleModifierModel>.from(state.saleModifiers);
    final saleModifierOptions = List<SaleModifierOptionModel>.from(
      state.saleModifierOptions,
    );

    /// remove first the related [saleModifierModel]
    /// but dont forget to add [saleModifierId] into the list [saleModifierIdsToRemove]

    saleModifiers.removeWhere((element) {
      bool shouldRemove =
          element.saleItemId == saleItemModelId &&
          element.updatedAt == updatedAt;
      if (shouldRemove) {
        saleModifierIdsToRemove.add(element.id!);
      }
      return shouldRemove;
    });

    /// then remove the saleModifierOptionModel

    for (String saleModifierId in saleModifierIdsToRemove) {
      saleModifierOptions.removeWhere((element) {
        return element.saleModifierId == saleModifierId;
      });
    }

    state = state.copyWith(
      saleModifiers: saleModifiers,
      saleModifierOptions: saleModifierOptions,
    );
  }

  // void removeItem(SaleItemModel saleItem) {
  //   final existingSaleItemIndex =
  //       selectedSaleItems.indexWhere((item) => item.itemId == saleItem.itemId);
  //   // Check if the item is already in the list
  //   // final existingItem = selectedSaleItems.firstWhere(
  //   //   (i) => i.id == saleItem.id,
  //   //   orElse: () => SaleItemModel(),
  //   // );

  //   if (existingSaleItemIndex != -1) {
  //     final existingSaleItem = selectedSaleItems[existingSaleItemIndex];
  //     // If the item exists, decrease the quantity
  //     ItemModel itemModel =
  //         ItemModel.getItemModelById(existingSaleItem.itemId!)!;
  //     double rateTax = TaxModel.getRateById(existingSaleItem.taxId!)!;
  //     if (existingSaleItem.quantity! > 1) {
  //       existingSaleItem.quantity = existingSaleItem.quantity! - 1;
  //       existingSaleItem.price =
  //           existingSaleItem.quantity! * itemModel.price! * (rateTax + 1);
  //     } else {
  //       // If the quantity is 1, remove the item from the list
  //       selectedSaleItems.remove(existingSaleItem);
  //     }
  //   }

  //   notifyListeners();
  // }

  double get subtotal {
    return state.saleItems.fold(0, (total, saleItem) {
      double pricePerItem = saleItem.price! / saleItem.quantity!;

      total += (pricePerItem * saleItem.quantity!);
      return total;
    });
  }

  List<Map<String, dynamic>> getOrderList() {
    // Pre-index saleModifiers by saleItemId

    final Map<String, List<String>> saleModifierIdsMap = {};
    final saleModifiers = List<SaleModifierModel>.from(state.saleModifiers);
    final saleModifierOptions = List<SaleModifierOptionModel>.from(
      state.saleModifierOptions,
    );

    for (final saleModifier in saleModifiers) {
      final saleItemId = saleModifier.saleItemId;
      if (saleItemId == null) continue;
      saleModifierIdsMap
          .putIfAbsent(saleItemId, () => [])
          .add(saleModifier.id!);
    }

    // Pre-index modifierOptions by saleModifierId
    final Map<String, List<String>> modifierOptionIdsMap = {};
    for (final option in saleModifierOptions) {
      final saleModifierId = option.saleModifierId;
      if (saleModifierId == null) continue;
      modifierOptionIdsMap
          .putIfAbsent(saleModifierId, () => [])
          .add(option.modifierOptionId!);
    }

    // Pre-index _saleItems for quick lookup by composite key
    final Map<String, SaleItemModel> saleItemIndex = {
      for (var item in state.saleItems)
        '${item.id}_${item.variantOptionId}_${item.comments}_${item.updatedAt?.toIso8601String()}':
            item,
    };

    final modifierOptionNotifier = _ref.read(modifierOptionProvider.notifier);
    final itemNotifier = _ref.read(itemProvider.notifier);

    return state.saleItems.map((saleItem) {
      // Use precomputed maps
      final saleModifierIds = saleModifierIdsMap[saleItem.id] ?? [];
      final List<String> modifierOptionIds = [];
      for (final saleModifierId in saleModifierIds) {
        modifierOptionIds.addAll(modifierOptionIdsMap[saleModifierId] ?? []);
      }
      final allModifierOptionName = modifierOptionNotifier
          .getModifierOptionNameFromListIds(modifierOptionIds);
      // Avoid full list search with a composite key
      final usedSaleItemKey =
          '${saleItem.id}_${saleItem.variantOptionId}_${saleItem.comments}_${saleItem.updatedAt?.toIso8601String()}';

      final usedSaleItemModel =
          saleItemIndex[usedSaleItemKey] ?? SaleItemModel();

      final itemModel = itemNotifier.getItemById(usedSaleItemModel.itemId!);
      final variantOptionModel = itemNotifier.getVariantOptionModelById(
        usedSaleItemModel.variantOptionId,
        usedSaleItemModel.itemId,
      );
      return {
        DataEnum.saleItemModel: saleItem,
        DataEnum.itemModel: itemModel,
        DataEnum.allModifierOptionNames: allModifierOptionName,
        DataEnum.variantOptionNames: variantOptionModel?.name,
        DataEnum.usedSaleItemModel: usedSaleItemModel,
      };
    }).toList();
  }

  Map<String, dynamic>? _updateTotalDiscount({
    required SaleItemModel? saleItemExisting,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) {
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );

    final saleItemNotifier = _ref.read(saleItemProvider.notifier);

    final double newTotalDiscount = saleItemNotifier.discountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: saleItemPrice / updatedQty,
    );

    final nowIso = now.toIso8601String();

    if (saleItemExisting == null) {
      final newDiscountMap = <String, dynamic>{
        'discountTotal': newTotalDiscount,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };
      listTotalDiscount.add(newDiscountMap);
      state = state.copyWith(listTotalDiscount: listTotalDiscount);
      return newDiscountMap;
    }

    final saleItemId = saleItemExisting.id;
    final saleItemUpdatedAt = saleItemExisting.updatedAt!.toIso8601String();

    int discountMapIndex = -1;
    for (int i = 0; i < listTotalDiscount.length; i++) {
      if (listTotalDiscount[i]['saleItemId'] == saleItemId &&
          listTotalDiscount[i]['updatedAt'] == saleItemUpdatedAt) {
        discountMapIndex = i;
        break;
      }
    }

    if (discountMapIndex != -1) {
      final updatedMap = Map<String, dynamic>.from(
        listTotalDiscount[discountMapIndex],
      );

      if (newSaleItemId != null) {
        updatedMap['saleItemId'] = newSaleItemId;
      }

      updatedMap['discountTotal'] = newTotalDiscount;
      updatedMap['updatedAt'] = nowIso;

      listTotalDiscount[discountMapIndex] = updatedMap;
      state = state.copyWith(listTotalDiscount: listTotalDiscount);
      return updatedMap;
    } else {
      final newDiscountMap = <String, dynamic>{
        'discountTotal': newTotalDiscount,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTotalDiscount.add(newDiscountMap);
      state = state.copyWith(listTotalDiscount: listTotalDiscount);
      return newDiscountMap;
    }
  }

  Map<String, dynamic>? _updateTaxIncludedAfterDiscount({
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) {
    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );

    final nowIso = now.toIso8601String();
    final updatedPrice = priceUpdated;
    final saleItemNotifier = _ref.read(saleItemProvider.notifier);

    final double newTaxIncludedAfterDiscount = saleItemNotifier
        .getTaxIncludedAfterDiscountPerItem(
          updatedPrice,
          taxModels,
          itemModel,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    if (saleItemExisting == null) {
      final newTaxIncludedMap = <String, dynamic>{
        'taxIncludedAfterDiscount': newTaxIncludedAfterDiscount,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTaxIncludedAfterDiscount.add(newTaxIncludedMap);
      state = state.copyWith(
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
      );
      return newTaxIncludedMap;
    }

    final saleItemId = saleItemExisting.id;
    final saleItemUpdatedAt = saleItemExisting.updatedAt!.toIso8601String();

    int taxIncludedMapIndex = -1;
    for (int i = 0; i < listTaxIncludedAfterDiscount.length; i++) {
      if (listTaxIncludedAfterDiscount[i]['saleItemId'] == saleItemId &&
          listTaxIncludedAfterDiscount[i]['updatedAt'] == saleItemUpdatedAt) {
        taxIncludedMapIndex = i;
        break;
      }
    }

    if (taxIncludedMapIndex != -1) {
      final updatedMap = Map<String, dynamic>.from(
        listTaxIncludedAfterDiscount[taxIncludedMapIndex],
      );

      if (newSaleItemId != null) {
        updatedMap['saleItemId'] = newSaleItemId;
      }

      updatedMap['taxIncludedAfterDiscount'] = newTaxIncludedAfterDiscount;
      updatedMap['updatedAt'] = nowIso;

      listTaxIncludedAfterDiscount[taxIncludedMapIndex] = updatedMap;
      state = state.copyWith(
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
      );
      return updatedMap;
    } else {
      final newTaxIncludedMap = <String, dynamic>{
        'taxIncludedAfterDiscount': newTaxIncludedAfterDiscount,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTaxIncludedAfterDiscount.add(newTaxIncludedMap);
      state = state.copyWith(
        listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
      );
      return newTaxIncludedMap;
    }
  }

  Map<String, dynamic>? _updateTaxAfterDiscount({
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) {
    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );

    final nowIso = now.toIso8601String();
    final updatedPrice = priceUpdated;

    final saleItemNotifier = _ref.read(saleItemProvider.notifier);

    final double newTaxAfterDiscount = saleItemNotifier
        .getTaxAfterDiscountPerItem(
          updatedPrice,
          taxModels,
          itemModel,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    if (saleItemExisting == null) {
      final newTaxAfterDiscountMap = <String, dynamic>{
        'taxAfterDiscount': newTaxAfterDiscount,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTaxAfterDiscount.add(newTaxAfterDiscountMap);
      state = state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount);
      return newTaxAfterDiscountMap;
    }

    final saleItemId = saleItemExisting.id;
    final saleItemUpdatedAt = saleItemExisting.updatedAt!.toIso8601String();

    int taxMapIndex = -1;
    for (int i = 0; i < listTaxAfterDiscount.length; i++) {
      if (listTaxAfterDiscount[i]['saleItemId'] == saleItemId &&
          listTaxAfterDiscount[i]['updatedAt'] == saleItemUpdatedAt) {
        taxMapIndex = i;
        break;
      }
    }

    if (taxMapIndex != -1) {
      final updatedMap = Map<String, dynamic>.from(
        listTaxAfterDiscount[taxMapIndex],
      );

      if (newSaleItemId != null) {
        updatedMap['saleItemId'] = newSaleItemId;
      }

      updatedMap['taxAfterDiscount'] = newTaxAfterDiscount;
      updatedMap['updatedAt'] = nowIso;

      listTaxAfterDiscount[taxMapIndex] = updatedMap;
      state = state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount);
      return updatedMap;
    } else {
      final newTaxAfterDiscountMap = <String, dynamic>{
        'taxAfterDiscount': newTaxAfterDiscount,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTaxAfterDiscount.add(newTaxAfterDiscountMap);
      state = state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount);
      return newTaxAfterDiscountMap;
    }
  }

  Map<String, dynamic>? _updateTotalAfterDiscountAndTax({
    required SaleItemModel? saleItemExisting,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
  }) {
    final listTotalAfterDiscAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscAndTax,
    );

    final nowIso = now.toIso8601String();
    final updatedPrice = saleItemPrice;

    final saleItemNotifier = _ref.read(saleItemProvider.notifier);

    final double newTotalAfterDiscountAndTax = saleItemNotifier
        .totalAfterDiscountAndTax(
          updatedPrice,
          itemModel,
          taxModels,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    if (saleItemExisting == null) {
      final newTotalAfterDiscAndTaxMap = <String, dynamic>{
        'totalAfterDiscAndTax': newTotalAfterDiscountAndTax,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTotalAfterDiscAndTax.add(newTotalAfterDiscAndTaxMap);
      state = state.copyWith(
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );
      return newTotalAfterDiscAndTaxMap;
    }

    final saleItemId = saleItemExisting.id;
    final saleItemUpdatedAt = saleItemExisting.updatedAt!.toIso8601String();

    int totalAfterDiscTaxMapIndex = -1;
    for (int i = 0; i < listTotalAfterDiscAndTax.length; i++) {
      if (listTotalAfterDiscAndTax[i]['saleItemId'] == saleItemId &&
          listTotalAfterDiscAndTax[i]['updatedAt'] == saleItemUpdatedAt) {
        totalAfterDiscTaxMapIndex = i;
        break;
      }
    }

    if (totalAfterDiscTaxMapIndex != -1) {
      final updatedMap = Map<String, dynamic>.from(
        listTotalAfterDiscAndTax[totalAfterDiscTaxMapIndex],
      );

      if (newSaleItemId != null) {
        updatedMap['saleItemId'] = newSaleItemId;
      }

      updatedMap['totalAfterDiscAndTax'] = newTotalAfterDiscountAndTax;
      updatedMap['updatedAt'] = nowIso;

      listTotalAfterDiscAndTax[totalAfterDiscTaxMapIndex] = updatedMap;
      state = state.copyWith(
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );
      return updatedMap;
    } else {
      final newTotalAfterDiscAndTaxMap = <String, dynamic>{
        'totalAfterDiscAndTax': newTotalAfterDiscountAndTax,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTotalAfterDiscAndTax.add(newTotalAfterDiscAndTaxMap);
      state = state.copyWith(
        listTotalAfterDiscAndTax: listTotalAfterDiscAndTax,
      );
      return newTotalAfterDiscAndTaxMap;
    }
  }
}

final splitPaymentProvider =
    StateNotifierProvider<SplitPaymentNotifier, SplitPaymentState>(
      (ref) => SplitPaymentNotifier(ref),
    );
