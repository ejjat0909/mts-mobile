import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';

part 'inventory_state.freezed.dart';

/// Immutable state class for Inventory domain using Freezed
@freezed
class InventoryState with _$InventoryState {
  const factory InventoryState({
    @Default([]) List<InventoryModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _InventoryState;
}
