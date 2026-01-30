import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';

part 'inventory_transaction_state.freezed.dart';

/// Immutable state class for InventoryTransaction domain using Freezed
@freezed
class InventoryTransactionState with _$InventoryTransactionState {
  const factory InventoryTransactionState({
    @Default([]) List<InventoryTransactionModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _InventoryTransactionState;
}
