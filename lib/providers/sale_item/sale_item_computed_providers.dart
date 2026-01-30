import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

/// ============================================================================
/// COMPUTED PROVIDERS FOR SALE ITEMS
/// ============================================================================
/// These providers extract specific pieces of state for optimal performance
/// Use .select() to listen only to what you need, preventing unnecessary rebuilds

/// Selector: Listen only to saleItems list
final saleItemsListProvider = Provider<List<SaleItemModel>>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.saleItems));
});

/// Selector: Listen only to orderOptionModel
final orderOptionModelProvider = Provider<OrderOptionModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.orderOptionModel));
});

/// Selector: Listen only to selectedTable
final selectedTableProvider = Provider<TableModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.selectedTable));
});

/// Selector: Listen only to currSaleModel
final currSaleModelProvider = Provider<SaleModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.currSaleModel));
});

/// Selector: Listen only to predefined order
final predefinedOrderModelProvider = Provider<PredefinedOrderModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.pom));
});

/// Selector: Listen only to payment type model
final paymentTypeModelProvider = Provider<PaymentTypeModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.paymentTypeModel));
});

/// Selector: Listen only to total price calculations
final totalPriceProvider = Provider<double>((ref) {
  return ref.watch(
    saleItemProvider.select((state) => state.totalAfterDiscountAndTax),
  );
});

/// Selector: Listen only to isSplitPayment flag
final isSplitPaymentProvider = Provider<bool>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.isSplitPayment));
});

/// Selector: Listen only to total discount
final totalDiscountProvider = Provider<double>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.totalDiscount));
});

/// Selector: Listen only to tax after discount
final taxAfterDiscountProvider = Provider<double>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.taxAfterDiscount));
});

/// Selector: Listen only to included tax after discount
final taxIncludedAfterDiscountProvider = Provider<double>((ref) {
  return ref.watch(
    saleItemProvider.select((state) => state.taxIncludedAfterDiscount),
  );
});

/// Selector: Listen only to adjusted price
final adjustedPriceProvider = Provider<double>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.adjustedPrice));
});

/// Selector: Listen only to total with adjusted price
final totalWithAdjustedPriceProvider = Provider<double>((ref) {
  return ref.watch(
    saleItemProvider.select((state) => state.totalWithAdjustedPrice),
  );
});

/// Selector: Listen only to total amount remaining
final totalAmountRemainingProvider = Provider<double>((ref) {
  return ref.watch(
    saleItemProvider.select((state) => state.totalAmountRemaining),
  );
});

/// Selector: Listen only to canBackToSalesPage flag
final canBackToSalesPageProvider = Provider<bool>((ref) {
  return ref.watch(
    saleItemProvider.select((state) => state.canBackToSalesPage),
  );
});

/// Selector: Listen only to isEditMode flag
final isEditModeProvider = Provider<bool>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.isEditMode));
});

/// ============================================================================
/// COMPUTED/DERIVED PROVIDERS
/// ============================================================================
/// These calculate values based on the current state

/// Get count of sale items
final saleItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(saleItemsListProvider);
  return items.length;
});

/// Get total quantity of all items
final totalQuantityProvider = Provider<double>((ref) {
  final items = ref.watch(saleItemsListProvider);
  return items.fold(0.0, (sum, item) => sum + (item.quantity ?? 0.0));
});

// NOTE: SaleItemModel doesn't have predefinedOrderId field.
// If this functionality is needed, it would require adding the field to the model
// or fetching from a relationship/join table.

/// Get sale items by category ID
final saleItemsByCategoryProvider =
    Provider.family<List<SaleItemModel>, String?>((ref, categoryId) {
      final items = ref.watch(saleItemsListProvider);
      if (categoryId == null) return [];

      return items.where((item) => item.categoryId == categoryId).toList();
    });

/// Get voided sale items
final voidedSaleItemsProvider = Provider<List<SaleItemModel>>((ref) {
  final items = ref.watch(saleItemsListProvider);
  return items.where((item) => item.isVoided == true).toList();
});

/// Get active (non-voided) sale items
final activeSaleItemsProvider = Provider<List<SaleItemModel>>((ref) {
  final items = ref.watch(saleItemsListProvider);
  return items.where((item) => item.isVoided != true).toList();
});

/// Get total for active items only
final activeSaleItemsTotalProvider = Provider<double>((ref) {
  final items = ref.watch(activeSaleItemsProvider);
  return items.fold(
    0.0,
    (sum, item) => sum + (item.totalAfterDiscAndTax ?? 0.0),
  );
});

/// Get sale items sorted by creation date
final saleItemsSortedByDateProvider = Provider<List<SaleItemModel>>((ref) {
  final items = ref.watch(saleItemsListProvider);
  final sortedItems = List<SaleItemModel>.from(items);
  sortedItems.sort((a, b) {
    if (a.createdAt == null && b.createdAt == null) return 0;
    if (a.createdAt == null) return 1;
    if (b.createdAt == null) return -1;
    return a.createdAt!.compareTo(b.createdAt!);
  });
  return sortedItems;
});

/// Check if cart has items
final hasItemsInCartProvider = Provider<bool>((ref) {
  final items = ref.watch(activeSaleItemsProvider);
  return items.isNotEmpty;
});

/// Check if cart is empty
final isCartEmptyProvider = Provider<bool>((ref) {
  final items = ref.watch(activeSaleItemsProvider);
  return items.isEmpty;
});

/// Get subtotal before discount and tax
final subtotalBeforeDiscountProvider = Provider<double>((ref) {
  final items = ref.watch(activeSaleItemsProvider);
  return items.fold(0.0, (sum, item) => sum + (item.price ?? 0.0));
});

/// Calculate total savings (discounts)
final totalSavingsProvider = Provider<double>((ref) {
  final totalDiscount = ref.watch(totalDiscountProvider);
  return totalDiscount;
});

/// Get sale items grouped by category
final saleItemsGroupedByCategoryProvider =
    Provider<Map<String?, List<SaleItemModel>>>((ref) {
      final items = ref.watch(activeSaleItemsProvider);
      final Map<String?, List<SaleItemModel>> grouped = {};

      for (final item in items) {
        if (!grouped.containsKey(item.categoryId)) {
          grouped[item.categoryId] = [];
        }
        grouped[item.categoryId]!.add(item);
      }

      return grouped;
    });

/// Check if payment can proceed (has items and total > 0)
final canProceedToPaymentProvider = Provider<bool>((ref) {
  final hasItems = ref.watch(hasItemsInCartProvider);
  final total = ref.watch(totalPriceProvider);
  return hasItems && total > 0;
});

/// Get sale item by ID
final saleItemByIdProvider = Provider.family<SaleItemModel?, String>((
  ref,
  itemId,
) {
  final items = ref.watch(saleItemsListProvider);
  try {
    return items.firstWhere((item) => item.id == itemId);
  } catch (_) {
    return null;
  }
});

/// Check if specific item is in cart
final isItemInCartProvider = Provider.family<bool, String>((ref, itemId) {
  final item = ref.watch(saleItemByIdProvider(itemId));
  return item != null && item.isVoided != true;
});

/// Get quantity of specific item in cart
final itemQuantityInCartProvider = Provider.family<double, String>((
  ref,
  itemId,
) {
  final item = ref.watch(saleItemByIdProvider(itemId));
  return item?.quantity ?? 0.0;
});
