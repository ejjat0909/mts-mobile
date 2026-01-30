import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/providers/split_order/split_order_state.dart';

/// StateNotifier for SplitOrder domain
class SplitOrderNotifier extends StateNotifier<SplitOrderState> {
  SplitOrderNotifier() : super(const SplitOrderState());

  List<List<SaleItemModel>> get getCards => state.cards;

  int get getSelectedItemCount => state.selectedItems.length;

  void addCard() {
    final updatedCards = [...state.cards, <SaleItemModel>[]];
    state = state.copyWith(cards: updatedCards);
  }

  void removeCard(int index) {
    //prevent remove the first card
    if (index == 0) {
      return;
    }

    final cards = List<List<SaleItemModel>>.from(state.cards);
    final removedItems = cards[index];
    cards.removeAt(index);

    //move removed items to the previous card
    int prevIdx = index - 1;
    cards[prevIdx] = [...cards[prevIdx], ...removedItems];

    state = state.copyWith(cards: cards);
  }

  void onSelectItem(int cardIdx, SaleItemModel item) {
    final selectedItems = Map<int, List<SaleItemModel>>.from(
      state.selectedItems,
    );

    if (selectedItems.containsKey(cardIdx)) {
      selectedItems[cardIdx] = [...selectedItems[cardIdx]!, item];
    } else {
      selectedItems[cardIdx] = [item];
    }

    state = state.copyWith(selectedItems: selectedItems);
  }

  void reset() {
    state = const SplitOrderState();
  }
}

/// Provider for splitOrder domain
final splitOrderProvider =
    StateNotifierProvider<SplitOrderNotifier, SplitOrderState>((ref) {
      return SplitOrderNotifier();
    });

/// Provider for cards
final splitOrderCardsProvider = Provider<List<List<SaleItemModel>>>((ref) {
  return ref.watch(splitOrderProvider).cards;
});

/// Provider for selected items count
final splitOrderSelectedItemCountProvider = Provider<int>((ref) {
  return ref.watch(splitOrderProvider).selectedItems.length;
});

/// Provider for card count
final splitOrderCardCountProvider = Provider<int>((ref) {
  return ref.watch(splitOrderProvider).cards.length;
});

/// Provider for selected items
final splitOrderSelectedItemsProvider = Provider<Map<int, List<SaleItemModel>>>(
  (ref) {
    return ref.watch(splitOrderProvider).selectedItems;
  },
);

/// Provider for card by index
final splitOrderCardByIndexProvider = Provider.family<List<SaleItemModel>, int>(
  (ref, index) {
    final cards = ref.watch(splitOrderProvider).cards;
    if (index >= 0 && index < cards.length) {
      return cards[index];
    }
    return [];
  },
);
