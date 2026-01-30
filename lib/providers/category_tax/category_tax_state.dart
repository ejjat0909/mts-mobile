import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';

part 'category_tax_state.freezed.dart';

/// Immutable state class for CategoryTax domain using Freezed
@freezed
class CategoryTaxState with _$CategoryTaxState {
  const factory CategoryTaxState({
    @Default([]) List<CategoryTaxModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _CategoryTaxState;
}
