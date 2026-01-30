import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/discount_type_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/domain/repositories/local/category_discount_repository.dart';
import 'package:mts/domain/repositories/local/discount_item_repository.dart';
import 'package:mts/domain/repositories/local/discount_outlet_repository.dart';
import 'package:mts/domain/repositories/local/discount_repository.dart';
import 'package:mts/providers/discount/discount_providers.dart';

/// Service class for handling discount calculations for sale items
class SaleItemDiscountService {
  final Ref ref;

  SaleItemDiscountService(this.ref);

  /// Calculate total discount for a single item
  /// This considers all applicable discounts (outlet, item, category)
  Future<double> calculateDiscountTotalPerItem(
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    final discountNotifier = ref.read(discountProvider.notifier);

    // Get discount data from Hive repositories (synchronous)
    final discountRepo = ServiceLocator.get<LocalDiscountRepository>();
    final discountOutletRepo =
        ServiceLocator.get<LocalDiscountOutletRepository>();
    final discountItemRepo = ServiceLocator.get<LocalDiscountItemRepository>();
    final categoryDiscountRepo =
        ServiceLocator.get<LocalCategoryDiscountRepository>();

    final originDiscountList = await discountRepo.getListDiscountModel();
    final discountOutletList = await discountOutletRepo.getListDiscountOutlet();
    final discountItemList = await discountItemRepo.getListDiscountItem();
    final categoryDiscountList =
        await categoryDiscountRepo.getListCategoryDiscount();

    // Get all applicable discounts for this item
    List<DiscountModel> listDiscounts = discountNotifier
        .getAllDiscountModelsForThatItem(
          itemModel,
          [],
          originDiscountList: originDiscountList,
          discountOutletList: discountOutletList,
          discountItemList: discountItemList,
          categoryDiscountList: categoryDiscountList,
        );

    // Calculate total discount (both fixed amount and percentage)
    double totalDiscount = listDiscounts.fold(0.0, (total, discount) {
      double discountFixTotal = 0.0;
      double discountPercentageTotal = 0.0;

      if (discount.type == DiscountTypeEnum.amount) {
        // Fixed amount discount
        discountFixTotal += discount.value ?? 0.0;
      } else {
        // Percentage discount (e.g., 1%, 2%)
        discountPercentageTotal +=
            (discount.value ?? 0.0) * itemPriceOrVariantPrice / 100;
      }

      return total + discountFixTotal + discountPercentageTotal;
    });

    // Multiply by quantity to get total discount for all items
    return totalDiscount * updatedQty;
  }

  /// Update total discount in a map for state management
  /// Returns a map containing discount information
  Future<Map<String, dynamic>?> updatedTotalDiscount({
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

      // Calculate discount total
      final double discountTotal = await calculateDiscountTotalPerItem(
        itemModel,
        updatedQty: updatedQty,
        itemPriceOrVariantPrice: pricePerItem,
      );

      // Ensure discount is not negative
      final double validatedDiscount = discountTotal < 0 ? 0.0 : discountTotal;

      // Create discount map
      return {
        'saleItemId': newSaleItemId ?? saleItemExisting?.id,
        'updatedAt': now.toIso8601String(),
        'discountTotal': validatedDiscount,
        'itemId': itemModel.id,
        'quantity': updatedQty,
        'pricePerItem': pricePerItem,
      };
    } catch (e, stack) {
      prints('Error in updatedTotalDiscount: $e');
      prints('Stack: $stack');
      return null;
    }
  }

  /// Calculate discounts for multiple items
  List<Map<String, dynamic>> calculateDiscountsForItems({
    required List<Map<String, dynamic>> items,
  }) {
    final List<Map<String, dynamic>> discounts = [];

    for (final item in items) {
      final itemModel = item['itemModel'] as ItemModel?;
      final quantity = item['quantity'] as double? ?? 1.0;
      final price = item['price'] as double? ?? 0.0;

      if (itemModel != null) {
        final discount = calculateDiscountTotalPerItem(
          itemModel,
          updatedQty: quantity,
          itemPriceOrVariantPrice: price / quantity,
        );

        discounts.add({
          'itemId': itemModel.id,
          'discountTotal': discount,
          'quantity': quantity,
        });
      }
    }

    return discounts;
  }

  /// Validate and sanitize discount amount
  double validateDiscountAmount(double discount) {
    if (discount < 0) return 0.0;
    if (discount.isNaN || discount.isInfinite) return 0.0;
    return discount;
  }

  /// Calculate net price after discount
  double calculateNetPriceAfterDiscount({
    required double grossPrice,
    required double discount,
  }) {
    final netPrice = grossPrice - discount;
    return netPrice < 0 ? 0.0 : netPrice;
  }

  /// Get discount percentage from discount models
  double getDiscountPercentage(List<DiscountModel> discounts) {
    return discounts.fold(0.0, (total, discount) {
      if (discount.type == DiscountTypeEnum.percentage) {
        return total + (discount.value ?? 0.0);
      }
      return total;
    });
  }

  /// Get fixed discount amount from discount models
  double getFixedDiscountAmount(List<DiscountModel> discounts) {
    return discounts.fold(0.0, (total, discount) {
      if (discount.type == DiscountTypeEnum.amount) {
        return total + (discount.value ?? 0.0);
      }
      return total;
    });
  }
}
