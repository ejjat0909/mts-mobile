import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/tax_type_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/providers/sale_item/services/sale_item_discount_service.dart';

/// Service class for handling tax calculations for sale items
class SaleItemTaxService {
  final Ref ref;
  final SaleItemDiscountService discountService;

  SaleItemTaxService(this.ref, this.discountService);

  /// Calculate tax after discount for a single item (Added tax type only)
  /// Formula: (subtotal - discount) * taxRate / 100
  Future<double> calculateTaxAfterDiscountPerItem(
    double netSaleItem,
    List<TaxModel> taxModels,
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    double subNetSaleItem = netSaleItem;

    // Calculate total tax percentage for TaxTypeEnum.Added only
    double taxPercent = taxModels.fold(0.0, (total, taxModel) {
      if (taxModel.type == TaxTypeEnum.Added) {
        return total + (taxModel.rate ?? 0.0);
      }
      return total;
    });

    // Calculate discount amount
    double discountAmount = await discountService.calculateDiscountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );

    // Ensure discount is not negative
    if (discountAmount < 0) {
      discountAmount = 0;
    }

    // Calculate price after discount
    double priceAfterDiscount = subNetSaleItem - discountAmount;

    // Calculate tax on the discounted price
    double totalTax = priceAfterDiscount * (taxPercent / 100);

    prints("TOTAL TAX AFTER DISCOUNT: $totalTax");
    return totalTax <= 0 ? 0 : totalTax;
  }

  /// Calculate included tax after discount for a single item
  /// Formula: (subtotal - discount) * taxRate / 100
  Future<double> calculateTaxIncludedAfterDiscountPerItem(
    double netSaleItem,
    List<TaxModel> taxModels,
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    double subNetSaleItem = netSaleItem;

    // Calculate total tax percentage for TaxTypeEnum.Included only
    double taxPercent = taxModels.fold(0.0, (total, taxModel) {
      if (taxModel.type == TaxTypeEnum.Included) {
        return total + (taxModel.rate ?? 0.0);
      }
      return total;
    });

    // Calculate discount amount
    double discountAmount = await discountService.calculateDiscountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );

    // Ensure discount is not negative
    if (discountAmount < 0) {
      discountAmount = 0;
    }

    // Calculate price after discount
    double priceAfterDiscount = subNetSaleItem - discountAmount;

    // Calculate included tax on the discounted price
    double totalTax = priceAfterDiscount * (taxPercent / 100);

    prints("TOTAL TAX INCLUDED AFTER DISCOUNT: $totalTax");
    return totalTax <= 0 ? 0 : totalTax;
  }

  /// Calculate total after applying both discount and tax
  Future<double> calculateTotalAfterDiscountAndTax(
    double subTotalPrice,
    ItemModel itemModel,
    List<TaxModel> taxModels, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    // Calculate tax (added type)
    double totalTax = await calculateTaxAfterDiscountPerItem(
      subTotalPrice,
      taxModels,
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );

    // Calculate discount
    double totalDiscount = await discountService.calculateDiscountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );

    // Final total: (subtotal - discount) + tax
    return (subTotalPrice - totalDiscount) + totalTax;
  }

  /// Update tax after discount in a map for state management
  Future<Map<String, dynamic>?> updatedTaxAfterDiscount({
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required ItemModel itemModel,
    required DateTime now,
    required double updatedQty,
    required double saleItemPrice,
    String? newSaleItemId,
    dynamic saleItemExisting,
  }) async {
    try {
      // Calculate price per item
      final double pricePerItem = saleItemPrice / updatedQty;

      // Calculate tax after discount
      final double taxAfterDiscount = await calculateTaxAfterDiscountPerItem(
        priceUpdated,
        taxModels,
        itemModel,
        updatedQty: updatedQty,
        itemPriceOrVariantPrice: pricePerItem,
      );

      // Create tax map
      return {
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': now.toIso8601String(),
        'taxAfterDiscount': taxAfterDiscount,
        'itemId': itemModel.id,
        'quantity': updatedQty,
        'pricePerItem': pricePerItem,
      };
    } catch (e, stack) {
      prints('Error in updatedTaxAfterDiscount: $e');
      prints('Stack: $stack');
      return null;
    }
  }

  /// Update included tax after discount in a map for state management
  Future<Map<String, dynamic>?> updatedTaxIncludedAfterDiscount({
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required ItemModel itemModel,
    required DateTime now,
    required double updatedQty,
    required double saleItemPrice,
    String? newSaleItemId,
    dynamic saleItemExisting,
  }) async {
    try {
      // Calculate price per item
      final double pricePerItem = saleItemPrice / updatedQty;

      // Calculate included tax after discount
      final double taxIncludedAfterDiscount =
          await calculateTaxIncludedAfterDiscountPerItem(
            priceUpdated,
            taxModels,
            itemModel,
            updatedQty: updatedQty,
            itemPriceOrVariantPrice: pricePerItem,
          );

      // Create tax map
      return {
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': now.toIso8601String(),
        'taxIncludedAfterDiscount': taxIncludedAfterDiscount,
        'itemId': itemModel.id,
        'quantity': updatedQty,
        'pricePerItem': pricePerItem,
      };
    } catch (e, stack) {
      prints('Error in updatedTaxIncludedAfterDiscount: $e');
      prints('Stack: $stack');
      return null;
    }
  }

  /// Update total after discount and tax in a map for state management
  Future<Map<String, dynamic>?> updatedTotalAfterDiscountAndTax({
    required List<TaxModel> taxModels,
    required ItemModel itemModel,
    required double saleItemPrice,
    required DateTime now,
    required double updatedQty,
    String? newSaleItemId,
    dynamic saleItemExisting,
  }) async {
    try {
      // Calculate price per item
      final double pricePerItem = saleItemPrice / updatedQty;

      // Calculate total after discount and tax
      final double totalAfterDiscAndTax = await calculateTotalAfterDiscountAndTax(
        saleItemPrice,
        itemModel,
        taxModels,
        updatedQty: updatedQty,
        itemPriceOrVariantPrice: pricePerItem,
      );

      // Create total map
      return {
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': now.toIso8601String(),
        'totalAfterDiscAndTax': totalAfterDiscAndTax,
        'itemId': itemModel.id,
        'quantity': updatedQty,
        'pricePerItem': pricePerItem,
      };
    } catch (e, stack) {
      prints('Error in updatedTotalAfterDiscountAndTax: $e');
      prints('Stack: $stack');
      return null;
    }
  }

  /// Get total tax rate for a specific tax type
  double getTotalTaxRate(List<TaxModel> taxModels, TaxTypeEnum taxType) {
    return taxModels.fold(0.0, (total, taxModel) {
      if (taxModel.type == taxType) {
        return total + (taxModel.rate ?? 0.0);
      }
      return total;
    });
  }

  /// Get order option taxes for calculations
  List<TaxModel> getOrderOptionTaxes(OrderOptionModel? orderOptionModel) {
    // Implementation depends on how order option taxes are stored
    // This is a placeholder that returns empty list
    return [];
  }

  /// Validate and sanitize tax amount
  double validateTaxAmount(double tax) {
    if (tax < 0) return 0.0;
    if (tax.isNaN || tax.isInfinite) return 0.0;
    return tax;
  }
}
