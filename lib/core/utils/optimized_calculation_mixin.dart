import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/utils/calculation_cache.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

/// Mixin to optimize calculation performance in SaleItemsNotifier
mixin OptimizedCalculationMixin on SaleItemNotifier {
  // Track last calculation state to avoid redundant calculations
  static String? _lastCalculationHash;
  static Map<String, dynamic>? _lastCalculationResult;

  // Timer for debouncing calculation updates
  Timer? _calculationTimer;
  static const Duration _calculationDebounce = Duration(milliseconds: 50);

  /// Optimized version of getMapDataToTransfer with intelligent caching
  @override
  Map<String, dynamic> getMapDataToTransfer() {
    // Generate hash of current state to detect if recalculation is needed
    final currentStateHash = _generateStateHash();

    // If state hasn't changed, return cached result
    if (_lastCalculationHash == currentStateHash &&
        _lastCalculationResult != null) {
      prints('Calculation cache HIT - returning cached result');
      return Map<String, dynamic>.from(_lastCalculationResult!);
    }

    prints('Calculation cache MISS - performing calculations');
    final stopwatch = Stopwatch()..start();

    // Perform calculations only when necessary
    _performOptimizedCalculations();

    // Update order list (this is lightweight)
    state = state.copyWith(orderList: getOrderList());

    final saleModifiers = List<SaleModifierModel>.from(state.saleModifiers);
    final saleModifierOptions = List<SaleModifierOptionModel>.from(
      state.saleModifierOptions,
    );

    // Generate cart update ID
    final String cartUpdateId =
        DateTime.now().millisecondsSinceEpoch.toString();

    // Build result
    final result = {
      // Cart state identifier
      DataEnum.cartUpdateId: cartUpdateId,

      // Essential summary data
      DataEnum.totalAmountRemaining: state.totalAmountRemaining,
      DataEnum.totalAfterDiscAndTax: state.totalAfterDiscountAndTax,
      DataEnum.totalDiscount: state.totalDiscount,
      DataEnum.totalTax: state.taxAfterDiscount,
      DataEnum.totalTaxIncluded: state.taxIncludedAfterDiscount,
      DataEnum.totalWithAdjustedPrice: state.totalWithAdjustedPrice,
      DataEnum.totalAdjustment: state.adjustedPrice,

      // Sale items and modifiers
      DataEnum.listSaleItems: state.saleItems.map((e) => e.toJson()).toList(),
      DataEnum.listSM: saleModifiers.map((e) => e.toJson()).toList(),
      DataEnum.listSMO: saleModifierOptions.map((e) => e.toJson()).toList(),

      // Other essential data
      DataEnum.orderOptionModel:
          state.orderOptionModel?.id != null
              ? state.orderOptionModel?.toJson()
              : {},
      DataEnum.tableName: state.selectedTable?.name,
      DataEnum.saleModel:
          state.currSaleModel?.id != null ? state.currSaleModel?.toJson() : {},
    };

    // Cache the result
    _lastCalculationHash = currentStateHash;
    _lastCalculationResult = Map<String, dynamic>.from(result);

    stopwatch.stop();
    prints('Total calculation time: ${stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  /// Perform calculations only when necessary
  void _performOptimizedCalculations() {
    final stopwatch = Stopwatch()..start();

    // Check if individual calculations need to be updated
    final needsDiscountCalc = _needsCalculationUpdate('discount');
    final needsTaxCalc = _needsCalculationUpdate('tax');
    final needsTaxIncludedCalc = _needsCalculationUpdate('tax_included');
    final needsTotalCalc = _needsCalculationUpdate('total');
    final needsAdjustedCalc = _needsCalculationUpdate('adjusted');

    if (needsDiscountCalc) {
      prints('Updating discount calculations');
      calcTotalDiscount();
    }

    if (needsTaxCalc) {
      prints('Updating tax calculations');
      calcTaxAfterDiscount();
    }

    if (needsTaxIncludedCalc) {
      prints('Updating tax included calculations');
      calcTaxIncludedAfterDiscount();
    }

    if (needsTotalCalc) {
      prints('Updating total calculations');
      calcTotalAfterDiscountAndTax();
    }

    if (needsAdjustedCalc) {
      prints('Updating adjusted price calculations');
      calcTotalWithAdjustedPrice();
    }

    stopwatch.stop();
    prints('Selective calculations took: ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Check if specific calculation needs updating based on relevant state changes
  bool _needsCalculationUpdate(String calculationType) {
    // For now, we'll recalculate everything when state changes
    // In a more advanced implementation, you could track specific dependencies
    // For example:
    // - Discount calculations only need updating when item prices/quantities change
    // - Tax calculations only need updating when tax-relevant data changes
    return true;
  }

  /// Generate hash of current state to detect changes
  String _generateStateHash() {
    // Create a hash based on relevant state properties
    final buffer = StringBuffer();

    // Include sale items with their key properties
    for (final item in state.saleItems) {
      buffer.write(
        '${item.id}_${item.quantity}_${item.price}_${item.updatedAt?.millisecondsSinceEpoch}|',
      );
    }

    // Include totals that might affect calculations
    buffer.write('${state.adjustedPrice}_');
    buffer.write('${state.totalAmountPaid}_');

    // Include modifiers count (changes in modifiers affect calculations)
    buffer.write(
      '${state.saleModifiers.length}_${state.saleModifierOptions.length}',
    );

    return buffer.toString().hashCode.toString();
  }

  /// Debounced version of calculation update for rapid state changes
  void scheduleCalculationUpdate() {
    _calculationTimer?.cancel();
    _calculationTimer = Timer(_calculationDebounce, () {
      if (mounted) {
        _invalidateCalculationCache();
      }
    });
  }

  /// Invalidate calculation cache when state changes
  void _invalidateCalculationCache() {
    _lastCalculationHash = null;
    _lastCalculationResult = null;
    prints('Calculation cache invalidated');
  }

  /// Call this when items are added/removed/modified
  void invalidateCalculationsForItem(String itemId) {
    // Invalidate both local and global caches
    _invalidateCalculationCache();
    CalculationCache.invalidateByPattern(itemId);
  }

  /// Call this when tax rules change
  void invalidateTaxCalculations() {
    _invalidateCalculationCache();
    CalculationCache.invalidateByPattern('tax_');
  }

  /// Call this when discount rules change
  void invalidateDiscountCalculations() {
    _invalidateCalculationCache();
    CalculationCache.invalidateByPattern('discount_');
  }

  /// Performance monitoring - call periodically
  void monitorCalculationPerformance() {
    if (kDebugMode) {
      final cacheStats = CalculationCache.getStats();
      prints('Calculation cache stats: $cacheStats');

      // Clean up expired entries
      CalculationCache.cleanupExpired();
    }
  }

  /// Dispose of timers and clean up
  void disposeOptimizedCalculations() {
    _calculationTimer?.cancel();
    _calculationTimer = null;
    _lastCalculationHash = null;
    _lastCalculationResult = null;
  }
}
