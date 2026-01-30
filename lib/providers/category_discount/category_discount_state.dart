import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';

part 'category_discount_state.freezed.dart';

/// Immutable state class for CategoryDiscount domain using Freezed
@freezed
class CategoryDiscountState with _$CategoryDiscountState {
  const factory CategoryDiscountState({
    @Default([]) List<CategoryDiscountModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _CategoryDiscountState;
}
