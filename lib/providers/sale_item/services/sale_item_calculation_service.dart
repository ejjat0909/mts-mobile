import 'package:mts/core/utils/calc_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';

/// Service class for handling all sale item calculation logic
/// This separates calculation logic from state management
class SaleItemCalculationService {
  /// Calculate total discount across all sale items
  double calculateTotalDiscount(List<Map<String, dynamic>> listTotalDiscount) {
    double total = 0;

    for (final discountMap in listTotalDiscount) {
      final value = discountMap['discountTotal'];
      if (value is num) {
        total += value.toDouble();
      }
    }

    return total;
  }

  /// Calculate total tax after discount
  double calculateTaxAfterDiscount(
    List<Map<String, dynamic>> listTaxAfterDiscount,
  ) {
    double total = 0;

    for (var taxMap in listTaxAfterDiscount) {
      total += (taxMap['taxAfterDiscount'] as double);
    }

    return total;
  }

  /// Calculate total included tax after discount
  double calculateTaxIncludedAfterDiscount(
    List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
  ) {
    double total = 0;

    for (var taxMap in listTaxIncludedAfterDiscount) {
      total += (taxMap['taxIncludedAfterDiscount'] as double);
    }

    return total;
  }

  /// Calculate total after discount and tax
  double calculateTotalAfterDiscountAndTax(
    List<Map<String, dynamic>> listTotalAfterDiscountAndTax,
  ) {
    double total = 0;

    for (final map in listTotalAfterDiscountAndTax) {
      total += map['totalAfterDiscAndTax'] as double;
    }

    return total;
  }

  /// Calculate total with adjusted price (after price adjustments)
  Map<String, double> calculateTotalWithAdjustedPrice({
    required double totalAfterDiscountAndTax,
    required double adjustedPrice,
    required PaymentTypeModel? paymentTypeModel,
  }) {
    double totalWithAdjustedPrice = totalAfterDiscountAndTax - adjustedPrice;

    if (totalWithAdjustedPrice <= 0) {
      totalWithAdjustedPrice = 0;
    }

    double afterCashRounding = CalcUtils.calcCashRounding(
      totalWithAdjustedPrice,
    );

    if (afterCashRounding < 0) {
      afterCashRounding = 0;
    }

    double totalAmountRemaining;

    if (paymentTypeModel?.id != null && paymentTypeModel!.autoRounding!) {
      totalAmountRemaining = afterCashRounding;
    } else {
      totalAmountRemaining = totalWithAdjustedPrice;
    }

    return {
      'totalWithAdjustedPrice': totalWithAdjustedPrice,
      'totalAmountRemaining': totalAmountRemaining,
    };
  }

  /// Calculate total costs across all sale items
  double calculateTotalCosts(List<SaleItemModel> saleItems) {
    double total = 0.0;

    for (final saleItem in saleItems) {
      if (saleItem.cost != null && saleItem.quantity != null) {
        total += (saleItem.cost! * saleItem.quantity!);
      }
    }

    return total;
  }

  /// Calculate gross amount for a single sale item
  double calculateGrossAmountPerSaleItem(SaleItemModel saleItem) {
    double grossAmount = 0.0;

    if (saleItem.price != null) {
      grossAmount = saleItem.price!;
    }

    if (saleItem.taxIncludedAfterDiscount != null) {
      grossAmount += saleItem.taxIncludedAfterDiscount!;
    }

    return grossAmount;
  }

  /// Calculate net sale for a single sale item
  double calculateNetSalePerSaleItem(SaleItemModel saleItem) {
    double netSale = 0.0;

    if (saleItem.price != null) {
      netSale = saleItem.price!;
    }

    return netSale;
  }

  /// Calculate total net sales across all sale items
  double calculateNetSales(List<SaleItemModel> saleItems) {
    double totalNetSales = 0.0;

    for (final saleItem in saleItems) {
      totalNetSales += calculateNetSalePerSaleItem(saleItem);
    }

    return totalNetSales;
  }

  /// Calculate total gross sales across all sale items
  double calculateGrossSales(List<SaleItemModel> saleItems) {
    double totalGrossSales = 0.0;

    for (final saleItem in saleItems) {
      final grossAmount = calculateGrossAmountPerSaleItem(saleItem);

      if (saleItem.discountTotal != null) {
        totalGrossSales += (grossAmount - saleItem.discountTotal!);
      } else {
        totalGrossSales += grossAmount;
      }
    }

    return totalGrossSales;
  }

  /// Calculate price per item based on item properties
  /// ItemModel only has a single 'price' field
  double calculatePricePerItem({
    required ItemModel itemModel,
    bool isCustomVariant = false,
    double? customVariantPrice,
  }) {
    // Use custom variant price if applicable, otherwise use item price
    if (isCustomVariant && customVariantPrice != null) {
      return customVariantPrice;
    }

    return itemModel.price ?? 0.0;
  }

  /// Calculate sale item price (total price = price per item * quantity)
  double calculateSaleItemPrice({
    required double pricePerItem,
    required double quantity,
    required List<dynamic> selectedModifierOptions,
  }) {
    double basePrice = pricePerItem * quantity;
    double modifierTotal = 0.0;

    // Add modifier option prices
    for (final modOption in selectedModifierOptions) {
      if (modOption.priceModifier != null) {
        modifierTotal += modOption.priceModifier! * quantity;
      }
    }

    return basePrice + modifierTotal;
  }

  /// Generate a unique hash for calculation state (for caching)
  String generateCalculationHash({
    required List<SaleItemModel> saleItems,
    required double adjustedPrice,
  }) {
    final itemIds = saleItems.map((e) => e.id).join(',');
    final itemQuantities = saleItems.map((e) => e.quantity).join(',');

    return '$itemIds-$itemQuantities-$adjustedPrice';
  }
}
