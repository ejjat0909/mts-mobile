import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_calculation_helper.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';

/// Helper class for sale item split payment operations
/// Handles moving items between order and split payment
class SaleItemSplitHelper {
  final Ref _ref;
  final SaleItemCalculationHelper _calculationHelper;

  SaleItemSplitHelper(this._ref, this._calculationHelper);

  /// Remove sale item and move to split payment
  /// Used when splitting an order
  Future<SaleItemModel?> removeSaleItemAndMoveToSplit({
    required SaleItemModel saleItem,
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required Function(String, DateTime)
    deleteSaleModifierModelAndSaleModifierOptionModel,
    required Function(String, DateTime) removeSaleItemFromNotifier,
    required Function(String, DateTime) reCalculateAllTotal,
    required Function() calcTotalAfterDiscountAndTax,
    required Function() calcTaxAfterDiscount,
    required Function() calcTotalDiscount,
    required Function() calcTotalWithAdjustedPrice,
    required Function() calcTaxIncludedAfterDiscount,
  }) async {
    // Early validation
    if (saleItem.id == null) return null;

    SaleItemModel selectedSI = state.saleItems.firstWhere(
      (si) => si.id == saleItem.id,
      orElse: () => SaleItemModel(),
    );

    // Early return if sale item not found
    if (selectedSI.id == null) return null;

    final taxNotifier = _ref.read(taxProvider.notifier);
    final List<TaxModel> taxModels = taxNotifier.getAllTaxModelsForThatItem(
      itemModel,
      <TaxModel>[],
    );

    // prints("qty");
    // prints(selectedSI.quantity);
    // prints(selectedSI.price);

    if (selectedSI.id != null) {
      double perPrice =
          selectedSI.soldBy == ItemSoldByEnum.item
              ? (selectedSI.price! / selectedSI.quantity!)
              : selectedSI.price!;
      List<SaleModifierModel> listSM =
          state.saleModifiers
              .where((element) => element.saleItemId == selectedSI.id)
              .toList();

      // extract saleModifiers ids from listSM
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

        /// update the [discountTotal, taxAfterDiscount, taxIncludedAfterDiscount, totalAfterDiscAndTax, customVariant]
        final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: selectedSI,
          now: selectedSI.updatedAt!,
          itemModel: itemModel,
          newSaleItemId: selectedSI.id,
          updatedQty: newQty,
          saleItemPrice: newPrice,
        );

        final taxAfterDiscountMap = await _calculationHelper.updatedTaxAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: selectedSI,
          now: selectedSI.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: newPrice,
          newSaleItemId: selectedSI.id,
          updatedQty: newQty,
          saleItemPrice: newPrice,
        );

        final taxIncludedAfterDiscountMap = await _calculationHelper
            .updatedTaxIncludedAfterDiscount(
              state: state,
              updateState: updateState,
              saleItemExisting: selectedSI,
              now: selectedSI.updatedAt!,
              itemModel: itemModel,
              taxModels: taxModels,
              priceUpdated: newPrice,
              newSaleItemId: selectedSI.id,
              updatedQty: newQty,
              saleItemPrice: newPrice,
            );

        final totalAfterDiscountAndTaxMap = await _calculationHelper
            .updatedTotalAfterDiscountAndTax(
              state: state,
              updateState: updateState,
              saleItemExisting: selectedSI,
              now: selectedSI.updatedAt!,
              itemModel: itemModel,
              taxModels: taxModels,
              saleItemPrice: newPrice,
              newSaleItemId: selectedSI.id,
              updatedQty: newQty,
            );

        // find index of the saleItem to update it
        int indexSaleItem = state.saleItems.indexWhere(
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
          final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
          updatedSaleItems[indexSaleItem] = selectedSI;
          updateState(state.copyWith(saleItems: updatedSaleItems));
        } else {
          prints('FX remove saleItem indexSaleItem is null');
        }

        calcTotalAfterDiscountAndTax();
        calcTaxAfterDiscount();
        calcTotalDiscount();
        calcTotalWithAdjustedPrice();
        calcTaxIncludedAfterDiscount();

        /// [PROCESS ADD ITEM TO SPLIT NOTIFIER]

        _ref
            .read(splitPaymentProvider.notifier)
            .addItemToSplitPayment(
              saleItem,
              itemModel,
              taxModels,
              listSM,
              listSMO,
            );
      } else {
        // qty less then 1, remove sale item
        prints('OBBBJECT IS 1');
        _ref
            .read(splitPaymentProvider.notifier)
            .addItemToSplitPayment(
              saleItem,
              itemModel,
              taxModels,
              listSM,
              listSMO,
            );

        /// from the notifier - now async
        deleteSaleModifierModelAndSaleModifierOptionModel(
          saleItem.id!,
          saleItem.updatedAt!,
        );

        /// remove the one saleItemModel from the notifier
        removeSaleItemFromNotifier(saleItem.id!, saleItem.updatedAt!);

        // recalculate the total
        reCalculateAllTotal(saleItem.id!, saleItem.updatedAt!);
      }
    }

    return null; // Return null if no item was removed or decreased
  }

  /// Add item back to order from split payment
  /// Used when moving items from split payment back to order
  Future<void> addItemToOrder({
    required SaleItemModel saleItem,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required List<SaleModifierModel> listSM,
    required List<SaleModifierOptionModel> listSMO,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
  }) async {
    // this function used when user tap one item from split payment details and add back to order list payment
    SaleItemModel selectedSI = state.saleItems.firstWhere(
      (si) => si.id == saleItem.id,
      orElse: () => SaleItemModel(),
    );

    if (selectedSI.id != null) {
      // means sale item is exist, update qty, price, discountTotal, taxAfterDiscount, totalAfterDiscAndTax
      double perPrice = selectedSI.price! / selectedSI.quantity!;
      // prints("SELECTED SI ID NOT NULL");
      // prints("${selectedSI.id} - ${selectedSI.updatedAt!.toIso8601String()}");
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

      /// update the [discountTotal, taxAfterDiscount, totalAfterDiscAndTax, customVariant]
      final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
        state: state,
        updateState: updateState,
        saleItemExisting: selectedSI,
        now: now,
        itemModel: itemModel,
        newSaleItemId: newSaleItemId,
        updatedQty: newQty,
        saleItemPrice: newPrice,
      );
      // prints('UPDATED PRICE IN SALEE ${getNetSalePerSaleItem(selectedSI)}');
      // prints('UPDATED PRICE IN SALEE ${saleItem.price}');
      // prints('UPDATED PRICE IN SALEE ${selectedSI.price}');
      // prints('UPDATED PRICE IN SALEE $newQty');
      final taxAfterDiscountMap = await _calculationHelper.updatedTaxAfterDiscount(
        state: state,
        updateState: updateState,
        saleItemExisting: selectedSI,
        now: now,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: newPrice,
        newSaleItemId: newSaleItemId,
        updatedQty: newQty,
        saleItemPrice: newPrice,
      );

      final taxIncludedAfterDiscountMap = await _calculationHelper
          .updatedTaxIncludedAfterDiscount(
            state: state,
            updateState: updateState,
            saleItemExisting: selectedSI,
            priceUpdated: newPrice,
            taxModels: taxModels,
            now: now,
            itemModel: itemModel,
            newSaleItemId: newSaleItemId,
            updatedQty: newQty,
            saleItemPrice: newPrice,
          );

      final totalAfterDiscountAndTaxMap = await _calculationHelper
          .updatedTotalAfterDiscountAndTax(
            state: state,
            updateState: updateState,
            saleItemExisting: selectedSI,
            now: now,
            itemModel: itemModel,
            taxModels: taxModels,
            saleItemPrice: newPrice,
            newSaleItemId: newSaleItemId,
            updatedQty: newQty,
          );

      // find index of the saleItem to update it
      int indexSaleItem = state.saleItems.indexWhere(
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
        final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
        updatedSaleItems[indexSaleItem] = selectedSI;
        updateState(state.copyWith(saleItems: updatedSaleItems));
      } else {
        prints('FX addItemToOrder indexSaleItem is null');
      }

      // calcTotalAfterDiscountAndTax();
      // calcTaxAfterDiscount();
      // calcTotalDiscount();
      // calcTotalWithAdjustedPrice();
      getMapDataToTransfer();
    } else {
      // means sale item is not exist, add to list
      double perPrice =
          saleItem.soldBy == ItemSoldByEnum.item
              ? (saleItem.price! / saleItem.quantity!)
              : saleItem.price!;

      double newQty =
          saleItem.soldBy == ItemSoldByEnum.item ? 1 : saleItem.quantity!;
      // generate new discountTotal, totalAfterDiscAndTax, taxAfterDiscount
      /// get [discountTotal]
      final totalDiscountMap = await _calculationHelper.updatedTotalDiscount(
        state: state,
        updateState: updateState,
        saleItemExisting: null,
        now: saleItem.updatedAt!,
        itemModel: itemModel,
        newSaleItemId: saleItem.id,
        updatedQty: newQty,
        saleItemPrice: perPrice,
      );

      /// get [taxAfterDiscount]
      final taxAfterDiscountMap = await _calculationHelper.updatedTaxAfterDiscount(
        state: state,
        updateState: updateState,
        saleItemExisting: null,
        now: saleItem.updatedAt!,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: perPrice * newQty,
        newSaleItemId: saleItem.id,
        updatedQty: newQty,
        saleItemPrice: perPrice,
      );

      /// get [taxIncludedAfterDiscount]
      final taxIncludedAfterDiscountMap = await _calculationHelper
          .updatedTaxIncludedAfterDiscount(
            state: state,
            updateState: updateState,
            saleItemExisting: null,
            now: saleItem.updatedAt!,
            itemModel: itemModel,
            taxModels: taxModels,
            priceUpdated: perPrice * newQty,
            newSaleItemId: saleItem.id,
            updatedQty: newQty,
            saleItemPrice: perPrice,
          );

      /// get [totalAfterDiscAndTax]
      final totalAfterDiscAndTaxMap = await _calculationHelper
          .updatedTotalAfterDiscountAndTax(
            state: state,
            updateState: updateState,
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
            totalAfterDiscAndTaxMap == null
                ? 0
                : totalAfterDiscAndTaxMap['totalAfterDiscAndTax'],
      );

      updateState(
        state.copyWith(
          saleItems: [...state.saleItems, newSI],
          saleModifiers: [...state.saleModifiers, ...listSM],
          saleModifierOptions: [...state.saleModifierOptions, ...listSMO],
        ),
      );

      // calcTotalAfterDiscountAndTax();
      // calcTaxAfterDiscount();
      // calcTotalDiscount();
    }

    getMapDataToTransfer();
  }
}
