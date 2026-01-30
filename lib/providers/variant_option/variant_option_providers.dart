import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/providers/variant_option/variant_option_state.dart';

/// StateNotifier for VariantOption domain
class VariantOptionNotifier extends StateNotifier<VariantOptionState> {
  VariantOptionNotifier() : super(const VariantOptionState());

  List<VariantOptionModel> get getVariantOptionList => state.items;

  void setListVariantOption(List<VariantOptionModel> list) {
    state = state.copyWith(items: list);
  }

  void addOrUpdateList(List<VariantOptionModel> list) {
    final currentItems = List<VariantOptionModel>.from(state.items);

    for (VariantOptionModel variantOption in list) {
      int index = currentItems.indexWhere(
        (element) => element.id == variantOption.id,
      );

      if (index != -1) {
        currentItems[index] = variantOption;
      } else {
        currentItems.add(variantOption);
      }
    }
    state = state.copyWith(items: currentItems);
  }

  void addOrUpdate(VariantOptionModel variantOption) {
    final currentItems = List<VariantOptionModel>.from(state.items);
    int index = currentItems.indexWhere((m) => m.id == variantOption.id);

    if (index != -1) {
      currentItems[index] = variantOption;
    } else {
      currentItems.add(variantOption);
    }
    state = state.copyWith(items: currentItems);
  }

  void remove(String id) {
    final updatedItems =
        state.items.where((variantOption) => variantOption.id != id).toList();
    state = state.copyWith(items: updatedItems);
  }

  void reset() {
    state = const VariantOptionState();
  }
}

/// Provider for variantOption domain
final variantOptionProvider =
    StateNotifierProvider<VariantOptionNotifier, VariantOptionState>((ref) {
      return VariantOptionNotifier();
    });

/// Provider for sorted items (computed provider)
final sortedVariantOptionsProvider = Provider<List<VariantOptionModel>>((ref) {
  final items = ref.watch(variantOptionProvider).items;
  final sorted = List<VariantOptionModel>.from(items);
  sorted.sort(
    (a, b) =>
        (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
  );
  return sorted;
});

/// Provider for variantOption by ID (sync version - computed provider)
final variantOptionByIdProvider = Provider.family<VariantOptionModel?, String>((
  ref,
  id,
) {
  final items = ref.watch(variantOptionProvider).items;
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Provider for variantOptions by variant ID
final variantOptionsByVariantIdProvider =
    Provider.family<List<VariantOptionModel>, String>((ref, variantId) {
      final items = ref.watch(variantOptionProvider).items;
      return items.where((item) => item.variantId == variantId).toList();
    });

/// Provider for variantOptions count
final variantOptionsCountProvider = Provider<int>((ref) {
  final items = ref.watch(variantOptionProvider).items;
  return items.length;
});
