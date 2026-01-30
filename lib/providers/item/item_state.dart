import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';

part 'item_state.freezed.dart';

/// Immutable state class for Item domain using Freezed
@freezed
class ItemState with _$ItemState {
  const factory ItemState({
    @Default([]) List<ItemModel> items,
    @Default([]) List<ItemRepresentationModel> itemRepresentations,
    String? error,
    @Default(false) bool isLoading,
    // Old notifier UI state fields
    @Default('') String itemName,
    @Default('') String searchItemName,
    @Default('MAIN') String dialogueNavigation,
    VariantOptionModel? tempVariantOptionModel,
    @Default([]) List<VariantOptionModel> listVariantOptions,
    // Price pad dialogue state
    String? tempPrice,
    String? previousPrice,
    String? selectedPrice,
    // Qty pad dialogue state
    String? tempQty,
    String? previousQty,
    String? selectedQty,
  }) = _ItemState;
}
