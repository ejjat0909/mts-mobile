import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/tax/tax_providers.dart';

/// Helper class for recalculating sale item data when order options change
/// Handles batch recalculation of discounts, taxes, and totals for all items
class OrderOptionRecalculationHelper {
  final Ref ref;

  OrderOptionRecalculationHelper(this.ref);

  /// Regenerates all calculation data when order option changes
  /// Recalculates discounts and taxes for all sale items with new order option settings
  Future<void> regenerateCalculationDataForOrderOptionChange({
    required SaleItemState state,
    required void Function(SaleItemState) updateState,
    required bool reCalculate,
    required Map<String, dynamic> Function() getMapDataToTransfer,
    required Future<Map<String, dynamic>?> Function({
      required SaleItemModel? saleItemExisting,
      required DateTime now,
      required ItemModel itemModel,
      required String? newSaleItemId,
      required double updatedQty,
      required double saleItemPrice,
    })
    updatedTotalDiscount,
    required Future<Map<String, dynamic>?> Function({
      required SaleItemModel? saleItemExisting,
      required DateTime now,
      required ItemModel itemModel,
      required List<TaxModel> taxModels,
      required double priceUpdated,
      required String? newSaleItemId,
      required double updatedQty,
      required double saleItemPrice,
    })
    updatedTaxAfterDiscount,
    required Future<Map<String, dynamic>?> Function({
      required SaleItemModel? saleItemExisting,
      required DateTime now,
      required ItemModel itemModel,
      required List<TaxModel> taxModels,
      required double priceUpdated,
      required String? newSaleItemId,
      required double updatedQty,
      required double saleItemPrice,
    })
    updatedTaxIncludedAfterDiscount,
    required Future<Map<String, dynamic>?> Function({
      required SaleItemModel? saleItemExisting,
      required DateTime now,
      required ItemModel itemModel,
      required List<TaxModel> taxModels,
      required double saleItemPrice,
      required String? newSaleItemId,
      required double updatedQty,
    })
    updatedTotalAfterDiscountAndTax,
  }) async {
    // Early return if no recalculation needed
    if (!reCalculate) return;

    if (state.saleItems.isEmpty) {
      getMapDataToTransfer();
      return;
    }

    final taxNotifier = ref.read(taxProvider.notifier);
    final itemNotifier = ref.read(itemProvider.notifier);

    // Pre-allocate lists with known capacity for better performance
    final newListTotalDiscount = <Map<String, dynamic>>[];
    final newListTaxAfterDiscount = <Map<String, dynamic>>[];
    final newListTaxIncludedAfterDiscount = <Map<String, dynamic>>[];
    final newListTotalAfterDiscountAndTax = <Map<String, dynamic>>[];

    // Batch process all sale items
    for (final saleItem in state.saleItems) {
      if (saleItem.id == null || saleItem.itemId == null) continue;

      final itemModel = itemNotifier.getItemById(saleItem.itemId!);
      if (itemModel.id == null) continue;

      // Get tax models once per item
      final taxModels = taxNotifier.getAllTaxModelsForThatItem(
        itemModel,
        <TaxModel>[],
      );

      // Generate all calculation maps in one go
      final now = saleItem.updatedAt!;
      final qty = saleItem.quantity!;
      final price = saleItem.price!;

      final discountTotalMap = await updatedTotalDiscount(
        saleItemExisting: saleItem,
        now: now,
        itemModel: itemModel,
        newSaleItemId: null,
        updatedQty: qty,
        saleItemPrice: price,
      );

      final taxAfterDiscountMap = await updatedTaxAfterDiscount(
        saleItemExisting: saleItem,
        now: now,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: price,
        newSaleItemId: null,
        updatedQty: qty,
        saleItemPrice: price,
      );

      final taxIncludedAfterDiscountMap = await updatedTaxIncludedAfterDiscount(
        saleItemExisting: saleItem,
        now: now,
        itemModel: itemModel,
        taxModels: taxModels,
        priceUpdated: price,
        newSaleItemId: null,
        updatedQty: qty,
        saleItemPrice: price,
      );

      final totalAfterDiscountAndTaxMap = await updatedTotalAfterDiscountAndTax(
        saleItemExisting: saleItem,
        now: now,
        itemModel: itemModel,
        taxModels: taxModels,
        saleItemPrice: price,
        newSaleItemId: null,
        updatedQty: qty,
      );

      // Add non-null maps to lists
      if (discountTotalMap != null) newListTotalDiscount.add(discountTotalMap);
      newListTaxAfterDiscount.add(taxAfterDiscountMap!);
      if (taxIncludedAfterDiscountMap != null) {
        newListTaxIncludedAfterDiscount.add(taxIncludedAfterDiscountMap);
      }
      if (totalAfterDiscountAndTaxMap != null) {
        newListTotalAfterDiscountAndTax.add(totalAfterDiscountAndTaxMap);
      }
    }

    // Single state update with all new calculation lists
    updateState(
      state.copyWith(
        listTotalDiscount: newListTotalDiscount,
        listTaxAfterDiscount: newListTaxAfterDiscount,
        listTaxIncludedAfterDiscount: newListTaxIncludedAfterDiscount,
        listTotalAfterDiscountAndTax: newListTotalAfterDiscountAndTax,
      ),
    );

    // Recalculate all totals once
    getMapDataToTransfer();
  }
}
