import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';

/// Helper class for data transfer operations in SaleItemNotifier
/// Handles calculation caching and data aggregation for cart updates
class SaleItemDataTransferHelper {
  // Cache for expensive calculations
  static String? _lastCalculationHash;
  static Map<String, dynamic>? _lastCalculationResult;

  // Dependencies passed from notifier
  final dynamic modifierOptionNotifier;
  final dynamic itemNotifier;

  SaleItemDataTransferHelper({
    required this.modifierOptionNotifier,
    required this.itemNotifier,
  });

  /// Generates a unique hash representing the current state
  /// Used for detecting when recalculation is needed
  String generateStateHash(SaleItemState state) {
    return '${state.saleItems.length}_'
        '${state.saleItems.fold<double>(0, (sum, item) => sum + (item.quantity ?? 0))}_'
        '${state.totalDiscount}_'
        '${state.adjustedPrice}_'
        '${state.saleModifiers.length}_'
        '${DateTime.now().millisecondsSinceEpoch ~/ 1000}'; // Cache for 1 second
  }

  /// Main method for getting aggregated data to transfer to UI
  /// Uses caching to avoid expensive recalculations
  Map<String, dynamic> getMapDataToTransfer({
    required SaleItemState state,
    required void Function(SaleItemState) updateState,
    required void Function() recalculateAllTotals,
  }) {
    // Generate hash of current state to detect if recalculation is needed
    final currentStateHash = generateStateHash(state);

    // If state hasn't changed significantly, return cached result with updated timestamp
    if (_lastCalculationHash == currentStateHash &&
        _lastCalculationResult != null) {
      prints('🚀 Calculation cache HIT - avoiding expensive recalculations');
      final cachedResult = Map<String, dynamic>.from(_lastCalculationResult!);
      // Update only the timestamp for cart update tracking
      cachedResult[DataEnum.cartUpdateId] =
          DateTime.now().millisecondsSinceEpoch.toString();
      return cachedResult;
    }

    prints('⚡ Calculation cache MISS - performing calculations');
    final stopwatch = Stopwatch()..start();

    // Perform the expensive calculations only when necessary
    recalculateAllTotals();

    // Cache order list to avoid regenerating it
    final orderList = getOrderList(
      state: state,
      modifierOptionNotifier: modifierOptionNotifier,
      itemNotifier: itemNotifier,
    );
    updateState(state.copyWith(orderList: orderList));

    // Avoid creating new lists if not necessary
    final saleModifiers = state.saleModifiers;
    final saleModifierOptions = state.saleModifierOptions;

    // Generate a unique cart update ID based on timestamp
    final cartUpdateId = DateTime.now().millisecondsSinceEpoch.toString();

    // Build result data efficiently
    final result = {
      DataEnum.cartUpdateId: cartUpdateId,
      DataEnum.totalAmountRemaining: state.totalAmountRemaining,
      DataEnum.totalAfterDiscAndTax: state.totalAfterDiscountAndTax,
      DataEnum.totalDiscount: state.totalDiscount,
      DataEnum.totalTax: state.taxAfterDiscount,
      DataEnum.totalTaxIncluded: state.taxIncludedAfterDiscount,
      DataEnum.totalWithAdjustedPrice: state.totalWithAdjustedPrice,
      DataEnum.totalAdjustment: state.adjustedPrice,
      // Convert to JSON only when necessary
      DataEnum.listSaleItems: state.saleItems.map((e) => e.toJson()).toList(),
      DataEnum.listSM: saleModifiers.map((e) => e.toJson()).toList(),
      DataEnum.listSMO: saleModifierOptions.map((e) => e.toJson()).toList(),
      DataEnum.orderOptionModel:
          state.orderOptionModel?.id != null
              ? state.orderOptionModel!.toJson()
              : <String, dynamic>{},
      DataEnum.tableName: state.selectedTable?.name,
      DataEnum.saleModel:
          state.currSaleModel?.id != null
              ? state.currSaleModel!.toJson()
              : <String, dynamic>{},
    };

    stopwatch.stop();
    prints('⚡ Calculation completed in ${stopwatch.elapsedMilliseconds}ms');

    // Cache the result for future use
    _lastCalculationHash = currentStateHash;
    _lastCalculationResult = Map<String, dynamic>.from(result);

    return result;
  }

  /// Gets complete data including full modifier information
  /// Used for initial load or when full refresh is needed
  Map<String, dynamic> getCompleteDataToTransfer({
    required SaleItemState state,
    required void Function(SaleItemState) updateState,
    required void Function() recalculateAllTotals,
  }) {
    Map<String, dynamic> data = getMapDataToTransfer(
      state: state,
      updateState: updateState,
      recalculateAllTotals: recalculateAllTotals,
    );

    final saleModifiers = List<SaleModifierModel>.from(state.saleModifiers);
    final saleModifierOptions = List<SaleModifierOptionModel>.from(
      state.saleModifierOptions,
    );

    // Add the complete modifier data
    data[DataEnum.listSM] = saleModifiers.map((e) => e.toJson()).toList();
    data[DataEnum.listSMO] =
        saleModifierOptions.map((e) => e.toJson()).toList();

    return data;
  }

  /// Generates the order list with all associated data for each sale item
  /// Pre-indexes data for O(1) lookups to improve performance
  List<Map<String, dynamic>> getOrderList({
    required SaleItemState state,
    required dynamic modifierOptionNotifier,
    required dynamic itemNotifier,
  }) {
    if (state.saleItems.isEmpty) return [];

    final saleModifiers = state.saleModifiers;
    final saleModifierOptions = state.saleModifierOptions;

    // Pre-index saleModifiers by saleItemId for O(1) lookups
    final saleModifierIdsMap = <String, List<String>>{};
    for (final saleModifier in saleModifiers) {
      final saleItemId = saleModifier.saleItemId;
      if (saleItemId != null && saleModifier.id != null) {
        saleModifierIdsMap
            .putIfAbsent(saleItemId, () => [])
            .add(saleModifier.id!);
      }
    }

    // Pre-index modifierOptions by saleModifierId for O(1) lookups
    final modifierOptionIdsMap = <String, List<String>>{};
    for (final option in saleModifierOptions) {
      final saleModifierId = option.saleModifierId;
      if (saleModifierId != null && option.modifierOptionId != null) {
        modifierOptionIdsMap
            .putIfAbsent(saleModifierId, () => [])
            .add(option.modifierOptionId!);
      }
    }

    // Build composite key index for fast sale item lookups
    final saleItemIndex = <String, SaleItemModel>{};
    for (final item in state.saleItems) {
      final key =
          '${item.id}_${item.variantOptionId}_'
          '${item.comments}_${item.updatedAt?.toIso8601String()}';
      saleItemIndex[key] = item;
    }

    // Process each sale item only once
    return state.saleItems.map((saleItem) {
      // Use precomputed maps for O(1) lookups
      final saleModifierIds = saleModifierIdsMap[saleItem.id] ?? <String>[];
      final modifierOptionIds = <String>[];

      for (final saleModifierId in saleModifierIds) {
        modifierOptionIds.addAll(modifierOptionIdsMap[saleModifierId] ?? []);
      }

      final allModifierOptionName = modifierOptionNotifier
          .getModifierOptionNameFromListIds(modifierOptionIds);

      // Use composite key for O(1) lookup
      final usedSaleItemKey =
          '${saleItem.id}_${saleItem.variantOptionId}_'
          '${saleItem.comments}_${saleItem.updatedAt?.toIso8601String()}';
      final usedSaleItemModel =
          saleItemIndex[usedSaleItemKey] ?? SaleItemModel();

      // Cache item and variant lookups
      final itemModel =
          usedSaleItemModel.itemId != null
              ? itemNotifier.getItemById(usedSaleItemModel.itemId!)
              : ItemModel();

      final variantOptionModel =
          usedSaleItemModel.variantOptionId != null
              ? itemNotifier.getVariantOptionModelById(
                usedSaleItemModel.variantOptionId,
                usedSaleItemModel.itemId,
              )
              : null;

      return {
        DataEnum.saleItemModel: saleItem,
        DataEnum.itemModel: itemModel,
        DataEnum.allModifierOptionNames: allModifierOptionName,
        DataEnum.variantOptionNames: variantOptionModel?.name,
        DataEnum.usedSaleItemModel: usedSaleItemModel,
      };
    }).toList();
  }

  /// Clear the calculation cache
  /// Call this when a major state change requires full recalculation
  static void clearCache() {
    _lastCalculationHash = null;
    _lastCalculationResult = null;
  }
}
