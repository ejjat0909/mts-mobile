import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/sale/sale_model.dart';

part 'sale_state.freezed.dart';

/// Immutable state class for Sale domain using Freezed
@freezed
class SaleState with _$SaleState {
  const factory SaleState({
    @Default([]) List<SaleModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _SaleState;
}
