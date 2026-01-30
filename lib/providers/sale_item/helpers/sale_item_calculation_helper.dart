import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/log_utils.dart';
import '../../../data/models/item/item_model.dart';
import '../../../data/models/sale_item/sale_item_model.dart';
import '../../../data/models/tax/tax_model.dart';
import '../../../data/models/variant_option/variant_option_model.dart';
import '../../../core/enum/tax_type_enum.dart';
import '../sale_item_state.dart';
import '../services/sale_item_calculation_service.dart';
import '../services/sale_item_discount_service.dart';
import '../services/sale_item_tax_service.dart';

/// Helper class for sale item calculations
/// Extracted from SaleItemNotifier to improve maintainability
class SaleItemCalculationHelper {
  final Ref _ref;
  final SaleItemCalculationService _calculationService;
  final SaleItemDiscountService _discountService;
  final SaleItemTaxService _taxService;

  // Track last calculation state to avoid redundant calculations
  static String? _lastCalculationHash;
  static Map<String, dynamic>? _lastCalculationResult;

  SaleItemCalculationHelper(
    this._ref,
    this._calculationService,
    this._discountService,
    this._taxService,
  );

  /// Update total discount for a sale item
  Future<Map<String, dynamic>?> updatedTotalDiscount({
    required SaleItemState state,
    required SaleItemModel? saleItemExisting,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
    required Function(SaleItemState) updateState,
  }) async {
    // Calculate the discount total using service
    final double newTotalDiscount = await discountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: saleItemPrice / updatedQty,
    );

    // Create a copy of the list for immutability
    final listTotalDiscount = List<Map<String, dynamic>>.from(
      state.listTotalDiscount,
    );

    final nowIso = now.toIso8601String();

    // If saleItemExisting is null, create new entry for new sale item
    if (saleItemExisting == null) {
      final newDiscountMap = <String, dynamic>{
        'discountTotal': newTotalDiscount,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTotalDiscount.add(newDiscountMap);
      updateState(state.copyWith(listTotalDiscount: listTotalDiscount));
      return newDiscountMap;
    }

    // Cache values for existing sale item
    final saleItemId = saleItemExisting.id;
    final saleItemUpdatedAt = saleItemExisting.updatedAt!.toIso8601String();

    // Use a for loop with early exit for better performance than indexWhere
    int discountMapIndex = -1;
    for (int i = 0; i < listTotalDiscount.length; i++) {
      if (listTotalDiscount[i]['saleItemId'] == saleItemId &&
          listTotalDiscount[i]['updatedAt'] == saleItemUpdatedAt) {
        discountMapIndex = i;
        break;
      }
    }

    // Update the map if found, otherwise create a new entry
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

      updateState(state.copyWith(listTotalDiscount: listTotalDiscount));
      return updatedMap;
    } else {
      final newDiscountMap = <String, dynamic>{
        'discountTotal': newTotalDiscount,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTotalDiscount.add(newDiscountMap);
      updateState(state.copyWith(listTotalDiscount: listTotalDiscount));
      return newDiscountMap;
    }
  }

  Future<Map<String, dynamic>?> updatedTaxIncludedAfterDiscount({
    required SaleItemState state,
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
    required Function(SaleItemState) updateState,
  }) async {
    final nowIso = now.toIso8601String();
    final updatedPrice = priceUpdated;

    final double newTaxIncludedAfterDiscount =
        await getTaxIncludedAfterDiscountPerItem(
          updatedPrice,
          taxModels,
          itemModel,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    final listTaxIncludedAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxIncludedAfterDiscount,
    );

    if (saleItemExisting == null) {
      final newTaxIncludedMap = <String, dynamic>{
        'taxIncludedAfterDiscount': newTaxIncludedAfterDiscount,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTaxIncludedAfterDiscount.add(newTaxIncludedMap);
      updateState(
        state.copyWith(
          listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        ),
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

      updateState(
        state.copyWith(
          listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        ),
      );
      return updatedMap;
    } else {
      final newTaxIncludedMap = <String, dynamic>{
        'taxIncludedAfterDiscount': newTaxIncludedAfterDiscount,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTaxIncludedAfterDiscount.add(newTaxIncludedMap);
      updateState(
        state.copyWith(
          listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
        ),
      );
      return newTaxIncludedMap;
    }
  }

  Future<Map<String, dynamic>?> updatedTaxAfterDiscount({
    required SaleItemState state,
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
    required Function(SaleItemState) updateState,
  }) async {
    final nowIso = now.toIso8601String();
    final updatedPrice = priceUpdated;

    final double newTaxAfterDiscount = await getTaxAfterDiscountPerItem(
      updatedPrice,
      taxModels,
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: saleItemPrice / updatedQty,
    );

    final listTaxAfterDiscount = List<Map<String, dynamic>>.from(
      state.listTaxAfterDiscount,
    );

    if (saleItemExisting == null) {
      final newTaxAfterDiscountMap = <String, dynamic>{
        'taxAfterDiscount': newTaxAfterDiscount,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTaxAfterDiscount.add(newTaxAfterDiscountMap);
      updateState(state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount));
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
      updateState(state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount));
      return updatedMap;
    } else {
      final newTaxAfterDiscountMap = <String, dynamic>{
        'taxAfterDiscount': newTaxAfterDiscount,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTaxAfterDiscount.add(newTaxAfterDiscountMap);
      updateState(state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount));
      return newTaxAfterDiscountMap;
    }
  }

  Future<Map<String, dynamic>?> updatedTotalAfterDiscountAndTax({
    required SaleItemState state,
    required SaleItemModel? saleItemExisting,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required Function(SaleItemState) updateState,
  }) async {
    final nowIso = now.toIso8601String();
    final updatedPrice = saleItemPrice;

    final double newTotalAfterDiscountAndTax = await totalAfterDiscountAndTax(
      updatedPrice,
      itemModel,
      taxModels,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: saleItemPrice / updatedQty,
    );

    final listTotalAfterDiscountAndTax = List<Map<String, dynamic>>.from(
      state.listTotalAfterDiscountAndTax,
    );

    if (saleItemExisting == null) {
      final newTotalAfterDiscAndTaxMap = <String, dynamic>{
        'totalAfterDiscAndTax': newTotalAfterDiscountAndTax,
        'saleItemId': newSaleItemId,
        'updatedAt': nowIso,
      };

      listTotalAfterDiscountAndTax.add(newTotalAfterDiscAndTaxMap);
      updateState(
        state.copyWith(
          listTotalAfterDiscountAndTax: listTotalAfterDiscountAndTax,
        ),
      );
      return newTotalAfterDiscAndTaxMap;
    }

    final saleItemId = saleItemExisting.id;
    final saleItemUpdatedAt = saleItemExisting.updatedAt!.toIso8601String();

    int totalAfterDiscTaxMapIndex = -1;
    for (int i = 0; i < listTotalAfterDiscountAndTax.length; i++) {
      if (listTotalAfterDiscountAndTax[i]['saleItemId'] == saleItemId &&
          listTotalAfterDiscountAndTax[i]['updatedAt'] == saleItemUpdatedAt) {
        totalAfterDiscTaxMapIndex = i;
        break;
      }
    }

    if (totalAfterDiscTaxMapIndex != -1) {
      final updatedMap = Map<String, dynamic>.from(
        listTotalAfterDiscountAndTax[totalAfterDiscTaxMapIndex],
      );

      if (newSaleItemId != null) {
        updatedMap['saleItemId'] = newSaleItemId;
      }

      updatedMap['totalAfterDiscAndTax'] = newTotalAfterDiscountAndTax;
      updatedMap['updatedAt'] = nowIso;

      listTotalAfterDiscountAndTax[totalAfterDiscTaxMapIndex] = updatedMap;
      updateState(
        state.copyWith(
          listTotalAfterDiscountAndTax: listTotalAfterDiscountAndTax,
        ),
      );
      return updatedMap;
    } else {
      final newTotalAfterDiscAndTaxMap = <String, dynamic>{
        'totalAfterDiscAndTax': newTotalAfterDiscountAndTax,
        'saleItemId': newSaleItemId ?? saleItemId,
        'updatedAt': nowIso,
      };

      listTotalAfterDiscountAndTax.add(newTotalAfterDiscAndTaxMap);
      updateState(
        state.copyWith(
          listTotalAfterDiscountAndTax: listTotalAfterDiscountAndTax,
        ),
      );
      return newTotalAfterDiscAndTaxMap;
    }
  }

  void updateCustomVariant({
    required SaleItemState state,
    required SaleItemModel? saleItemExisting,
    required VariantOptionModel varOptModel,
    required DateTime now,
    required bool isCustomVariant,
    required String? newSaleItemId,
    required Function(SaleItemState) updateState,
  }) {
    final listCustomVariant = List<Map<String, dynamic>>.from(
      state.listCustomVariant,
    );

    if (varOptModel.id != null) {
      if (saleItemExisting == null) {
        final newCustomVariantMap = <String, dynamic>{
          'saleItemId': newSaleItemId,
          'isCustomVariant': isCustomVariant,
          'variantOptionId': varOptModel.id,
          'variantOptionPrice': varOptModel.price,
          'updatedAt': now.toIso8601String(),
        };

        listCustomVariant.add(newCustomVariantMap);
        updateState(state.copyWith(listCustomVariant: listCustomVariant));
      } else {
        final customVariantMapIndex = listCustomVariant.indexWhere(
          (map) =>
              map['saleItemId'] == saleItemExisting.id &&
              map['updatedAt'] == saleItemExisting.updatedAt!.toIso8601String(),
        );

        if (customVariantMapIndex != -1) {
          final updatedMap = Map<String, dynamic>.from(
            listCustomVariant[customVariantMapIndex],
          );
          if (newSaleItemId != null) {
            updatedMap['saleItemId'] = newSaleItemId;
          }
          updatedMap['isCustomVariant'] = isCustomVariant;
          updatedMap['variantOptionId'] = varOptModel.id;
          updatedMap['variantOptionPrice'] = varOptModel.price;
          updatedMap['updatedAt'] = now.toIso8601String();

          listCustomVariant[customVariantMapIndex] = updatedMap;
          updateState(state.copyWith(listCustomVariant: listCustomVariant));
        } else {
          final newCustomVariantMap = <String, dynamic>{
            'saleItemId': newSaleItemId ?? saleItemExisting.id,
            'isCustomVariant': isCustomVariant,
            'variantOptionId': varOptModel.id,
            'variantOptionPrice': varOptModel.price,
            'updatedAt': now.toIso8601String(),
          };

          listCustomVariant.add(newCustomVariantMap);
          updateState(state.copyWith(listCustomVariant: listCustomVariant));
        }
      }
    }
  }

  // Calculate discount for a single item using service
  Future<double> discountTotalPerItem(
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    // Validate inputs
    if (updatedQty <= 0) {
      prints('Warning: Invalid quantity $updatedQty for discount calculation');
      return 0.0;
    }

    if (itemPriceOrVariantPrice < 0) {
      prints(
        'Warning: Invalid price $itemPriceOrVariantPrice for discount calculation',
      );
      return 0.0;
    }

    return await _discountService.calculateDiscountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );
  }

  Future<double> getTaxAfterDiscountPerItem(
    double netSaleItem,
    List<TaxModel> taxModels,
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    // Validate inputs
    if (netSaleItem < 0) {
      prints('Warning: Negative net sale item $netSaleItem');
      return 0.0;
    }

    if (taxModels.isEmpty) return 0.0;

    // Calculate discount amount
    double discountAmount = await discountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );

    // Ensure discount is not negative
    if (discountAmount < 0) discountAmount = 0.0;

    // Calculate tax percentage for Added taxes only
    final taxPercent = taxModels.fold<double>(
      0.0,
      (total, tm) =>
          tm.type == TaxTypeEnum.Added ? total + (tm.rate ?? 0.0) : total,
    );

    final perItem = netSaleItem - discountAmount;
    final totalTax = perItem * (taxPercent / 100);

    prints('TOTAL TAX AFTER DISCOUNT: $totalTax');
    return totalTax.isNegative ? 0.0 : totalTax;
  }

  // Calculate tax included after discount for a single item using service
  Future<double> getTaxIncludedAfterDiscountPerItem(
    double netSaleItem,
    List<TaxModel> taxModels,
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    return await _taxService.calculateTaxIncludedAfterDiscountPerItem(
      netSaleItem,
      taxModels,
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );
  }

  // Calculate total after discount and tax using service
  Future<double> totalAfterDiscountAndTax(
    double subTotalPrice,
    ItemModel itemModel,
    List<TaxModel> taxModels, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    return await _taxService.calculateTotalAfterDiscountAndTax(
      subTotalPrice,
      itemModel,
      taxModels,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );
  }

  /// Removes discount, tax, and total entries for a specific sale item
  void removeDiscountTaxAndTotal(
    String? saleItemId,
    DateTime updatedAt,
    SaleItemState state,
    Function(SaleItemState) updateState,
    Function() recalculateAllTotals,
  ) {
    if (saleItemId == null) return;

    final updatedAtStr = updatedAt.toIso8601String();

    List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> list) {
      return list
          .where(
            (element) =>
                element['saleItemId'] != saleItemId ||
                element['updatedAt'] != updatedAtStr,
          )
          .toList();
    }

    // Update state with all filtered lists in one operation
    updateState(
      state.copyWith(
        listTotalDiscount: filterList(state.listTotalDiscount),
        listTaxAfterDiscount: filterList(state.listTaxAfterDiscount),
        listTaxIncludedAfterDiscount: filterList(
          state.listTaxIncludedAfterDiscount,
        ),
        listTotalAfterDiscountAndTax: filterList(
          state.listTotalAfterDiscountAndTax,
        ),
      ),
    );

    // Recalculate totals once after all updates
    recalculateAllTotals();
  }

  /// Calculate total costs from all sale items
  double getTotalCosts(SaleItemState state) {
    if (state.saleItems.isEmpty) return 0.0;

    return state.saleItems.fold<double>(
      0.0,
      (total, item) => total + (item.cost ?? 0.0),
    );
  }

  /// Get gross amount for a single sale item
  double getGrossAmountPerSaleItem(SaleItemModel saleItem) {
    // Validate input
    if (saleItem.price == null) {
      prints('Warning: Sale item ${saleItem.id} has null price');
      return 0.0;
    }

    prints('Gross amount for item ${saleItem.id}: ${saleItem.price}');
    prints('qty for item ${saleItem.id}: ${saleItem.quantity ?? 0}');

    return saleItem.price!;
  }

  /// Calculate net sales for a specific sale item
  /// Net sales = gross sale per item - discount of that item
  double getNetSalePerSaleItem(SaleItemModel saleItem) {
    if (saleItem.discountTotal == null) {
      prints('Warning: Sale item ${saleItem.id} has null discountTotal');
      return getGrossAmountPerSaleItem(saleItem);
    }

    return getGrossAmountPerSaleItem(saleItem) - saleItem.discountTotal!;
  }

  /// Calculate net sales across all sale items
  /// Net sales = gross sales - discounts - adjusted price
  double getNetSales(SaleItemState state) {
    if (state.saleItems.isEmpty) return 0.0 - state.adjustedPrice;

    final netSales = state.saleItems.fold<double>(0.0, (total, saleItem) {
      final netSaleValue = getNetSalePerSaleItem(saleItem);
      prints('Net sale for item ${saleItem.id}: $netSaleValue');
      return total + netSaleValue;
    });

    return netSales - state.adjustedPrice;
  }

  /// Calculate gross sales across all sale items
  double getGrossSales(SaleItemState state) {
    if (state.saleItems.isEmpty) return 0.0;

    final grossSales = state.saleItems.fold<double>(0.0, (total, saleItem) {
      final grossAmount = getGrossAmountPerSaleItem(saleItem);
      prints('Gross amount for item ${saleItem.id}: $grossAmount');
      return total + grossAmount;
    });

    prints('Final calculated grossSales: $grossSales');
    return grossSales;
  }
}
