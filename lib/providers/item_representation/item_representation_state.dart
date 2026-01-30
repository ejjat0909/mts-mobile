import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';

part 'item_representation_state.freezed.dart';

@freezed
class ItemRepresentationState with _$ItemRepresentationState {
  const factory ItemRepresentationState({
    @Default([]) List<ItemRepresentationModel> items,
    @Default(false) bool isLoading,
    String? error,
  }) = _ItemRepresentationState;
}
