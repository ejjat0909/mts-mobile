import '../../../data/models/modifier/modifier_model.dart';
import '../../../data/models/modifier_option/modifier_option_model.dart';
import '../../../data/models/sale_modifier/sale_modifier_model.dart';
import '../sale_item_state.dart';

/// Helper class for sale modifier operations
/// Extracted from SaleItemNotifier to improve maintainability
class SaleItemModifierHelper {
  void deleteSaleModifierModelAndSaleModifierOptionModel(
    String saleItemModelId,
    DateTime updatedAt,
    SaleItemState state,
    Function(SaleItemState) updateState,
  ) {
    // Collect IDs to remove using Set for O(1) lookup
    final saleModifierIdsToRemove = <String>{};
    final updatedSaleModifiers = <SaleModifierModel>[];

    // Single pass to filter modifiers and collect IDs
    for (final modifier in state.saleModifiers) {
      if (modifier.saleItemId == saleItemModelId &&
          modifier.updatedAt == updatedAt) {
        if (modifier.id != null) {
          saleModifierIdsToRemove.add(modifier.id!);
        }
      } else {
        updatedSaleModifiers.add(modifier);
      }
    }

    // Filter modifier options using Set for O(1) contains check
    final updatedSaleModifierOptions =
        state.saleModifierOptions
            .where((e) => !saleModifierIdsToRemove.contains(e.saleModifierId))
            .toList();

    updateState(
      state.copyWith(
        saleModifiers: updatedSaleModifiers,
        saleModifierOptions: updatedSaleModifierOptions,
      ),
    );
  }

  /// Adds or updates modifier options in state
  /// Merges new options with existing ones by ID
  void addOrUpdateModifierOptionList(
    List<ModifierOptionModel> listModOpt,
    SaleItemState state,
    Function(SaleItemState) updateState,
  ) {
    // Create a map of existing modifier options by ID for quick lookup
    final existingModifierOptionsMap = {
      for (var modifierOption in state.listModifierOptionDB)
        if (modifierOption.id != null) modifierOption.id!: modifierOption,
    };

    // Update existing options and add new ones
    for (var newModifierOption in listModOpt) {
      if (newModifierOption.id != null) {
        existingModifierOptionsMap[newModifierOption.id!] = newModifierOption;
      }
    }

    // Convert back to list and update state
    final mergedModifierOptions = existingModifierOptionsMap.values.toList();
    updateState(state.copyWith(listModifierOptionDB: mergedModifierOptions));
  }

  /// Adds or updates modifiers in state
  /// Merges new modifiers with existing ones by ID
  void addOrUpdateModifierList(
    List<ModifierModel> listMod,
    SaleItemState state,
    Function(SaleItemState) updateState,
  ) {
    // Create a map of existing modifiers by ID for quick lookup
    final existingModifiersMap = {
      for (var modifier in state.listModifiers)
        if (modifier.id != null) modifier.id!: modifier,
    };

    // Update existing modifiers and collect new ones
    for (var newModifier in listMod) {
      if (newModifier.id != null) {
        existingModifiersMap[newModifier.id!] = newModifier;
      }
    }

    // Convert back to list and update state
    final mergedModifiers = existingModifiersMap.values.toList();
    updateState(state.copyWith(listModifiers: mergedModifiers));
  }
}
