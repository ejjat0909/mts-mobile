import 'dart:convert';

import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_crud_helper.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/providers/tax/tax_providers.dart';

/// Router helper class for handling all 17 cases in createAndUpdateSaleItems
/// Extracts case routing logic from SaleItemNotifier for better maintainability
/// and testability. Each case is a separate private method.
class SaleItemCaseRouter {
  final Ref _ref;
  final SaleItemCrudHelper _crudHelper;

  SaleItemCaseRouter(this._ref, this._crudHelper);

  /// Main orchestrator method - handles all 17 cases of sale item creation/update
  /// Routes to appropriate private case method based on conditions
  Future<Map<String, dynamic>> createAndUpdateSaleItems(
    ItemModel itemModel, {
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required String? newSaleItemUuid,
    required SaleItemModel? existingSaleItem,
    required double saleItemPrice,
    required String comments,
    required double pricePerItem,
    required bool isCustomVariant,
    VariantOptionModel? varOptModel,
    List<ModifierOptionModel>? listModOpt,
    required List<String> listModifierOptionIds,
    double qty = 1,
  }) async {
    List<TaxModel> taxModels = [];
    final taxNotifier = _ref.read(taxProvider.notifier);
    taxModels = taxNotifier.getAllTaxModelsForThatItem(itemModel, taxModels);
    prints(taxModels.map((e) => e.id).toList());

    if (itemModel.price != null &&
        existingSaleItem == null &&
        varOptModel != null &&
        listModOpt != null) {
      return await _handleCase1And2(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        varOptModel: varOptModel,
        listModOpt: listModOpt,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        pricePerItem: pricePerItem,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        isCustomVariant: isCustomVariant,
      );
    } else if (itemModel.price != null &&
        existingSaleItem == null &&
        varOptModel == null &&
        listModOpt == null) {
      return await _handleCase3And4(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        comments: comments,
        pricePerItem: pricePerItem,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
      );
    } else if (itemModel.price != null &&
        existingSaleItem != null &&
        varOptModel == null) {
      return await _handleCase5And6(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        existingSaleItem: existingSaleItem,
        listModifierOptionIds: listModifierOptionIds,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
      );
    } else if (itemModel.price != null &&
        existingSaleItem != null &&
        varOptModel!.id != null) {
      return _handleCase7And8(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        existingSaleItem: existingSaleItem,
        varOptModel: varOptModel,
        listModifierOptionIds: listModifierOptionIds,
        pricePerItem: pricePerItem,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        isCustomVariant: isCustomVariant,
      );
    } else if (existingSaleItem == null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel == null &&
        listModOpt != null) {
      return _handleCase9And10(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        pricePerItem: pricePerItem,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        saleItemPrice: saleItemPrice,
      );
    } else if (existingSaleItem == null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel != null &&
        listModOpt != null) {
      return _handleCase11And12(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        varOptModel: varOptModel,
        pricePerItem: pricePerItem,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        saleItemPrice: saleItemPrice,
        isCustomVariant: isCustomVariant,
      );
    } else if (existingSaleItem != null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel == null &&
        listModOpt != null) {
      return _handleCase13And14(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        existingSaleItem: existingSaleItem,
        listModifierOptionIds: listModifierOptionIds,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        pricePerItem: pricePerItem,
      );
    } else if (existingSaleItem != null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel != null &&
        listModOpt != null) {
      return _handleCase15And16(
        itemModel: itemModel,
        state: state,
        updateState: updateState,
        getMapDataToTransfer: getMapDataToTransfer,
        existingSaleItem: existingSaleItem,
        varOptModel: varOptModel,
        listModifierOptionIds: listModifierOptionIds,
        pricePerItem: pricePerItem,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        isCustomVariant: isCustomVariant,
      );
    }

    // CASE 17 - fallback when no condition matches
    return _handleCase17(getMapDataToTransfer);
  }

  /// CASE 1 & 2: Item with price, no existing sale item, has variant and modifiers
  /// Checks if variant/comment/modifier combination exists to decide update vs insert
  Future<Map<String, dynamic>> _handleCase1And2({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required VariantOptionModel varOptModel,
    required List<ModifierOptionModel> listModOpt,
    required String comments,
    required List<String> listModifierOptionIds,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required bool isCustomVariant,
  }) async {
    bool isVariantIdCommentModifierExist = state.saleItems.any((element) {
      bool isVariantAndCommentSale =
          element.variantOptionId == varOptModel.id &&
          element.comments == comments &&
          element.id ==
              IdUtils.generateHashId(
                varOptModel.id!,
                listModifierOptionIds,
                comments,
                itemModel.id!,
                cost: pricePerItem,
                variantPrice: varOptModel.price,
              );

      return isVariantAndCommentSale;
    });

    if (isVariantIdCommentModifierExist) {
      prints('CASE 1');
      return await _crudHelper.updateSaleItemHaveVariantAndModifier(
        state: state,
        updateState: updateState,
        varOptModel: varOptModel,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        itemModel: itemModel,
        pricePerItem: pricePerItem,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        isCustomVariant: isCustomVariant,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 2');
      return await _crudHelper.insertSaleItemHaveVariantAndModifier(
        state: state,
        updateState: updateState,
        varOptModel: varOptModel,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        itemModel: itemModel,
        pricePerItem: pricePerItem,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        isCustomVariant: isCustomVariant,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 3 & 4: Direct add item with price, no existing sale item, no variant/modifiers
  /// Checks if item ID exists to decide update vs new sale item
  Future<Map<String, dynamic>> _handleCase3And4({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required String comments,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
  }) async {
    String incomingSaleItemId =
        itemModel.soldBy == ItemSoldByEnum.item
            ? itemModel.id!
            : IdUtils.generateHashId(
              null,
              [],
              comments,
              itemModel.id!,
              cost: pricePerItem,
              variantPrice: null,
              qty: qty,
            );

    bool isItemIdExist = state.saleItems.any(
      (element) => element.id == incomingSaleItemId,
    );

    if (isItemIdExist) {
      prints('CASE 3');
      return await _crudHelper.updateSaleItemNoVariantAndModifier(
        state: state,
        updateState: updateState,
        incomingSaleItemId: incomingSaleItemId,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 4');
      return await _crudHelper.newSaleItemNoVariantAndModifier(
        state: state,
        updateState: updateState,
        itemModel: itemModel,
        incomingSaleItemId: incomingSaleItemId,
        saleItemPrice: saleItemPrice,
        taxModels: taxModels,
        pricePerItem: pricePerItem,
        qty: qty,
        comments: comments,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 5 & 6: Item from order list without variant
  /// Checks if existing sale item ID matches item ID
  Future<Map<String, dynamic>> _handleCase5And6({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required SaleItemModel existingSaleItem,
    required List<String> listModifierOptionIds,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
  }) async {
    if (existingSaleItem.id == itemModel.id) {
      prints('CASE 5');
      return await _crudHelper.updateFromOrderListNoVariant(
        state: state,
        updateState: updateState,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 6');
      return await _crudHelper.updateFromOrderListExistingNotSameWithItem(
        state: state,
        updateState: updateState,
        existingSaleItem: existingSaleItem,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 7 & 8: Item from order list with variant
  /// Compares existing hash ID to determine correct update path
  Future<Map<String, dynamic>> _handleCase7And8({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required SaleItemModel existingSaleItem,
    required VariantOptionModel varOptModel,
    required List<String> listModifierOptionIds,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
  }) async {
    List<SaleModifierModel> currListSaleModifierModel =
        state.saleModifiers
            .where((element) => element.saleItemId == existingSaleItem.id)
            .toList();

    List<SaleModifierOptionModel> currListSaleModifierOptionModel =
        currListSaleModifierModel
            .expand(
              (saleModifierModel) => state.saleModifierOptions.where(
                (option) => option.saleModifierId == saleModifierModel.id,
              ),
            )
            .toList();

    List<String> prevListModifierOptionIds =
        currListSaleModifierOptionModel
            .map((e) => e.modifierOptionId!)
            .toList();

    final variantJsonStr = existingSaleItem.variantOptionJson;
    final newVOM =
        (variantJsonStr != null)
            ? VariantOptionModel.fromJson(jsonDecode(variantJsonStr))
            : VariantOptionModel();

    final exisitingHashSaleItemIdNeedToCompared = IdUtils.generateHashId(
      existingSaleItem.variantOptionId!,
      prevListModifierOptionIds,
      existingSaleItem.comments!,
      itemModel.id!,
      cost: pricePerItem,
      variantPrice: newVOM.price,
    );

    if (existingSaleItem.id == exisitingHashSaleItemIdNeedToCompared) {
      prints('CASE 7');
      return await _crudHelper.updateFromOrderListHaveVariant(
        state: state,
        updateState: updateState,
        existingSaleItem: existingSaleItem,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        isCustomVariant: isCustomVariant,
        varOptModel: varOptModel,
        pricePerItem: pricePerItem,
        prevListModifierOptionIds: prevListModifierOptionIds,
        currListSaleModifierModel: currListSaleModifierModel,
        existingHashSaleItemIdNeedToCompared:
            exisitingHashSaleItemIdNeedToCompared,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 8');
      return await _crudHelper.updateFromOrderListHaveVariantAndModifier(
        state: state,
        updateState: updateState,
        existingSaleItem: existingSaleItem,
        itemModel: itemModel,
        currListSaleModifierModel: currListSaleModifierModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        isCustomVariant: isCustomVariant,
        varOptModel: varOptModel,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 9 & 10: Custom price item (no default price), no variant, with modifiers
  /// Checks if cost/comment/modifier combination exists
  Future<Map<String, dynamic>> _handleCase9And10({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
  }) async {
    bool isCostCommentModifierExist = state.saleItems.any((si) {
      bool isCostAndCommentSale =
          si.cost == pricePerItem &&
          si.comments == comments &&
          si.id ==
              IdUtils.generateHashId(
                null,
                listModifierOptionIds,
                comments,
                itemModel.id!,
                cost: pricePerItem,
                variantPrice: null,
              );

      return isCostAndCommentSale;
    });

    if (isCostCommentModifierExist) {
      prints('CASE 9');
      return await _crudHelper.updateSaleItemCustomPrice(
        state: state,
        updateState: updateState,
        pricePerItem: pricePerItem,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        itemModel: itemModel,
        taxModels: taxModels,
        qty: qty,
        saleItemPrice: saleItemPrice,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 10');
      return await _crudHelper.insertSaleItemCustomPrice(
        state: state,
        updateState: updateState,
        pricePerItem: pricePerItem,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        itemModel: itemModel,
        taxModels: taxModels,
        qty: qty,
        saleItemPrice: saleItemPrice,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 11 & 12: Custom price item with variant and modifiers
  /// Checks if cost/variant/comment/modifier combination exists
  Future<Map<String, dynamic>> _handleCase11And12({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required VariantOptionModel varOptModel,
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
    required bool isCustomVariant,
  }) async {
    bool isCostVariantCommentModifierExist = state.saleItems.any((si) {
      bool isVariantCostCommentSale =
          si.cost == pricePerItem &&
          si.comments == comments &&
          si.variantOptionId == varOptModel.id &&
          si.id ==
              IdUtils.generateHashId(
                varOptModel.id,
                listModifierOptionIds,
                comments,
                itemModel.id!,
                cost: pricePerItem,
                variantPrice: varOptModel.price,
              );

      return isVariantCostCommentSale;
    });

    if (isCostVariantCommentModifierExist) {
      prints('CASE 11');
      return await _crudHelper.updateSaleItemCustomPriceHaveVariantAndModifier(
        state: state,
        updateState: updateState,
        pricePerItem: pricePerItem,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        itemModel: itemModel,
        taxModels: taxModels,
        qty: qty,
        varOptModel: varOptModel,
        saleItemPrice: saleItemPrice,
        isCustomVariant: isCustomVariant,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 12');
      return await _crudHelper.insertSaleItemCustomPriceHaveVariantAndModifier(
        state: state,
        updateState: updateState,
        pricePerItem: pricePerItem,
        comments: comments,
        listModifierOptionIds: listModifierOptionIds,
        itemModel: itemModel,
        taxModels: taxModels,
        qty: qty,
        varOptModel: varOptModel,
        saleItemPrice: saleItemPrice,
        isCustomVariant: isCustomVariant,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 13 & 14: Custom price item from order list, no variant
  /// Checks if existing sale item ID matches item ID
  Future<Map<String, dynamic>> _handleCase13And14({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required SaleItemModel existingSaleItem,
    required List<String> listModifierOptionIds,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required double pricePerItem,
  }) async {
    if (existingSaleItem.id == itemModel.id) {
      prints('CASE 13');
      return await _crudHelper.fromOrderListCustomPriceNoVariant(
        state: state,
        updateState: updateState,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        pricePerItem: pricePerItem,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 14');
      return await _crudHelper.fromOrderListCustomPriceNoVariantSecondTime(
        state: state,
        updateState: updateState,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        pricePerItem: pricePerItem,
        existingSaleItem: existingSaleItem,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 15 & 16: Custom price item from order list with variant
  /// Compares existing hash ID to determine correct update path
  Future<Map<String, dynamic>> _handleCase15And16({
    required ItemModel itemModel,
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required Function() getMapDataToTransfer,
    required SaleItemModel existingSaleItem,
    required VariantOptionModel varOptModel,
    required List<String> listModifierOptionIds,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
  }) async {
    List<SaleModifierModel> currListSaleModifierModel = [];
    List<SaleModifierOptionModel> currListSaleModifierOptionModel = [];

    currListSaleModifierModel =
        state.saleModifiers
            .where((element) => element.saleItemId == existingSaleItem.id)
            .toList();

    for (SaleModifierModel saleModifierModel in currListSaleModifierModel) {
      List<SaleModifierOptionModel> matchingModifierOptions =
          state.saleModifierOptions
              .where(
                (element) => element.saleModifierId == saleModifierModel.id,
              )
              .toList();

      currListSaleModifierOptionModel.addAll(matchingModifierOptions);
    }

    List<String> prevListModifierOptionIds =
        currListSaleModifierOptionModel
            .map((e) => e.modifierOptionId!)
            .toList();

    dynamic varOptJson = jsonDecode(existingSaleItem.variantOptionJson ?? '{}');
    VariantOptionModel newVOM = VariantOptionModel();
    if (existingSaleItem.variantOptionJson != null) {
      newVOM = VariantOptionModel.fromJson(varOptJson);
    }
    String existingHashSaleItemIdNeedToCompared = IdUtils.generateHashId(
      existingSaleItem.variantOptionId,
      prevListModifierOptionIds,
      existingSaleItem.comments!,
      itemModel.id!,
      cost: existingSaleItem.cost!,
      variantPrice: newVOM.price,
    );

    if (existingSaleItem.id == existingHashSaleItemIdNeedToCompared) {
      prints('CASE 15');
      return await _crudHelper.fromOrderListCustomPriceHaveVariant(
        state: state,
        updateState: updateState,
        existingSaleItem: existingSaleItem,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        isCustomVariant: isCustomVariant,
        varOptModel: varOptModel,
        pricePerItem: pricePerItem,
        prevListModifierOptionIds: prevListModifierOptionIds,
        currListSaleModifierModel: currListSaleModifierModel,
        existingHashSaleItemIdNeedToCompared:
            existingHashSaleItemIdNeedToCompared,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    } else {
      prints('CASE 16');
      return await _crudHelper.fromOrderListCustomPriceHaveVariantAndModifier(
        state: state,
        updateState: updateState,
        existingSaleItem: existingSaleItem,
        itemModel: itemModel,
        saleItemPrice: saleItemPrice,
        listModifierOptionIds: listModifierOptionIds,
        taxModels: taxModels,
        qty: qty,
        comments: comments,
        isCustomVariant: isCustomVariant,
        varOptModel: varOptModel,
        pricePerItem: pricePerItem,
        prevListModifierOptionIds: prevListModifierOptionIds,
        currListSaleModifierModel: currListSaleModifierModel,
        existingHashSaleItemIdNeedToCompared:
            existingHashSaleItemIdNeedToCompared,
        getMapDataToTransfer: getMapDataToTransfer,
      );
    }
  }

  /// CASE 17: Fallback case when no condition matches
  /// Returns current state unchanged
  Map<String, dynamic> _handleCase17(Function() getMapDataToTransfer) {
    prints('CASE 17 ---- NOTHING HAPPENED');
    return getMapDataToTransfer();
  }
}
