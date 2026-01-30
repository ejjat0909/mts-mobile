import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/tax/tax_model.dart';

part 'tax_state.freezed.dart';

/// Immutable state class for Tax domain using Freezed
@freezed
class TaxState with _$TaxState {
  const factory TaxState({
    @Default([]) List<TaxModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _TaxState;
}
