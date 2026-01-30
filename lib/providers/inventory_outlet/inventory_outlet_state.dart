import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';

part 'inventory_outlet_state.freezed.dart';

/// Immutable state class for InventoryOutlet domain using Freezed
@freezed
class InventoryOutletState with _$InventoryOutletState {
  const factory InventoryOutletState({
    @Default([]) List<InventoryOutletModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _InventoryOutletState;
}
