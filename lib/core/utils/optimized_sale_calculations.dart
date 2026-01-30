import 'package:mts/core/utils/calculation_cache.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

/// Optimized calculation methods with intelligent caching
/// This replaces the heavy calculation methods in sale_item_riverpod.dart
class OptimizedSaleCalculations {
  final SaleItemNotifier _saleItemNotifier;

  OptimizedSaleCalculations({required SaleItemNotifier saleItemNotifier})
    : _saleItemNotifier = saleItemNotifier;

  /// Optimized tax after discount calculation with caching
  Map<String, dynamic>? updatedTaxAfterDiscountCached({
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) {
    final nowIso = now.toIso8601String();

    // Generate cache key based on calculation inputs
    final cacheKey = CalculationCache.generateKey(
      operation: 'tax_after_discount',
      itemId: itemModel.id!,
      params: {
        'price': (saleItemPrice / updatedQty).toStringAsFixed(4),
        'qty': updatedQty.toString(),
        'taxes': taxModels.map((t) => '${t.id}:${t.rate}').join(','),
        'updated_price': priceUpdated.toStringAsFixed(4),
      },
    );

    // Try to get from cache first
    final cached = CalculationCache.get(cacheKey);
    if (cached != null) {
      final cachedResult = cached.value as Map<String, dynamic>;
      prints('Cache HIT for tax calculation: $cacheKey');

      // Return cached result with updated metadata
      return {
        ...cachedResult,
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': nowIso,
      };
    }

    // Cache miss - perform calculation
    prints('Cache MISS for tax calculation: $cacheKey');
    final stopwatch = Stopwatch()..start();

    final double newTaxAfterDiscount = _saleItemNotifier
        .getTaxAfterDiscountPerItem(
          priceUpdated,
          taxModels,
          itemModel,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    stopwatch.stop();
    prints('Tax calculation took: ${stopwatch.elapsedMilliseconds}ms');

    final result = {
      'taxAfterDiscount': newTaxAfterDiscount,
      'saleItemId': newSaleItemId ?? saleItemExisting?.id,
      'updatedAt': nowIso,
    };

    // Cache the calculation result (store only the calculation, not metadata)
    CalculationCache.set(cacheKey, {'taxAfterDiscount': newTaxAfterDiscount});

    return result;
  }

  /// Optimized tax included after discount calculation with caching
  Map<String, dynamic>? updatedTaxIncludedAfterDiscountCached({
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) {
    final nowIso = now.toIso8601String();

    // Generate cache key
    final cacheKey = CalculationCache.generateKey(
      operation: 'tax_included_after_discount',
      itemId: itemModel.id!,
      params: {
        'price': (saleItemPrice / updatedQty).toStringAsFixed(4),
        'qty': updatedQty.toString(),
        'taxes': taxModels.map((t) => '${t.id}:${t.rate}').join(','),
        'updated_price': priceUpdated.toStringAsFixed(4),
      },
    );

    // Try cache first
    final cached = CalculationCache.get(cacheKey);
    if (cached != null) {
      final cachedResult = cached.value as Map<String, dynamic>;
      prints('Cache HIT for tax included calculation: $cacheKey');

      return {
        ...cachedResult,
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': nowIso,
      };
    }

    // Calculate if not cached
    prints('Cache MISS for tax included calculation: $cacheKey');
    final stopwatch = Stopwatch()..start();

    final double newTaxIncludedAfterDiscount = _saleItemNotifier
        .getTaxIncludedAfterDiscountPerItem(
          priceUpdated,
          taxModels,
          itemModel,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    stopwatch.stop();
    prints('Tax included calculation took: ${stopwatch.elapsedMilliseconds}ms');

    final result = {
      'taxIncludedAfterDiscount': newTaxIncludedAfterDiscount,
      'saleItemId': newSaleItemId ?? saleItemExisting?.id,
      'updatedAt': nowIso,
    };

    // Cache result
    CalculationCache.set(cacheKey, {
      'taxIncludedAfterDiscount': newTaxIncludedAfterDiscount,
    });

    return result;
  }

  /// Optimized discount total calculation with caching
  Map<String, dynamic>? updatedTotalDiscountCached({
    required SaleItemModel? saleItemExisting,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) {
    final nowIso = now.toIso8601String();

    // Generate cache key
    final cacheKey = CalculationCache.generateKey(
      operation: 'discount_total',
      itemId: itemModel.id!,
      params: {
        'price_per_item': (saleItemPrice / updatedQty).toStringAsFixed(4),
        'qty': updatedQty.toString(),
        'discount_rules': itemModel.id ?? 'none',
      },
    );

    // Try cache first
    final cached = CalculationCache.get(cacheKey);
    if (cached != null) {
      final cachedResult = cached.value as Map<String, dynamic>;
      prints('Cache HIT for discount calculation: $cacheKey');

      return {
        ...cachedResult,
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': nowIso,
      };
    }

    // Calculate if not cached
    prints('Cache MISS for discount calculation: $cacheKey');
    final stopwatch = Stopwatch()..start();

    final double newTotalDiscount = _saleItemNotifier.discountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: saleItemPrice / updatedQty,
    );

    stopwatch.stop();
    prints('Discount calculation took: ${stopwatch.elapsedMilliseconds}ms');

    final result = {
      'discountTotal': newTotalDiscount,
      'saleItemId': newSaleItemId ?? saleItemExisting?.id,
      'updatedAt': nowIso,
    };

    // Cache result
    CalculationCache.set(cacheKey, {'discountTotal': newTotalDiscount});

    return result;
  }

  /// Optimized total after discount and tax calculation with caching
  Map<String, dynamic>? updatedTotalAfterDiscountAndTaxCached({
    required SaleItemModel? saleItemExisting,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
  }) {
    final nowIso = now.toIso8601String();

    // Generate cache key
    final cacheKey = CalculationCache.generateKey(
      operation: 'total_after_discount_tax',
      itemId: itemModel.id!,
      params: {
        'price_per_item': (saleItemPrice / updatedQty).toStringAsFixed(4),
        'qty': updatedQty.toString(),
        'taxes': taxModels.map((t) => '${t.id}:${t.rate}').join(','),
        'discount_rules': itemModel.id ?? 'none',
      },
    );

    // Try cache first
    final cached = CalculationCache.get(cacheKey);
    if (cached != null) {
      final cachedResult = cached.value as Map<String, dynamic>;
      prints('Cache HIT for total after discount/tax: $cacheKey');

      return {
        ...cachedResult,
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': nowIso,
      };
    }

    // Calculate if not cached
    prints('Cache MISS for total after discount/tax: $cacheKey');
    final stopwatch = Stopwatch()..start();

    final double newTotalAfterDiscountAndTax = _saleItemNotifier
        .totalAfterDiscountAndTax(
          saleItemPrice,
          itemModel,
          taxModels,
          updatedQty: updatedQty,
          itemPriceOrVariantPrice: saleItemPrice / updatedQty,
        );

    stopwatch.stop();
    prints('Total calculation took: ${stopwatch.elapsedMilliseconds}ms');

    final result = {
      'totalAfterDiscAndTax': newTotalAfterDiscountAndTax,
      'saleItemId': newSaleItemId ?? saleItemExisting?.id,
      'updatedAt': nowIso,
    };

    // Cache result
    CalculationCache.set(cacheKey, {
      'totalAfterDiscAndTax': newTotalAfterDiscountAndTax,
    });

    return result;
  }

  /// Invalidate cache when item properties change
  static void invalidateItemCache(String itemId) {
    CalculationCache.invalidateByPattern(itemId);
  }

  /// Invalidate cache when tax rules change
  static void invalidateTaxCache() {
    CalculationCache.invalidateByPattern('tax_');
  }

  /// Invalidate cache when discount rules change
  static void invalidateDiscountCache() {
    CalculationCache.invalidateByPattern('discount_');
  }

  /// Clean up expired cache entries (call periodically)
  static void cleanupCache() {
    CalculationCache.cleanupExpired();
  }

  /// Get cache performance statistics
  static Map<String, dynamic> getCacheStats() {
    return CalculationCache.getStats();
  }
}
