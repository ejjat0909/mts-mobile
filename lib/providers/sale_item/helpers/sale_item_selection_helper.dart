import '../../../data/models/sale/sale_model.dart';
import '../sale_item_state.dart';

/// Helper class for sale item selection operations
/// Extracted from SaleItemNotifier to improve maintainability
class SaleItemSelectionHelper {
  /// Clears all selected open orders
  void clearSelections(
    SaleItemState state,
    Function(SaleItemState) updateState,
  ) {
    updateState(state.copyWith(selectedOpenOrders: []));
  }

  /// Deselects all open orders
  void deselectAll(SaleItemState state, Function(SaleItemState) updateState) {
    updateState(state.copyWith(selectedOpenOrders: []));
  }

  /// Selects all provided orders
  void selectAll(
    List<SaleModel> orders,
    SaleItemState state,
    Function(SaleItemState) updateState,
  ) {
    final currentSelected = Set<SaleModel>.from(state.selectedOpenOrders);
    currentSelected.addAll(orders);
    updateState(state.copyWith(selectedOpenOrders: currentSelected.toList()));
  }

  /// Checks if all open orders are selected
  bool isAllOpenOrderSelected(List<SaleModel> orders, SaleItemState state) {
    if (orders.isEmpty) return false;

    final selectedSet = Set<SaleModel>.from(state.selectedOpenOrders);
    return orders.every((order) => selectedSet.contains(order));
  }

  /// Toggles the selection state of a specific open order
  void toggleOpenOrderSelection(
    SaleModel saleModel,
    SaleItemState state,
    Function(SaleItemState) updateState,
  ) {
    final currentSelected = Set<SaleModel>.from(state.selectedOpenOrders);

    // Toggle using XOR logic - O(1) operation
    if (currentSelected.contains(saleModel)) {
      currentSelected.remove(saleModel);
    } else {
      currentSelected.add(saleModel);
    }

    updateState(state.copyWith(selectedOpenOrders: currentSelected.toList()));
  }
}
