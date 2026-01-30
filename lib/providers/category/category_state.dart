import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/category/category_model.dart';

part 'category_state.freezed.dart';

/// Immutable state class for Category domain using Freezed
@freezed
class CategoryState with _$CategoryState {
  const factory CategoryState({@Default([]) List<CategoryModel> categories}) =
      _CategoryState;
}
