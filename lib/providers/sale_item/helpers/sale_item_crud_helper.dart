import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_utils.dart';
import '../../../core/utils/log_utils.dart';
import '../../../data/models/item/item_model.dart';
import '../../../data/models/modifier_option/modifier_option_model.dart';
import '../../../data/models/sale_item/sale_item_model.dart';
import '../../../data/models/sale_modifier/sale_modifier_model.dart';
import '../../../data/models/sale_modifier_option/sale_modifier_option_model.dart';
import '../../../data/models/tax/tax_model.dart';
import '../../../data/models/variant_option/variant_option_model.dart';
import '../../../core/enum/item_sold_by_enum.dart';
import '../../tax/tax_providers.dart';
import '../sale_item_state.dart';
import 'sale_item_calculation_helper.dart';
import 'sale_item_modifier_helper.dart';

/// Comprehensive helper for sale item CRUD operations
/// Handles all 17 cases of createAndUpdateSaleItems and related methods
/// Extracted from SaleItemNotifier for better maintainability
class SaleItemCrudHelper {
  final Ref _ref;
  final SaleItemCalculationHelper _calculationHelper;
  final SaleItemModifierHelper _modifierHelper;

  SaleItemCrudHelper(this._ref, this._calculationHelper, this._modifierHelper);

  /// Main orchestrator method - handles all 17 cases
  Future<Map<String, dynamic>> createAndUpdateSaleItems(
    ItemModel itemModel,
    SaleItemState state,
    Function(SaleItemState) updateState,
    Function() getMapDataToTransfer, {
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

    // CASE 1 & 2: Item with price, variant, and modifiers (new)
    if (itemModel.price != null &&
        existingSaleItem == null &&
        varOptModel != null &&
        listModOpt != null) {
      bool isVariantIdCommentModifierExist = state.saleItems.any((element) {
        return element.variantOptionId == varOptModel.id &&
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
      });

      if (isVariantIdCommentModifierExist) {
        prints('CASE 1');
        return await updateSaleItemHaveVariantAndModifier(
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
        return await insertSaleItemHaveVariantAndModifier(
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
    // CASE 3 & 4: Item with price, no variant, no modifiers
    else if (itemModel.price != null &&
        existingSaleItem == null &&
        varOptModel == null &&
        listModOpt == null) {
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
        return updateSaleItemNoVariantAndModifier(
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
        return newSaleItemNoVariantAndModifier(
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
    // CASE 5 & 6: Item from order list without variant
    else if (itemModel.price != null &&
        existingSaleItem != null &&
        varOptModel == null) {
      if (existingSaleItem.id == itemModel.id) {
        prints('CASE 5');
        return updateFromOrderListNoVariant(
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
        return updateFromOrderListExistingNotSameWithItem(
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
    // CASE 7 & 8: Item from order list with variant
    else if (itemModel.price != null &&
        existingSaleItem != null &&
        varOptModel!.id != null) {
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
        return updateFromOrderListHaveVariant(
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
        return updateFromOrderListHaveVariantAndModifier(
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
    // CASE 9 & 10: Custom price, no variant
    else if (existingSaleItem == null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel == null &&
        listModOpt != null) {
      bool isCostCommentModifierExist = state.saleItems.any((si) {
        return si.cost == pricePerItem &&
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
      });

      if (isCostCommentModifierExist) {
        prints('CASE 9');
        return updateSaleItemCustomPrice(
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
        return insertSaleItemCustomPrice(
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
    // CASE 11 & 12: Custom price with variant
    else if (existingSaleItem == null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel != null &&
        listModOpt != null) {
      bool isCostVariantCommentModifierExist = state.saleItems.any((si) {
        return si.cost == pricePerItem &&
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
      });

      if (isCostVariantCommentModifierExist) {
        prints('CASE 11');
        return updateSaleItemCustomPriceHaveVariantAndModifier(
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
        return insertSaleItemCustomPriceHaveVariantAndModifier(
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
    // CASE 13 & 14: Order list custom price, no variant
    else if (existingSaleItem != null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel == null &&
        listModOpt != null) {
      if (existingSaleItem.id == itemModel.id) {
        prints('CASE 13');
        return fromOrderListCustomPriceNoVariant(
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
        return fromOrderListCustomPriceNoVariantSecondTime(
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
    // CASE 15 & 16: Order list custom price with variant
    else if (existingSaleItem != null &&
        itemModel.price == null &&
        (itemModel.soldBy == ItemSoldByEnum.item ||
            itemModel.soldBy == ItemSoldByEnum.measurement) &&
        varOptModel != null &&
        listModOpt != null) {
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

      dynamic varOptJson = jsonDecode(
        existingSaleItem.variantOptionJson ?? '{}',
      );
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
        return fromOrderListCustomPriceHaveVariant(
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
        return fromOrderListCustomPriceHaveVariantAndModifier(
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

    // CASE 17: Nothing matched
    prints('CASE 17 ---- NOTHING HAPPENED');
    return getMapDataToTransfer();
  }

  // Placeholder methods - these need to be implemented with actual logic
  // Each method will follow similar patterns with calculation helper calls

  Future<Map<String, dynamic>> updateSaleItemHaveVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required VariantOptionModel varOptModel,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required bool isCustomVariant,
    required Function() getMapDataToTransfer,
  }) async {
    SaleItemModel saleItemExisting = state.saleItems.firstWhere(
      (element) =>
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
              ),
      orElse: () => SaleItemModel(),
    );

    if (saleItemExisting.id == null) return getMapDataToTransfer();

    DateTime now = DateTime.now();
    final updatedQty = saleItemExisting.quantity! + qty;
    final updatedPrice = saleItemExisting.price! + saleItemPrice;

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: updatedQty,
      saleItemPrice: updatedPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedPrice,
          updateState: updateState,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: updatedPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          updateState: updateState,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      saleItemExisting: saleItemExisting,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: null,
      updateState: updateState,
    );

    saleItemExisting = saleItemExisting.copyWith(
      quantity: updatedQty,
      price: updatedPrice,
      variantOptionId: varOptModel.id,
      variantOptionJson: jsonEncode(varOptModel),
      comments: comments,
      updatedAt: now,
      discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
    );

    int indexSaleItem = state.saleItems.indexWhere(
      (element) =>
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
              ),
    );

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = saleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> insertSaleItemHaveVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required VariantOptionModel varOptModel,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required bool isCustomVariant,
    required Function() getMapDataToTransfer,
  }) async {
    final DateTime now = DateTime.now();
    final String newSaleItemId = IdUtils.generateHashId(
      varOptModel.id,
      listModifierOptionIds,
      comments,
      itemModel.id!,
      cost: pricePerItem,
      variantPrice: varOptModel.price,
    );

    final List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds
            .map(
              (e) => SaleModifierOptionModel(
                id: IdUtils.generateUUID(),
                saleModifierId: IdUtils.generateUUID(),
                modifierOptionId: e,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .toList();

    final Set<String?> addedModifierIds = {};
    final List<SaleModifierModel> newSaleModifiers = [];

    for (final smo in newSaleModifierOptionList) {
      if (!addedModifierIds.contains(smo.saleModifierId)) {
        final relatedModOpt = state.listModifierOptionDB.firstWhere(
          (element) => element.id == smo.modifierOptionId,
          orElse: () => ModifierOptionModel(),
        );
        if (relatedModOpt.modifierId != null) {
          newSaleModifiers.add(
            SaleModifierModel(
              id: smo.saleModifierId,
              modifierId: relatedModOpt.modifierId,
              saleItemId: newSaleItemId,
              createdAt: now,
              updatedAt: now,
            ),
          );
          addedModifierIds.add(smo.saleModifierId);
        }
      }
    }

    final totalDiscountMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: null,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: null,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          updateState: updateState,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      saleItemExisting: null,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: newSaleItemId,
      updateState: updateState,
    );

    final newSaleItemModel = SaleItemModel(
      id: newSaleItemId,
      inventoryId: _getInventoryIdFromItemOrVariantOption(
        itemModel: itemModel,
        variantOptionModel: varOptModel,
      ),
      itemId: itemModel.id,
      soldBy: itemModel.soldBy,
      categoryId: itemModel.categoryId,
      price: saleItemPrice,
      cost: pricePerItem,
      variantOptionId: varOptModel.id,
      variantOptionJson: jsonEncode(varOptModel),
      quantity: qty,
      discountTotal: totalDiscountMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      comments: comments,
      createdAt: now,
      updatedAt: now,
      isVoided: false,
    );

    updateState(
      state.copyWith(
        saleItems: [...state.saleItems, newSaleItemModel],
        saleModifiers: [...state.saleModifiers, ...newSaleModifiers],
        saleModifierOptions: [
          ...state.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateSaleItemNoVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required String incomingSaleItemId,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required Function() getMapDataToTransfer,
  }) async {
    // Find existing sale item
    final index = state.saleItems.indexWhere((e) => e.id == incomingSaleItemId);
    if (index == -1) return getMapDataToTransfer(); // Exit early if not found

    SaleItemModel saleItemExisting = state.saleItems[index];
    final now = DateTime.now();
    final updatedPrice = saleItemExisting.price! + saleItemPrice;
    final updatedQty = saleItemExisting.quantity! + qty;

    // Calculate all values using helper
    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: updatedQty,
      saleItemPrice: updatedPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedPrice,
          updateState: updateState,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: updatedPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          updateState: updateState,
        );

    // Update sale item model
    saleItemExisting = saleItemExisting.copyWith(
      quantity: updatedQty,
      price: updatedPrice,
      comments: comments,
      discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      updatedAt: now,
    );

    final updatedSaleItems = List<SaleItemModel>.from(state.saleItems)
      ..[index] = saleItemExisting;
    updateState(state.copyWith(saleItems: updatedSaleItems));

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> newSaleItemNoVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required ItemModel itemModel,
    required String incomingSaleItemId,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double pricePerItem,
    required double qty,
    required String comments,
    required Function() getMapDataToTransfer,
  }) async {
    final DateTime now = DateTime.now();

    final totalDiscountMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: null,
      now: now,
      itemModel: itemModel,
      newSaleItemId: incomingSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: incomingSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: incomingSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: null,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: incomingSaleItemId,
          updatedQty: qty,
          updateState: updateState,
        );

    final newSaleItemModel = SaleItemModel(
      id: incomingSaleItemId,
      inventoryId: _getInventoryIdFromItemOrVariantOption(
        itemModel: itemModel,
        variantOptionModel: null,
      ),
      itemId: itemModel.id,
      soldBy: itemModel.soldBy,
      categoryId: itemModel.categoryId,
      price: saleItemPrice,
      cost: pricePerItem,
      quantity: qty,
      discountTotal: totalDiscountMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      comments: comments,
      createdAt: now,
      updatedAt: now,
      isVoided: false,
    );

    updateState(
      state.copyWith(saleItems: [...state.saleItems, newSaleItemModel]),
    );
    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateFromOrderListNoVariant({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required Function() getMapDataToTransfer,
  }) async {
    final now = DateTime.now();
    final newSaleItemId = IdUtils.generateUUID();

    SaleItemModel ssaleItemExisting = state.saleItems.firstWhere(
      (e) => e.id == itemModel.id,
      orElse: () => SaleItemModel(),
    );

    final existingSaleItemId = ssaleItemExisting.id;
    final currListSaleModifierModel =
        state.saleModifiers
            .where((e) => e.saleItemId == existingSaleItemId)
            .toList();
    final saleModifierIdsToRemove =
        currListSaleModifierModel.map((e) => e.id!).toSet();

    final updatedSaleModifiers =
        state.saleModifiers
            .where((e) => e.saleItemId != existingSaleItemId)
            .toList();
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

    final newSaleModifierOptionModel =
        listModifierOptionIds
            .map(
              (e) => SaleModifierOptionModel(
                id: IdUtils.generateUUID(),
                saleModifierId: IdUtils.generateUUID(),
                modifierOptionId: e,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .toList();

    final newSaleModifierModel = <SaleModifierModel>[];
    for (var i = 0; i < newSaleModifierOptionModel.length; i++) {
      final relatedModOpt = state.listModifierOptionDB.firstWhere(
        (element) => element.id == listModifierOptionIds[i],
        orElse: () => ModifierOptionModel(),
      );
      if (relatedModOpt.modifierId != null) {
        newSaleModifierModel.add(
          SaleModifierModel(
            id: newSaleModifierOptionModel[i].saleModifierId,
            modifierId: relatedModOpt.modifierId,
            saleItemId: newSaleItemId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: ssaleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: ssaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: ssaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: ssaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          updateState: updateState,
        );

    final indexSaleItem = state.saleItems.indexWhere(
      (e) => e.id == itemModel.id,
    );
    if (indexSaleItem != -1) {
      ssaleItemExisting = ssaleItemExisting.copyWith(
        id: newSaleItemId,
        quantity: qty,
        price: saleItemPrice,
        comments: comments,
        updatedAt: now,
        discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
        taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
        taxIncludedAfterDiscount:
            taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
        totalAfterDiscAndTax:
            totalAfterDiscAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      );

      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = ssaleItemExisting;
      updateState(
        state.copyWith(
          saleItems: updatedSaleItems,
          saleModifiers: [...state.saleModifiers, ...newSaleModifierModel],
          saleModifierOptions: [
            ...state.saleModifierOptions,
            ...newSaleModifierOptionModel,
          ],
        ),
      );
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateFromOrderListExistingNotSameWithItem({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required Function() getMapDataToTransfer,
  }) async {
    // Similar to updateFromOrderListNoVariant but with existingSaleItem parameter
    final now = DateTime.now();
    final newSaleItemId = IdUtils.generateUUID();

    SaleItemModel ssaleItemExisting = state.saleItems.firstWhere(
      (e) =>
          e.id == existingSaleItem.id &&
          e.updatedAt == existingSaleItem.updatedAt,
      orElse: () => SaleItemModel(),
    );

    final existingSaleItemId = ssaleItemExisting.id;
    final currListSaleModifierModel =
        state.saleModifiers
            .where((e) => e.saleItemId == existingSaleItemId)
            .toList();
    final saleModifierIdsToRemove =
        currListSaleModifierModel.map((e) => e.id!).toSet();

    final updatedSaleModifiers =
        state.saleModifiers
            .where((e) => e.saleItemId != existingSaleItemId)
            .toList();
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

    final newSaleModifierOptionModel =
        listModifierOptionIds
            .map(
              (e) => SaleModifierOptionModel(
                id: IdUtils.generateUUID(),
                saleModifierId: IdUtils.generateUUID(),
                modifierOptionId: e,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .toList();

    final newSaleModifierModel = <SaleModifierModel>[];
    for (var i = 0; i < newSaleModifierOptionModel.length; i++) {
      final relatedModOpt = state.listModifierOptionDB.firstWhere(
        (element) => element.id == listModifierOptionIds[i],
        orElse: () => ModifierOptionModel(),
      );
      if (relatedModOpt.modifierId != null) {
        newSaleModifierModel.add(
          SaleModifierModel(
            id: newSaleModifierOptionModel[i].saleModifierId,
            modifierId: relatedModOpt.modifierId,
            saleItemId: newSaleItemId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: ssaleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: ssaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: ssaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: ssaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          updateState: updateState,
        );

    final indexSaleItem = state.saleItems.indexWhere(
      (e) =>
          e.id == existingSaleItem.id &&
          e.updatedAt == existingSaleItem.updatedAt,
    );

    if (indexSaleItem != -1) {
      ssaleItemExisting = ssaleItemExisting.copyWith(
        id: newSaleItemId,
        quantity: qty,
        price: saleItemPrice,
        comments: comments,
        updatedAt: now,
        discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
        taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
        taxIncludedAfterDiscount:
            taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
        totalAfterDiscAndTax:
            totalAfterDiscAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      );

      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = ssaleItemExisting;
      updateState(
        state.copyWith(
          saleItems: updatedSaleItems,
          saleModifiers: [...state.saleModifiers, ...newSaleModifierModel],
          saleModifierOptions: [
            ...state.saleModifierOptions,
            ...newSaleModifierOptionModel,
          ],
        ),
      );
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateFromOrderListHaveVariant({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
    required VariantOptionModel varOptModel,
    required double pricePerItem,
    required List<String> prevListModifierOptionIds,
    required List<SaleModifierModel> currListSaleModifierModel,
    required String existingHashSaleItemIdNeedToCompared,
    required Function() getMapDataToTransfer,
  }) async {
    SaleItemModel vsaleItemExisting = state.saleItems.firstWhere(
      (e) =>
          e.id == existingSaleItem.id &&
          e.updatedAt == existingSaleItem.updatedAt,
      orElse: () => SaleItemModel(),
    );

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: vsaleItemExisting,
      now: vsaleItemExisting.updatedAt!,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: vsaleItemExisting,
          now: vsaleItemExisting.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: vsaleItemExisting,
          now: vsaleItemExisting.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: vsaleItemExisting,
          now: vsaleItemExisting.updatedAt!,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          updateState: updateState,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      saleItemExisting: vsaleItemExisting,
      varOptModel: varOptModel,
      now: vsaleItemExisting.updatedAt!,
      isCustomVariant: isCustomVariant,
      newSaleItemId: null,
      updateState: updateState,
    );

    final indexSaleItem = state.saleItems.indexWhere(
      (e) =>
          e.id == existingSaleItem.id &&
          e.updatedAt == existingSaleItem.updatedAt,
    );

    if (indexSaleItem != -1) {
      vsaleItemExisting = vsaleItemExisting.copyWith(
        quantity: qty,
        price: saleItemPrice,
        variantOptionId: varOptModel.id,
        variantOptionJson: jsonEncode(varOptModel),
        comments: comments,
        discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
        taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
        taxIncludedAfterDiscount:
            taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
        totalAfterDiscAndTax:
            totalAfterDiscountAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      );

      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = vsaleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateFromOrderListHaveVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required List<SaleModifierModel> currListSaleModifierModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
    required VariantOptionModel varOptModel,
    required Function() getMapDataToTransfer,
  }) async {
    SaleItemModel vsaleItemExisting = state.saleItems.firstWhere(
      (e) =>
          e.id == existingSaleItem.id &&
          e.updatedAt == existingSaleItem.updatedAt,
      orElse: () => SaleItemModel(),
    );

    // Delete old modifiers
    final saleModifierIdsToRemove =
        state.saleModifiers
            .where((e) => e.saleItemId == vsaleItemExisting.id)
            .map((e) => e.id!)
            .toList();

    final updatedSaleModifiers =
        state.saleModifiers
            .where((e) => e.saleItemId != vsaleItemExisting.id)
            .toList();
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

    final now = DateTime.now();
    final newSaleModifierOptionModel =
        listModifierOptionIds
            .map(
              (e) => SaleModifierOptionModel(
                id: IdUtils.generateUUID(),
                saleModifierId: IdUtils.generateUUID(),
                modifierOptionId: e,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .toList();

    final newSaleModifierModel = <SaleModifierModel>[];
    for (var i = 0; i < newSaleModifierOptionModel.length; i++) {
      final relatedModOpt = state.listModifierOptionDB.firstWhere(
        (element) => element.id == listModifierOptionIds[i],
        orElse: () => ModifierOptionModel(),
      );
      if (relatedModOpt.modifierId != null) {
        newSaleModifierModel.add(
          SaleModifierModel(
            id: newSaleModifierOptionModel[i].saleModifierId,
            modifierId: relatedModOpt.modifierId,
            saleItemId: vsaleItemExisting.id,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: vsaleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: vsaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: vsaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: vsaleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          updateState: updateState,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      saleItemExisting: vsaleItemExisting,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: null,
      updateState: updateState,
    );

    final indexSaleItem = state.saleItems.indexWhere(
      (e) =>
          e.id == existingSaleItem.id &&
          e.updatedAt == existingSaleItem.updatedAt,
    );

    if (indexSaleItem != -1) {
      vsaleItemExisting = vsaleItemExisting.copyWith(
        quantity: qty,
        price: saleItemPrice,
        variantOptionId: varOptModel.id,
        variantOptionJson: jsonEncode(varOptModel),
        comments: comments,
        updatedAt: now,
        discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
        taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
        taxIncludedAfterDiscount:
            taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
        totalAfterDiscAndTax:
            totalAfterDiscountAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      );

      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = vsaleItemExisting;
      updateState(
        state.copyWith(
          saleItems: updatedSaleItems,
          saleModifiers: [...state.saleModifiers, ...newSaleModifierModel],
          saleModifierOptions: [
            ...state.saleModifierOptions,
            ...newSaleModifierOptionModel,
          ],
        ),
      );
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateSaleItemCustomPrice({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
    required Function() getMapDataToTransfer,
  }) async {
    // Find the saleItem that has same price, comment, and id
    SaleItemModel saleItemExisting = state.saleItems.firstWhere((si) {
      return si.cost == pricePerItem &&
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
    }, orElse: () => SaleItemModel());

    if (saleItemExisting.id == null) return getMapDataToTransfer();

    DateTime now = DateTime.now();
    final updatedQty = saleItemExisting.quantity! + qty;
    final updatedSaleItemPrice = saleItemExisting.price! + saleItemPrice;

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: updatedQty,
      saleItemPrice: updatedSaleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedSaleItemPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedSaleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedSaleItemPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedSaleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: updatedSaleItemPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          updateState: updateState,
        );

    saleItemExisting = saleItemExisting.copyWith(
      cost: pricePerItem,
      comments: comments,
      quantity: updatedQty,
      price: updatedSaleItemPrice,
      discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      updatedAt: now,
    );

    // Find index of the saleItemModel existing
    int indexSaleItem = state.saleItems.indexWhere((element) {
      bool isCostAndCommentSale =
          element.cost == pricePerItem &&
          element.comments == comments &&
          element.id ==
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

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = saleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> insertSaleItemCustomPrice({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
    required Function() getMapDataToTransfer,
  }) async {
    final DateTime now = DateTime.now();
    final String newSaleItemId = IdUtils.generateHashId(
      null,
      listModifierOptionIds,
      comments,
      itemModel.id!,
      cost: pricePerItem,
      variantPrice: null,
    );

    // Create sale modifier options
    final List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds.map((e) {
          return SaleModifierOptionModel(
            id: IdUtils.generateUUID(),
            saleModifierId: IdUtils.generateUUID(),
            modifierOptionId: e,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    // Create sale modifiers
    final Set<String?> addedModifierIds = {};
    final List<SaleModifierModel> newSaleModifiers = [];

    for (final smo in newSaleModifierOptionList) {
      if (!addedModifierIds.contains(smo.saleModifierId)) {
        final ModifierOptionModel relatedModifierOptionModel = state
            .listModifierOptionDB
            .firstWhere(
              (element) => element.id == smo.modifierOptionId,
              orElse: () => ModifierOptionModel(),
            );

        if (relatedModifierOptionModel.modifierId != null) {
          newSaleModifiers.add(
            SaleModifierModel(
              id: smo.saleModifierId,
              modifierId: relatedModifierOptionModel.modifierId,
              saleItemId: newSaleItemId,
              createdAt: now,
              updatedAt: now,
            ),
          );
          addedModifierIds.add(smo.saleModifierId);
        }
      }
    }

    // Calculate values
    final totalDiscountMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: null,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: null,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          updateState: updateState,
        );

    // Create new sale item
    final SaleItemModel newSaleItemModel = SaleItemModel(
      id: newSaleItemId,
      inventoryId: _getInventoryIdFromItemOrVariantOption(
        itemModel: itemModel,
        variantOptionModel: null,
      ),
      itemId: itemModel.id,
      soldBy: itemModel.soldBy,
      categoryId: itemModel.categoryId,
      price: saleItemPrice,
      cost: pricePerItem,
      variantOptionId: null,
      quantity: qty,
      discountTotal: totalDiscountMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      createdAt: now,
      updatedAt: now,
      isVoided: false,
      comments: comments,
    );

    updateState(
      state.copyWith(
        saleItems: [...state.saleItems, newSaleItemModel],
        saleModifiers: [...state.saleModifiers, ...newSaleModifiers],
        saleModifierOptions: [
          ...state.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> updateSaleItemCustomPriceHaveVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double qty,
    required VariantOptionModel varOptModel,
    required double saleItemPrice,
    required bool isCustomVariant,
    required Function() getMapDataToTransfer,
  }) async {
    SaleItemModel saleItemExisting = state.saleItems.firstWhere(
      (si) =>
          si.cost == pricePerItem &&
          si.variantOptionId == varOptModel.id &&
          si.comments == comments &&
          si.id ==
              IdUtils.generateHashId(
                varOptModel.id,
                listModifierOptionIds,
                comments,
                itemModel.id!,
                cost: pricePerItem,
                variantPrice: varOptModel.price,
              ),
      orElse: () => SaleItemModel(),
    );

    if (saleItemExisting.id == null) return getMapDataToTransfer();

    DateTime now = DateTime.now();
    final updatedQty = saleItemExisting.quantity! + qty;
    final updatedSaleItemPrice = saleItemExisting.price! + saleItemPrice;

    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: updatedQty,
      saleItemPrice: updatedSaleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedSaleItemPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedSaleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: updatedSaleItemPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          saleItemPrice: updatedSaleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: updatedSaleItemPrice,
          newSaleItemId: null,
          updatedQty: updatedQty,
          updateState: updateState,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      saleItemExisting: saleItemExisting,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: null,
      updateState: updateState,
    );

    saleItemExisting = saleItemExisting.copyWith(
      cost: pricePerItem,
      comments: comments,
      variantOptionId: varOptModel.id,
      variantOptionJson: jsonEncode(varOptModel),
      quantity: updatedQty,
      price: updatedSaleItemPrice,
      updatedAt: now,
      discountTotal: discountTotalMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
    );

    int indexSaleItem = state.saleItems.indexWhere(
      (element) =>
          element.variantOptionId == varOptModel.id &&
          element.cost == pricePerItem &&
          element.comments == comments &&
          element.id ==
              IdUtils.generateHashId(
                varOptModel.id,
                listModifierOptionIds,
                comments,
                itemModel.id!,
                cost: pricePerItem,
                variantPrice: varOptModel.price,
              ),
    );

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = saleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> insertSaleItemCustomPriceHaveVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double qty,
    required VariantOptionModel varOptModel,
    required double saleItemPrice,
    required bool isCustomVariant,
    required Function() getMapDataToTransfer,
  }) async {
    final DateTime now = DateTime.now();
    final String newSaleItemId = IdUtils.generateHashId(
      varOptModel.id,
      listModifierOptionIds,
      comments,
      itemModel.id!,
      cost: pricePerItem,
      variantPrice: varOptModel.price,
    );

    // Create sale modifier options
    final List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds.map((e) {
          return SaleModifierOptionModel(
            id: IdUtils.generateUUID(),
            saleModifierId: IdUtils.generateUUID(),
            modifierOptionId: e,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    // Create sale modifiers
    final Set<String?> addedModifierIds = {};
    final List<SaleModifierModel> newSaleModifiers = [];

    for (final smo in newSaleModifierOptionList) {
      if (!addedModifierIds.contains(smo.saleModifierId)) {
        final ModifierOptionModel relatedModifierOptionModel = state
            .listModifierOptionDB
            .firstWhere(
              (element) => element.id == smo.modifierOptionId,
              orElse: () => ModifierOptionModel(),
            );

        if (relatedModifierOptionModel.modifierId != null) {
          newSaleModifiers.add(
            SaleModifierModel(
              id: smo.saleModifierId,
              modifierId: relatedModifierOptionModel.modifierId,
              saleItemId: newSaleItemId,
              createdAt: now,
              updatedAt: now,
            ),
          );
          addedModifierIds.add(smo.saleModifierId);
        }
      }
    }

    // Calculate values
    final totalDiscountMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      saleItemExisting: null,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
      updateState: updateState,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          saleItemExisting: null,
          priceUpdated: saleItemPrice,
          taxModels: taxModels,
          now: now,
          itemModel: itemModel,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
          updateState: updateState,
        );

    final totalAfterDiscAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          saleItemExisting: null,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          updateState: updateState,
        );

    // Update custom variant
    _calculationHelper.updateCustomVariant(
      state: state,
      saleItemExisting: null,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: newSaleItemId,
      updateState: updateState,
    );

    // Create new sale item
    final SaleItemModel newSaleItemModel = SaleItemModel(
      id: newSaleItemId,
      inventoryId: _getInventoryIdFromItemOrVariantOption(
        itemModel: itemModel,
        variantOptionModel: varOptModel,
      ),
      itemId: itemModel.id,
      soldBy: itemModel.soldBy,
      categoryId: itemModel.categoryId,
      price: saleItemPrice,
      cost: pricePerItem,
      variantOptionId: varOptModel.id,
      variantOptionJson: jsonEncode(varOptModel),
      quantity: qty,
      discountTotal: totalDiscountMap?['discountTotal'] ?? 0.0,
      taxAfterDiscount: taxAfterDiscountMap?['taxAfterDiscount'] ?? 0.0,
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap?['taxIncludedAfterDiscount'] ?? 0.0,
      totalAfterDiscAndTax:
          totalAfterDiscAndTaxMap?['totalAfterDiscAndTax'] ?? 0.0,
      createdAt: now,
      updatedAt: now,
      isVoided: false,
      comments: comments,
    );

    updateState(
      state.copyWith(
        saleItems: [...state.saleItems, newSaleItemModel],
        saleModifiers: [...state.saleModifiers, ...newSaleModifiers],
        saleModifierOptions: [
          ...state.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> fromOrderListCustomPriceNoVariant({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required double pricePerItem,
    required Function() getMapDataToTransfer,
  }) async {
    // Find existing sale item
    SaleItemModel existingSaleItem = state.saleItems.firstWhere(
      (element) => element.id == itemModel.id,
      orElse: () => SaleItemModel(),
    );

    final saleItemId = existingSaleItem.id;

    // Get related sale modifiers and options
    final currListSaleModifierModel =
        state.saleModifiers
            .where((element) => element.saleItemId == saleItemId)
            .toList();

    final saleModifierIdsToRemove =
        currListSaleModifierModel.map((e) => e.id!).toList();

    // Remove old modifiers and options
    final updatedSaleModifiers =
        state.saleModifiers.where((e) => e.saleItemId != saleItemId).toList();

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

    DateTime now = DateTime.now();
    String newSaleItemId = IdUtils.generateUUID();

    // Create new modifier structures
    List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds.map((e) {
          return SaleModifierOptionModel(
            id: IdUtils.generateUUID(),
            saleModifierId: IdUtils.generateUUID(),
            modifierOptionId: e,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    List<SaleModifierModel> newSaleModifierList =
        newSaleModifierOptionList.asMap().entries.map((e) {
          int index = e.key;
          SaleModifierOptionModel saleModifierOptionModel = e.value;

          ModifierOptionModel relatedModifierOption = state.listModifierOptionDB
              .firstWhere(
                (element) => element.id == listModifierOptionIds[index],
                orElse: () => ModifierOptionModel(),
              );

          return SaleModifierModel(
            id: saleModifierOptionModel.saleModifierId,
            modifierId: relatedModifierOption.modifierId,
            saleItemId: newSaleItemId,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    // Calculate updated values
    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      updateState: updateState,
      saleItemExisting: existingSaleItem,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: existingSaleItem,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: existingSaleItem,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          updateState: updateState,
          saleItemExisting: existingSaleItem,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
        );

    // Find index and update sale item
    int indexSaleItem = state.saleItems.indexWhere(
      (element) =>
          element.id == existingSaleItem.id &&
          element.updatedAt == existingSaleItem.updatedAt,
    );

    existingSaleItem = existingSaleItem.copyWith(
      id: newSaleItemId,
      quantity: qty,
      price: saleItemPrice,
      cost: pricePerItem,
      comments: comments,
      discountTotal:
          discountTotalMap == null ? 0.00 : discountTotalMap['discountTotal'],
      taxAfterDiscount:
          taxAfterDiscountMap == null
              ? 0.00
              : taxAfterDiscountMap['taxAfterDiscount'],
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap == null
              ? 0.00
              : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap == null
              ? 0.00
              : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
      updatedAt: now,
    );

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = existingSaleItem;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    // Add new modifiers and options
    final currentState = state;
    updateState(
      currentState.copyWith(
        saleModifiers: [...currentState.saleModifiers, ...newSaleModifierList],
        saleModifierOptions: [
          ...currentState.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> fromOrderListCustomPriceNoVariantSecondTime({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required double pricePerItem,
    required SaleItemModel existingSaleItem,
    required Function() getMapDataToTransfer,
  }) async {
    // Find the specific existing sale item
    SaleItemModel saleItemExisting = state.saleItems.firstWhere(
      (element) =>
          element.id == existingSaleItem.id &&
          element.updatedAt == existingSaleItem.updatedAt,
      orElse: () => SaleItemModel(),
    );

    // Generate new hash ID with cost parameter
    String newSaleItemId = IdUtils.generateHashId(
      null,
      listModifierOptionIds,
      comments,
      itemModel.id!,
      cost: pricePerItem,
      variantPrice: null,
    );

    // Remove old modifiers
    final saleModifierIdsToRemove =
        state.saleModifiers
            .where((element) => element.saleItemId == saleItemExisting.id)
            .map((e) => e.id!)
            .toList();

    final updatedSaleModifiers =
        state.saleModifiers
            .where((element) => !saleModifierIdsToRemove.contains(element.id))
            .toList();

    updateState(state.copyWith(saleModifiers: updatedSaleModifiers));

    DateTime now = DateTime.now();

    // Create new modifier structures
    List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds.map((e) {
          return SaleModifierOptionModel(
            id: IdUtils.generateUUID(),
            saleModifierId: IdUtils.generateUUID(),
            modifierOptionId: e,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    List<SaleModifierModel> newSaleModifierList =
        newSaleModifierOptionList.asMap().entries.map((e) {
          int index = e.key;
          SaleModifierOptionModel saleModifierOptionModel = e.value;

          ModifierOptionModel relatedModifierOption = state.listModifierOptionDB
              .firstWhere(
                (element) => element.id == listModifierOptionIds[index],
                orElse: () => ModifierOptionModel(),
              );

          return SaleModifierModel(
            id: saleModifierOptionModel.saleModifierId,
            modifierId: relatedModifierOption.modifierId,
            saleItemId: saleItemExisting.id,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    // Calculate updated values
    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      updateState: updateState,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
        );

    // Find index and update sale item
    int indexSaleItem = state.saleItems.indexWhere(
      (element) =>
          element.id == existingSaleItem.id &&
          element.updatedAt == existingSaleItem.updatedAt,
    );

    saleItemExisting = saleItemExisting.copyWith(
      id: newSaleItemId,
      quantity: qty,
      price: saleItemPrice,
      cost: pricePerItem,
      comments: comments,
      discountTotal:
          discountTotalMap == null ? 0.00 : discountTotalMap['discountTotal'],
      taxAfterDiscount:
          taxAfterDiscountMap == null
              ? 0.00
              : taxAfterDiscountMap['taxAfterDiscount'],
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap == null
              ? 0.00
              : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap == null
              ? 0.00
              : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
      updatedAt: now,
    );

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = saleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    // Add new modifiers and options
    final currentState = state;
    updateState(
      currentState.copyWith(
        saleModifiers: [...currentState.saleModifiers, ...newSaleModifierList],
        saleModifierOptions: [
          ...currentState.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> fromOrderListCustomPriceHaveVariant({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
    required VariantOptionModel varOptModel,
    required double pricePerItem,
    required List<String> prevListModifierOptionIds,
    required List<SaleModifierModel> currListSaleModifierModel,
    required String existingHashSaleItemIdNeedToCompared,
    required Function() getMapDataToTransfer,
  }) async {
    // Parse existing variant option JSON
    dynamic varOptJson = jsonDecode(existingSaleItem.variantOptionJson ?? '{}');
    VariantOptionModel newVOM = VariantOptionModel();
    if (existingSaleItem.variantOptionJson != null) {
      newVOM = VariantOptionModel.fromJson(varOptJson);
    }

    // Find existing sale item with matching hash
    SaleItemModel saleItemExisting = state.saleItems.firstWhere(
      (element) =>
          element.updatedAt == existingSaleItem.updatedAt &&
          element.id ==
              IdUtils.generateHashId(
                existingSaleItem.variantOptionId!,
                prevListModifierOptionIds,
                element.comments!,
                itemModel.id!,
                cost: element.cost,
                variantPrice: newVOM.price,
              ),
      orElse: () => SaleItemModel(),
    );

    String newSaleItemId = IdUtils.generateUUID();
    DateTime now = DateTime.now();

    // Remove old modifiers and options
    final currListSaleModifierModel =
        state.saleModifiers
            .where((element) => element.saleItemId == saleItemExisting.id)
            .toList();

    final saleModifierIdsToRemove =
        currListSaleModifierModel.map((e) => e.id!).toList();

    final updatedSaleModifiers =
        state.saleModifiers
            .where((element) => element.saleItemId != saleItemExisting.id)
            .toList();

    final updatedSaleModifierOptions =
        state.saleModifierOptions
            .where(
              (element) =>
                  !saleModifierIdsToRemove.contains(element.saleModifierId),
            )
            .toList();

    updateState(
      state.copyWith(
        saleModifiers: updatedSaleModifiers,
        saleModifierOptions: updatedSaleModifierOptions,
      ),
    );

    // Create new modifier structures
    List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds.map((e) {
          return SaleModifierOptionModel(
            id: IdUtils.generateUUID().toString(),
            saleModifierId: IdUtils.generateUUID().toString(),
            modifierOptionId: e,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    List<SaleModifierModel> newSaleModifierList =
        newSaleModifierOptionList.asMap().entries.map((entry) {
          int index = entry.key;
          SaleModifierOptionModel saleModifierOptionModel = entry.value;

          ModifierOptionModel relatedModifierOption = state.listModifierOptionDB
              .firstWhere(
                (element) => element.id == listModifierOptionIds[index],
                orElse: () => ModifierOptionModel(),
              );

          return SaleModifierModel(
            id: saleModifierOptionModel.saleModifierId,
            modifierId: relatedModifierOption.modifierId,
            saleItemId: newSaleItemId,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    // Calculate updated values
    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      updateState: updateState,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: newSaleItemId,
          updatedQty: qty,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      updateState: updateState,
      saleItemExisting: saleItemExisting,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: newSaleItemId,
    );

    // Find index and update sale item
    int indexSaleItem = state.saleItems.indexWhere(
      (element) =>
          element.id == existingHashSaleItemIdNeedToCompared &&
          element.updatedAt == saleItemExisting.updatedAt,
    );

    saleItemExisting = saleItemExisting.copyWith(
      id: newSaleItemId,
      quantity: qty,
      price: saleItemPrice,
      cost: pricePerItem,
      variantOptionId: varOptModel.id,
      variantOptionJson: jsonEncode(varOptModel),
      comments: comments,
      discountTotal:
          discountTotalMap == null ? 0.00 : discountTotalMap['discountTotal'],
      taxAfterDiscount:
          taxAfterDiscountMap == null
              ? 0.00
              : taxAfterDiscountMap['taxAfterDiscount'],
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap == null
              ? 0.00
              : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap == null
              ? 0.00
              : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
      updatedAt: now,
    );

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = saleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    // Add new modifiers and options
    final currentState = state;
    updateState(
      currentState.copyWith(
        saleModifiers: [...currentState.saleModifiers, ...newSaleModifierList],
        saleModifierOptions: [
          ...currentState.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  Future<Map<String, dynamic>> fromOrderListCustomPriceHaveVariantAndModifier({
    required SaleItemState state,
    required Function(SaleItemState) updateState,
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
    required VariantOptionModel varOptModel,
    required double pricePerItem,
    required List<String> prevListModifierOptionIds,
    required List<SaleModifierModel> currListSaleModifierModel,
    required String existingHashSaleItemIdNeedToCompared,
    required Function() getMapDataToTransfer,
  }) async {
    // Find existing sale item
    SaleItemModel saleItemExisting = state.saleItems.firstWhere(
      (element) =>
          element.id == existingSaleItem.id &&
          element.updatedAt == existingSaleItem.updatedAt,
      orElse: () => SaleItemModel(),
    );

    // Remove old modifiers and options
    final currListSaleModifierModel =
        state.saleModifiers
            .where((element) => element.saleItemId == saleItemExisting.id)
            .toList();

    final saleModifierIdsToRemove =
        currListSaleModifierModel.map((e) => e.id!).toList();

    final updatedSaleModifiers =
        state.saleModifiers
            .where((element) => element.saleItemId != saleItemExisting.id)
            .toList();

    final updatedSaleModifierOptions =
        state.saleModifierOptions
            .where(
              (element) =>
                  !saleModifierIdsToRemove.contains(element.saleModifierId),
            )
            .toList();

    updateState(
      state.copyWith(
        saleModifiers: updatedSaleModifiers,
        saleModifierOptions: updatedSaleModifierOptions,
      ),
    );

    DateTime now = DateTime.now();

    // Create new modifier structures
    List<SaleModifierOptionModel> newSaleModifierOptionList =
        listModifierOptionIds.map((e) {
          return SaleModifierOptionModel(
            id: IdUtils.generateUUID().toString(),
            saleModifierId: IdUtils.generateUUID().toString(),
            modifierOptionId: e,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    List<SaleModifierModel> newSaleModifierList =
        newSaleModifierOptionList.asMap().entries.map((entry) {
          int index = entry.key;
          SaleModifierOptionModel saleModifierOptionModel = entry.value;

          ModifierOptionModel relatedModifierOptionModel = state
              .listModifierOptionDB
              .firstWhere(
                (element) => element.id == listModifierOptionIds[index],
                orElse: () => ModifierOptionModel(),
              );

          return SaleModifierModel(
            id: saleModifierOptionModel.saleModifierId,
            modifierId: relatedModifierOptionModel.modifierId,
            saleItemId: saleItemExisting.id,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

    // Calculate updated values (no sale item ID change for this case)
    final discountTotalMap = await _calculationHelper.updatedTotalDiscount(
      state: state,
      updateState: updateState,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: null,
      updatedQty: qty,
      saleItemPrice: saleItemPrice,
    );

    final taxAfterDiscountMap = await _calculationHelper
        .updatedTaxAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final taxIncludedAfterDiscountMap = await _calculationHelper
        .updatedTaxIncludedAfterDiscount(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          priceUpdated: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
          saleItemPrice: saleItemPrice,
        );

    final totalAfterDiscountAndTaxMap = await _calculationHelper
        .updatedTotalAfterDiscountAndTax(
          state: state,
          updateState: updateState,
          saleItemExisting: saleItemExisting,
          now: now,
          itemModel: itemModel,
          taxModels: taxModels,
          saleItemPrice: saleItemPrice,
          newSaleItemId: null,
          updatedQty: qty,
        );

    _calculationHelper.updateCustomVariant(
      state: state,
      updateState: updateState,
      saleItemExisting: saleItemExisting,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: null,
    );

    // Find index and update sale item
    int indexSaleItem = state.saleItems.indexWhere(
      (element) =>
          element.id == existingSaleItem.id &&
          element.updatedAt == existingSaleItem.updatedAt,
    );

    saleItemExisting = saleItemExisting.copyWith(
      quantity: qty,
      price: saleItemPrice,
      cost: pricePerItem,
      variantOptionId: varOptModel.id,
      variantOptionJson: jsonEncode(varOptModel),
      comments: comments,
      discountTotal:
          discountTotalMap == null ? 0.00 : discountTotalMap['discountTotal'],
      taxAfterDiscount:
          taxAfterDiscountMap == null
              ? 0.00
              : taxAfterDiscountMap['taxAfterDiscount'],
      taxIncludedAfterDiscount:
          taxIncludedAfterDiscountMap == null
              ? 0.00
              : taxIncludedAfterDiscountMap['taxIncludedAfterDiscount'],
      totalAfterDiscAndTax:
          totalAfterDiscountAndTaxMap == null
              ? 0.00
              : totalAfterDiscountAndTaxMap['totalAfterDiscAndTax'],
      updatedAt: now,
    );

    if (indexSaleItem != -1) {
      final updatedSaleItems = List<SaleItemModel>.from(state.saleItems);
      updatedSaleItems[indexSaleItem] = saleItemExisting;
      updateState(state.copyWith(saleItems: updatedSaleItems));
    }

    // Add new modifiers and options
    final currentState = state;
    updateState(
      currentState.copyWith(
        saleModifiers: [...currentState.saleModifiers, ...newSaleModifierList],
        saleModifierOptions: [
          ...currentState.saleModifierOptions,
          ...newSaleModifierOptionList,
        ],
      ),
    );

    return getMapDataToTransfer();
  }

  /// Adds or updates cleared sale items in a list
  /// Uses Map for O(1) lookups instead of O(n) indexWhere
  void addOrUpdateListClearedSaleItem(
    List<SaleItemModel> saleItemListCleared,
    List<SaleItemModel> list,
    String? saleId,
  ) {
    if (saleId == null || list.isEmpty) {
      // Early return if no sale id or empty list
      return;
    }

    // Use Map for O(1) lookups instead of O(n) indexWhere
    final Map<String, int> idToIndexMap = {
      for (int i = 0; i < saleItemListCleared.length; i++)
        if (saleItemListCleared[i].id != null) saleItemListCleared[i].id!: i,
    };

    for (final saleItem in list) {
      if (saleItem.id == null) continue;

      final index = idToIndexMap[saleItem.id];
      if (index != null) {
        saleItemListCleared[index] = saleItem;
      } else {
        saleItemListCleared.add(saleItem);
      }
    }
  }

  /// Private helper to get inventory ID from item or variant option
  String? _getInventoryIdFromItemOrVariantOption({
    required ItemModel itemModel,
    required VariantOptionModel? variantOptionModel,
  }) {
    if (variantOptionModel != null && variantOptionModel.id != null) {
      return variantOptionModel.inventoryId;
    }
    return itemModel.inventoryId;
  }
}
