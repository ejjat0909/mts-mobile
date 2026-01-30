import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';

part 'item_tax_state.freezed.dart';

/// Immutable state class for ItemTax domain using Freezed
@freezed
class ItemTaxState with _$ItemTaxState {
  const factory ItemTaxState({
    @Default([]) List<ItemTaxModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _ItemTaxState;
}
