import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/core/enum/tax_type_enum.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/domain/repositories/local/sale_item_repository.dart';
import 'package:mts/domain/repositories/remote/sale_item_repository.dart';
// Import the extracted service classes
import 'package:mts/providers/sale_item/services/sale_item_calculation_service.dart';
import 'package:mts/providers/sale_item/services/sale_item_discount_service.dart';
import 'package:mts/providers/sale_item/services/sale_item_tax_service.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_crud_helper.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_calculation_helper.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_modifier_helper.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_case_router.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_split_helper.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_data_transfer_helper.dart';
import 'package:mts/providers/sale_item/helpers/order_option_recalculation_helper.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_sync_helper.dart';
import 'package:mts/providers/sale_item/helpers/sale_item_selection_helper.dart';

// StateNotifier for managing sale items
class SaleItemNotifier extends StateNotifier<SaleItemState> {
  final LocalSaleItemRepository _localRepository;
  final SaleItemRepository _remoteRepository;
  final IWebService _webService;
  final Ref _ref;

  // Business logic services - extracted from this class
  late final SaleItemCalculationService _calculationService;
  late final SaleItemDiscountService _discountService;
  late final SaleItemTaxService _taxService;
  late final SaleItemCrudHelper _crudHelper;
  late final SaleItemCalculationHelper _calculationHelper;
  late final SaleItemCaseRouter _caseRouter;
  late final SaleItemSplitHelper _splitHelper;
  late final SaleItemDataTransferHelper _dataTransferHelper;
  late final OrderOptionRecalculationHelper _recalculationHelper;
  late final SaleItemSyncHelper _syncHelper;
  late final SaleItemSelectionHelper _selectionHelper;
  late final SaleItemModifierHelper _modifierHelper;

  // Lists for modifiers and options - cached to improve performance
  List<SaleItemModel> saleItemListCleared = [];

  // Notifiers accessed via Riverpod (migrated from ServiceLocator)
  late final dynamic _modifierOptionNotifier;
  late final dynamic _itemNotifier;

  SaleItemNotifier({
    required LocalSaleItemRepository localRepository,
    required SaleItemRepository remoteRepository,
    required IWebService webService,
    required Ref ref,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository,
       _webService = webService,
       _ref = ref,
       super(SaleItemState(saleItems: [])) {
    // Initialize services after constructor completes
    _calculationService = SaleItemCalculationService();
    _discountService = SaleItemDiscountService(_ref);
    _taxService = SaleItemTaxService(_ref, _discountService);

    // Initialize CRUD helper with required dependencies
    _calculationHelper = SaleItemCalculationHelper(
      _ref,
      _calculationService,
      _discountService,
      _taxService,
    );
    _modifierHelper = SaleItemModifierHelper();
    _crudHelper = SaleItemCrudHelper(_ref, _calculationHelper, _modifierHelper);
    _caseRouter = SaleItemCaseRouter(_ref, _crudHelper);
    _splitHelper = SaleItemSplitHelper(_ref, _calculationHelper);
    _syncHelper = SaleItemSyncHelper(_remoteRepository, _webService);
    _selectionHelper = SaleItemSelectionHelper();

    // Initialize notifiers
    _modifierOptionNotifier = _ref.read(itemProvider.notifier);
    _itemNotifier = _ref.read(itemProvider.notifier);

    // Initialize new helpers
    _dataTransferHelper = SaleItemDataTransferHelper(
      modifierOptionNotifier: _modifierOptionNotifier,
      itemNotifier: _itemNotifier,
    );
    _recalculationHelper = OrderOptionRecalculationHelper(_ref);
  }

  Future<bool> upsertBulk(
    List<SaleModifierModel> list, {
    bool isInsertToPending = true,
    bool isQueue = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _localRepository.upsertBulk(
        list,
        isInsertToPending: isInsertToPending,
      );

      if (result) {
        final existingItems = List<SaleModifierModel>.from(state.items);
        for (final item in list) {
          final index = existingItems.indexWhere((e) => e.id == item.id);
          if (index >= 0) {
            existingItems[index] = item;
          } else {
            existingItems.add(item);
          }
        }
        state = state.copyWith(items: existingItems, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void addOrUpdateListClearedSaleItem(
    List<SaleItemModel> list,
    SaleModel saleModel,
  ) {
    _crudHelper.addOrUpdateListClearedSaleItem(
      saleItemListCleared,
      list,
      saleModel.id,
    );
  }

  void deleteAllSaleItemsCleared() {
    saleItemListCleared.clear();
  }

  // getter for cleared sale items list
  List<SaleItemModel> get getListSaleItemsCleared => saleItemListCleared;

  // set is split payment
  void setIsSplitPayment(bool value) {
    state = state.copyWith(isSplitPayment: value);
  }

  void setCanBackToSalesPage(bool value) {
    state = state.copyWith(canBackToSalesPage: value);
  }

  // set list sale items
  void setSaleItems(List<SaleItemModel> listItems) {
    // Early return if the list is identical to avoid unnecessary state updates
    if (identical(state.saleItems, listItems)) return;
    state = state.copyWith(saleItems: listItems);
  }

  // set predefined order model
  void setPredefinedOrderModel(PredefinedOrderModel predefinedOrderModel) {
    state = state.copyWith(pom: predefinedOrderModel);
  }

  // set list sale modifiers
  void setSaleModifiers(List<SaleModifierModel> listMod) {
    if (identical(state.saleModifiers, listMod)) return;
    state = state.copyWith(saleModifiers: listMod);
  }

  // set list sale modifier options
  void setSaleModifierOptions(List<SaleModifierOptionModel> listModOpt) {
    state = state.copyWith(saleModifierOptions: listModOpt);
  }

  // set list modifier option from db - merge new options with existing ones
  void addOrUpdateModifierOptionList(List<ModifierOptionModel> listModOpt) {
    _modifierHelper.addOrUpdateModifierOptionList(
      listModOpt,
      state,
      (newState) => state = newState,
    );
  }

  // set list modifiers
  void addOrUpdateModifierList(List<ModifierModel> listMod) {
    _modifierHelper.addOrUpdateModifierList(
      listMod,
      state,
      (newState) => state = newState,
    );
  }

  void setModeEdit(bool isEditMode) {
    state = state.copyWith(isEditMode: isEditMode);
  }

  // set variant option model
  void setVariantOptionModel(VariantOptionModel variantOptionModel) {
    state = state.copyWith(variantOptionModel: variantOptionModel);
  }

  // set order option name
  void setOrderOptionModel(
    OrderOptionModel orderOptionModel, {
    bool reCalculate = true,
  }) {
    state = state.copyWith(orderOptionModel: orderOptionModel);
    // Regenerate all calculation data for existing sale items with new order option taxes

    regenerateCalculationDataForOrderOptionChange(reCalculate);
  }

  // Regenerate calculation data for all sale items when order option changes
  void regenerateCalculationDataForOrderOptionChange(bool reCalculate) {
    _recalculationHelper.regenerateCalculationDataForOrderOptionChange(
      state: state,
      updateState: (newState) => state = newState,
      reCalculate: reCalculate,
      getMapDataToTransfer: getMapDataToTransfer,
      updatedTotalDiscount: updatedTotalDiscount,
      updatedTaxAfterDiscount: updatedTaxAfterDiscount,
      updatedTaxIncludedAfterDiscount: updatedTaxIncludedAfterDiscount,
      updatedTotalAfterDiscountAndTax: updatedTotalAfterDiscountAndTax,
    );
  }

  // set current sale model
  void setCurrSaleModel(SaleModel currSaleModel) {
    state = state.copyWith(currSaleModel: currSaleModel);
  }

  // set selected table
  void setSelectedTable(TableModel selectedTable) {
    state = state.copyWith(selectedTable: selectedTable);
  }

  // clear selected table - explicitly set to empty table
  void clearSelectedTable() {
    final emptyTable = TableModel(
      id: null,
      name: null,
      tableSectionId: null,
      left: null,
      top: null,
      type: null,
      status: null,
      staffId: null,
      customerId: null,
      saleId: null,
      predefinedOrderId: null,
      outletId: null,
      seats: null,
      createdAt: null,
      updatedAt: null,
    );
    state = state.copyWith(selectedTable: emptyTable);
  }

  // set payment type model
  void setPaymentTypeModel(PaymentTypeModel paymentTypeModel) {
    state = state.copyWith(paymentTypeModel: paymentTypeModel);
  }

  void setTotalAmountRemaining(double amount) {
    state = state.copyWith(
      totalAmountPaid: state.totalAmountRemaining,
      totalAmountRemaining: amount,
    );
  }

  void setListCustomVariant(List<Map<String, dynamic>> listCustomVariant) {
    state = state.copyWith(listCustomVariant: listCustomVariant);
  }

  void setListTotalDiscount(List<Map<String, dynamic>> listTotalDiscount) {
    state = state.copyWith(listTotalDiscount: listTotalDiscount);
  }

  void setListTaxAfterDiscount(
    List<Map<String, dynamic>> listTaxAfterDiscount,
  ) {
    state = state.copyWith(listTaxAfterDiscount: listTaxAfterDiscount);
  }

  void setListTaxIncludedAfterDiscount(
    List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
  ) {
    state = state.copyWith(
      listTaxIncludedAfterDiscount: listTaxIncludedAfterDiscount,
    );
  }

  void setListTotalAfterDiscountAndTax(
    List<Map<String, dynamic>> listTotalAfterDiscountAndTax,
  ) {
    state = state.copyWith(
      listTotalAfterDiscountAndTax: listTotalAfterDiscountAndTax,
    );
  }

  void setSelectedModifierOptionList(List<ModifierOptionModel> listModOpt) {
    state = state.copyWith(listSelectedModifierOption: listModOpt);
  }

  // Set adjusted price
  void setAdjustedPrice(double price) {
    state = state.copyWith(adjustedPrice: price);
    calcTotalWithAdjustedPrice();
  }

  void setTotalWithAdjustedPrice(double price) {
    state = state.copyWith(totalWithAdjustedPrice: price);
  }

  // Helper method that sets adjusted price and returns the updated state
  SaleItemState setAdjustedPriceAndGetState(double price) {
    setAdjustedPrice(price);
    return state;
  }

  // Set sales tax
  void setSalesTax(double tax) {
    state = state.copyWith(salesTax: tax);
  }

  // Set sales discount
  void setSalesDiscount(double discount) {
    state = state.copyWith(salesDiscount: discount);
  }

  // set category id
  void setCategoryId(String categoryId) {
    // Explicitly set categoryId to null or a specific value
    // This will override the null-coalescing operator in copyWith
    state = state.copyWith(categoryId: categoryId);
  }

  // set selected category use for add or remove item from page item
  void setSelectedCategory(int index, CategoryModel? category) {
    // Create a new map to ensure immutability
    final newSelectedCategories = Map<int, CategoryModel?>.from(
      state.selectedCategories,
    )..[index] = category;

    state = state.copyWith(
      listCategories: [...state.listCategories, category],
      selectedCategories: newSelectedCategories,
    );
  }

  void clearSelections() {
    _selectionHelper.clearSelections(state, (newState) => state = newState);
  }

  void deselectAll() {
    _selectionHelper.deselectAll(state, (newState) => state = newState);
  }

  void selectAll(List<SaleModel> orders) {
    _selectionHelper.selectAll(orders, state, (newState) => state = newState);
  }

  bool isAllOpenOrderSelected(List<SaleModel> filteredList) {
    return _selectionHelper.isAllOpenOrderSelected(filteredList, state);
  }

  // set selected item use for add or remove item from page item
  void setSelectedItem(int index, ItemModel? item) {
    // Create a new map to ensure immutability
    final newSelectedItems = Map<int, ItemModel?>.from(state.selectedItems)
      ..[index] = item;

    state = state.copyWith(
      listItems: [...state.listItems, item],
      selectedItems: newSelectedItems,
    );
  }

  // For split order
  void removeSaleItemFromNotifier(String saleItemId, DateTime updatedAt) {
    final saleItems = state.saleItems;
    saleItems.removeWhere(
      (element) => element.id == saleItemId && element.updatedAt == updatedAt,
    );

    state = state.copyWith(saleItems: saleItems);
  }

  // for split order
  Future<SaleItemModel?> removeSaleItemAndMoveToSplit(
    SaleItemModel saleItem,
    ItemModel itemModel,
  ) async {
    return _splitHelper.removeSaleItemAndMoveToSplit(
      saleItem: saleItem,
      itemModel: itemModel,
      state: state,
      updateState: (newState) => state = newState,
      getMapDataToTransfer: getMapDataToTransfer,
      deleteSaleModifierModelAndSaleModifierOptionModel:
          deleteSaleModifierModelAndSaleModifierOptionModel,
      removeSaleItemFromNotifier: removeSaleItemFromNotifier,
      reCalculateAllTotal: reCalculateAllTotal,
      calcTotalAfterDiscountAndTax: calcTotalAfterDiscountAndTax,
      calcTaxAfterDiscount: calcTaxAfterDiscount,
      calcTotalDiscount: calcTotalDiscount,
      calcTotalWithAdjustedPrice: calcTotalWithAdjustedPrice,
      calcTaxIncludedAfterDiscount: calcTaxIncludedAfterDiscount,
    );
  }

  // for split order
  Future<void> addItemToOrder(
    SaleItemModel saleItem,
    ItemModel itemModel,
    List<TaxModel> taxModels,
    List<SaleModifierModel> listSM,
    List<SaleModifierOptionModel> listSMO,
  ) async {
    return _splitHelper.addItemToOrder(
      saleItem: saleItem,
      itemModel: itemModel,
      taxModels: taxModels,
      listSM: listSM,
      listSMO: listSMO,
      state: state,
      updateState: (newState) => state = newState,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  void toggleOpenOrderSelection(SaleModel saleModel) {
    _selectionHelper.toggleOpenOrderSelection(
      saleModel,
      state,
      (newState) => state = newState,
    );
  }

  bool get hasSaleItems => state.saleItems.isNotEmpty;

  bool checkSaleItemExist(SaleItemModel saleItem) {
    return state.saleItems.any((item) => item.id == saleItem.id);
  }

  void clearOrderItems() {
    state = state.copyWith(
      saleItems: const [],
      saleModifierOptions: const [],
      saleModifiers: const [],
      listTotalDiscount: const [],
      listTaxAfterDiscount: const [],
      listTaxIncludedAfterDiscount: const [],
      listTotalAfterDiscountAndTax: const [],
      listCustomVariant: const [],
      totalWithAdjustedPrice: 0.0,
    );
    setAdjustedPrice(0);
  }

  // Helper method that clears items and recalculates everything at once
  SaleItemState clearOrderItemsAndRecalculate() {
    clearOrderItems();
    _recalculateAllTotals();
    return state;
  }

  void removeAllSaleItems() {
    clearOrderItems();
    _recalculateAllTotals();
  }

  double getTotalCosts() {
    return _calculationHelper.getTotalCosts(state);
  }

  double getGrossAmountPerSaleItem(SaleItemModel saleItem) {
    return _calculationHelper.getGrossAmountPerSaleItem(saleItem);
  }

  /// Calculate net sales for a specific sale item
  /// Net sales = gross sale per item - discount of that item
  double getNetSalePerSaleItem(SaleItemModel saleItem) {
    return _calculationHelper.getNetSalePerSaleItem(saleItem);
  }

  /// Calculate gross sales for a specific sale item
  /// RM 10 x 5 = 50
  /// RM 15 x 3 = 45
  /// Gross sales = RM 95

  double getNetSales() {
    return _calculationHelper.getNetSales(state);
  }

  double getGrossSales() {
    return _calculationHelper.getGrossSales(state);
  }

  double get subtotal {
    return state.saleItems.fold(0, (total, saleItem) {
      total += saleItem.totalAfterDiscAndTax ?? 0;
      return total;
    });
  }

  // Helper method to recalculate all totals efficiently
  void _recalculateAllTotals() {
    calcTotalDiscount();
    calcTaxAfterDiscount();
    calcTaxIncludedAfterDiscount();
    calcTotalAfterDiscountAndTax();
    calcTotalWithAdjustedPrice();
  }

  void reCalculateAllTotal(String? saleItemId, DateTime? updatedAt) {
    if (saleItemId != null && updatedAt != null) {
      removeDiscountTaxAndTotal(saleItemId, updatedAt);
    }
    _recalculateAllTotals();
  }

  void resetModAndVar() {
    state = state.copyWith(
      listSelectedModifierOption: [],
      variantOptionModel: VariantOptionModel(),
    );
  }

  void deleteSaleModifierModelAndSaleModifierOptionModel(
    String saleItemModelId,
    DateTime updatedAt,
  ) {
    _modifierHelper.deleteSaleModifierModelAndSaleModifierOptionModel(
      saleItemModelId,
      updatedAt,
      state,
      (newState) => state = newState,
    );
  }

  // Calculate total discount using service
  void calcTotalDiscount() {
    final newTotal = _calculationService.calculateTotalDiscount(
      state.listTotalDiscount,
    );
    state = state.copyWith(totalDiscount: newTotal);
  }

  // Calculate tax after discount using service
  void calcTaxAfterDiscount() {
    final total = _calculationService.calculateTaxAfterDiscount(
      state.listTaxAfterDiscount,
    );
    state = state.copyWith(taxAfterDiscount: total);
  }

  void calcTaxIncludedAfterDiscount() {
    final total = _calculationService.calculateTaxIncludedAfterDiscount(
      state.listTaxIncludedAfterDiscount,
    );
    state = state.copyWith(taxIncludedAfterDiscount: total);
  }

  // Calculate total after discount and tax using service
  void calcTotalAfterDiscountAndTax() {
    final total = _calculationService.calculateTotalAfterDiscountAndTax(
      state.listTotalAfterDiscountAndTax,
    );
    state = state.copyWith(totalAfterDiscountAndTax: total);
  }

  // Calculate total with adjusted price using service
  void calcTotalWithAdjustedPrice() {
    prints(
      "NOT SPLIT calcTotalWithAdjustedPrice ${state.totalAfterDiscountAndTax} - ${state.adjustedPrice}",
    );

    final result = _calculationService.calculateTotalWithAdjustedPrice(
      totalAfterDiscountAndTax: state.totalAfterDiscountAndTax,
      adjustedPrice: state.adjustedPrice,
      paymentTypeModel: state.paymentTypeModel,
    );

    state = state.copyWith(
      totalWithAdjustedPrice: result['totalWithAdjustedPrice']!,
    );

    setTotalAmountRemaining(result['totalAmountRemaining']!);
  }

  // Remove discount, tax, and total for a specific sale item
  void removeDiscountTaxAndTotal(String saleItemId, DateTime updatedAt) {
    _calculationHelper.removeDiscountTaxAndTotal(
      saleItemId,
      updatedAt,
      state,
      (newState) => state = newState,
      _recalculateAllTotals,
    );
  }

  // Update sale item with custom price
  Future<Map<String, dynamic>> updateSaleItemCustomPrice({
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
  }) async {
    return await _crudHelper.updateSaleItemCustomPrice(
      state: state,
      updateState: (newState) => state = newState,
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

  // Update sale item with custom price, variant, and modifier
  Future<Map<String, dynamic>> updateSaleItemCustomPriceHaveVariantAndModifier({
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
    required VariantOptionModel varOptModel,
    required bool isCustomVariant,
  }) async {
    return await _crudHelper.updateSaleItemCustomPriceHaveVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
      pricePerItem: pricePerItem,
      comments: comments,
      listModifierOptionIds: listModifierOptionIds,
      itemModel: itemModel,
      taxModels: taxModels,
      qty: qty,
      saleItemPrice: saleItemPrice,
      varOptModel: varOptModel,
      isCustomVariant: isCustomVariant,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Insert a new sale item with custom price
  Future<Map<String, dynamic>> insertSaleItemCustomPrice({
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double saleItemPrice,
    required double qty,
  }) async {
    return await _crudHelper.insertSaleItemCustomPrice(
      state: state,
      updateState: (newState) => state = newState,
      pricePerItem: pricePerItem,
      comments: comments,
      listModifierOptionIds: listModifierOptionIds,
      itemModel: itemModel,
      taxModels: taxModels,
      saleItemPrice: saleItemPrice,
      qty: qty,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Insert a new sale item with custom price, variant, and modifier
  Future<Map<String, dynamic>> insertSaleItemCustomPriceHaveVariantAndModifier({
    required double pricePerItem,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required List<TaxModel> taxModels,
    required double saleItemPrice,
    required double qty,
    required VariantOptionModel varOptModel,
    required bool isCustomVariant,
  }) async {
    return await _crudHelper.insertSaleItemCustomPriceHaveVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
      pricePerItem: pricePerItem,
      comments: comments,
      listModifierOptionIds: listModifierOptionIds,
      itemModel: itemModel,
      taxModels: taxModels,
      saleItemPrice: saleItemPrice,
      qty: qty,
      varOptModel: varOptModel,
      isCustomVariant: isCustomVariant,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Update sale item with no variant and modifier
  Future<Map<String, dynamic>> updateSaleItemNoVariantAndModifier({
    required String incomingSaleItemId,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
  }) async {
    return await _crudHelper.updateSaleItemNoVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
      incomingSaleItemId: incomingSaleItemId,
      itemModel: itemModel,
      saleItemPrice: saleItemPrice,
      taxModels: taxModels,
      qty: qty,
      comments: comments,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Create a new sale item with no variant and modifier
  Future<Map<String, dynamic>> newSaleItemNoVariantAndModifier({
    required ItemModel itemModel,
    required String incomingSaleItemId,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double pricePerItem,
    required double qty,
    required String comments,
  }) async {
    return await _crudHelper.newSaleItemNoVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
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

  // Update sale item from order list with variant and modifier
  Future<Map<String, dynamic>> updateFromOrderListHaveVariantAndModifier({
    required SaleItemModel existingSaleItem,
    required List<SaleModifierModel> currListSaleModifierModel,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required bool isCustomVariant,
    required String comments,
    required VariantOptionModel varOptModel,
  }) async {
    return await _crudHelper.updateFromOrderListHaveVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
      existingSaleItem: existingSaleItem,
      currListSaleModifierModel: currListSaleModifierModel,
      itemModel: itemModel,
      saleItemPrice: saleItemPrice,
      listModifierOptionIds: listModifierOptionIds,
      taxModels: taxModels,
      qty: qty,
      isCustomVariant: isCustomVariant,
      comments: comments,
      varOptModel: varOptModel,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Update item from order list with custom price and no variant
  Future<Map<String, dynamic>> fromOrderListCustomPriceNoVariant({
    required ItemModel itemModel,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
    required String comments,
    required double pricePerItem,
  }) async {
    return await _crudHelper.fromOrderListCustomPriceNoVariant(
      state: state,
      updateState: (newState) => state = newState,
      itemModel: itemModel,
      listModifierOptionIds: listModifierOptionIds,
      taxModels: taxModels,
      qty: qty,
      saleItemPrice: saleItemPrice,
      comments: comments,
      pricePerItem: pricePerItem,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Update item from order list with custom price and no variant (second time)
  Future<Map<String, dynamic>> fromOrderListCustomPriceNoVariantSecondTime({
    required ItemModel itemModel,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required double saleItemPrice,
    required String comments,
    required double pricePerItem,
    required SaleItemModel existingSaleItem,
  }) async {
    return await _crudHelper.fromOrderListCustomPriceNoVariantSecondTime(
      state: state,
      updateState: (newState) => state = newState,
      itemModel: itemModel,
      listModifierOptionIds: listModifierOptionIds,
      taxModels: taxModels,
      qty: qty,
      saleItemPrice: saleItemPrice,
      comments: comments,
      pricePerItem: pricePerItem,
      existingSaleItem: existingSaleItem,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Update item from order list with custom price and variant
  Future<Map<String, dynamic>> fromOrderListCustomPriceHaveVariant({
    required SaleItemModel existingSaleItem,
    required List<String> prevListModifierOptionIds,
    required VariantOptionModel varOptModel,
    required ItemModel itemModel,
    required String comments,
    required double qty,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required List<String> listModifierOptionIds,
    required String existingHashSaleItemIdNeedToCompared,
    required bool isCustomVariant,
    required double pricePerItem,
    required List<SaleModifierModel> currListSaleModifierModel,
  }) async {
    return await _crudHelper.fromOrderListCustomPriceHaveVariant(
      state: state,
      updateState: (newState) => state = newState,
      existingSaleItem: existingSaleItem,
      prevListModifierOptionIds: prevListModifierOptionIds,
      varOptModel: varOptModel,
      itemModel: itemModel,
      comments: comments,
      qty: qty,
      saleItemPrice: saleItemPrice,
      taxModels: taxModels,
      listModifierOptionIds: listModifierOptionIds,
      existingHashSaleItemIdNeedToCompared:
          existingHashSaleItemIdNeedToCompared,
      isCustomVariant: isCustomVariant,
      pricePerItem: pricePerItem,
      currListSaleModifierModel: currListSaleModifierModel,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Update item from order list with custom price, variant, and modifier
  Future<Map<String, dynamic>> fromOrderListCustomPriceHaveVariantAndModifier({
    required SaleItemModel existingSaleItem,
    required List<String> prevListModifierOptionIds,
    required VariantOptionModel varOptModel,
    required ItemModel itemModel,
    required String comments,
    required double qty,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required List<String> listModifierOptionIds,
    required String existingHashSaleItemIdNeedToCompared,
    required bool isCustomVariant,
    required double pricePerItem,
    required List<SaleModifierModel> currListSaleModifierModel,
  }) async {
    return await _crudHelper.fromOrderListCustomPriceHaveVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
      existingSaleItem: existingSaleItem,
      prevListModifierOptionIds: prevListModifierOptionIds,
      varOptModel: varOptModel,
      itemModel: itemModel,
      comments: comments,
      qty: qty,
      saleItemPrice: saleItemPrice,
      taxModels: taxModels,
      listModifierOptionIds: listModifierOptionIds,
      existingHashSaleItemIdNeedToCompared:
          existingHashSaleItemIdNeedToCompared,
      isCustomVariant: isCustomVariant,
      pricePerItem: pricePerItem,
      currListSaleModifierModel: currListSaleModifierModel,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  // Create and update sale items - delegates to SaleItemCaseRouter
  Future<Map<String, dynamic>> createAndUpdateSaleItems(
    ItemModel itemModel, {
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
    return await _caseRouter.createAndUpdateSaleItems(
      itemModel,
      state: state,
      updateState: (newState) => state = newState,
      getMapDataToTransfer: getMapDataToTransfer,
      newSaleItemUuid: newSaleItemUuid,
      existingSaleItem: existingSaleItem,
      saleItemPrice: saleItemPrice,
      comments: comments,
      pricePerItem: pricePerItem,
      isCustomVariant: isCustomVariant,
      varOptModel: varOptModel,
      listModOpt: listModOpt,
      listModifierOptionIds: listModifierOptionIds,
      qty: qty,
    );
  }

  // Update existing sale item with variant and modifiers
  Future<Map<String, dynamic>> updateSaleItemHaveVariantAndModifier({
    required VariantOptionModel varOptModel,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required bool isCustomVariant,
  }) async {
    return await _crudHelper.updateSaleItemHaveVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
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

  Future<Map<String, dynamic>> insertSaleItemHaveVariantAndModifier({
    required VariantOptionModel varOptModel,
    required String comments,
    required List<String> listModifierOptionIds,
    required ItemModel itemModel,
    required double pricePerItem,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required double qty,
    required bool isCustomVariant,
  }) async {
    return await _crudHelper.insertSaleItemHaveVariantAndModifier(
      state: state,
      updateState: (newState) => state = newState,
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

  Future<Map<String, dynamic>> updateFromOrderListNoVariant({
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
  }) async {
    return await _crudHelper.updateFromOrderListNoVariant(
      state: state,
      updateState: (newState) => state = newState,
      itemModel: itemModel,
      saleItemPrice: saleItemPrice,
      listModifierOptionIds: listModifierOptionIds,
      taxModels: taxModels,
      qty: qty,
      comments: comments,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  Future<Map<String, dynamic>> updateFromOrderListExistingNotSameWithItem({
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required double saleItemPrice,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
  }) async {
    return await _crudHelper.updateFromOrderListExistingNotSameWithItem(
      state: state,
      updateState: (newState) => state = newState,
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

  Future<Map<String, dynamic>> updateFromOrderListHaveVariant({
    required SaleItemModel existingSaleItem,
    required ItemModel itemModel,
    required double saleItemPrice,
    required VariantOptionModel varOptModel,
    required List<String> listModifierOptionIds,
    required List<TaxModel> taxModels,
    required double qty,
    required String comments,
    required bool isCustomVariant,
    required String existingHashSaleItemIdNeedToCompared,
    required double pricePerItem,
    required List<String> prevListModifierOptionIds,
    required List<SaleModifierModel> currListSaleModifierModel,
  }) async {
    return await _crudHelper.updateFromOrderListHaveVariant(
      state: state,
      updateState: (newState) => state = newState,
      existingSaleItem: existingSaleItem,
      itemModel: itemModel,
      saleItemPrice: saleItemPrice,
      varOptModel: varOptModel,
      listModifierOptionIds: listModifierOptionIds,
      taxModels: taxModels,
      qty: qty,
      comments: comments,
      isCustomVariant: isCustomVariant,
      existingHashSaleItemIdNeedToCompared:
          existingHashSaleItemIdNeedToCompared,
      pricePerItem: pricePerItem,
      prevListModifierOptionIds: prevListModifierOptionIds,
      currListSaleModifierModel: currListSaleModifierModel,
      getMapDataToTransfer: getMapDataToTransfer,
    );
  }

  /// Generate hash of current state for change detection
  Map<String, dynamic> getMapDataToTransfer() {
    return _dataTransferHelper.getMapDataToTransfer(
      state: state,
      updateState: (newState) => state = newState,
      recalculateAllTotals: _recalculateAllTotals,
    );
  }

  String? getInventoryIdFromItemOrVariantOption({
    ItemModel? itemModel,
    VariantOptionModel? variantOptionModel,
  }) {
    if (itemModel != null && itemModel.inventoryId != null) {
      return itemModel.inventoryId;
    } else if (variantOptionModel != null &&
        variantOptionModel.inventoryId != null) {
      return variantOptionModel.inventoryId;
    }
    return null;
  }

  // New method for getting complete data (for initial load or when full refresh is needed)
  Map<String, dynamic> getCompleteDataToTransfer() {
    return _dataTransferHelper.getCompleteDataToTransfer(
      state: state,
      updateState: (newState) => state = newState,
      recalculateAllTotals: _recalculateAllTotals,
    );
  }

  List<Map<String, dynamic>> getOrderList() {
    return _dataTransferHelper.getOrderList(
      state: state,
      modifierOptionNotifier: _modifierOptionNotifier,
      itemNotifier: _itemNotifier,
    );
  }

  Future<Map<String, dynamic>?> updatedTotalDiscount({
    required SaleItemModel? saleItemExisting,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) async {
    return await _calculationHelper.updatedTotalDiscount(
      state: state,
      updateState: (newState) => state = newState,
      saleItemExisting: saleItemExisting,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: updatedQty,
      saleItemPrice: saleItemPrice,
    );
  }

  Future<Map<String, dynamic>?> updatedTaxIncludedAfterDiscount({
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) async {
    return await _calculationHelper.updatedTaxIncludedAfterDiscount(
      state: state,
      updateState: (newState) => state = newState,
      saleItemExisting: saleItemExisting,
      priceUpdated: priceUpdated,
      taxModels: taxModels,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: updatedQty,
      saleItemPrice: saleItemPrice,
    );
  }

  Future<Map<String, dynamic>?> updatedTaxAfterDiscount({
    required SaleItemModel? saleItemExisting,
    required double priceUpdated,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
    required double saleItemPrice,
  }) async {
    return await _calculationHelper.updatedTaxAfterDiscount(
      state: state,
      updateState: (newState) => state = newState,
      saleItemExisting: saleItemExisting,
      priceUpdated: priceUpdated,
      taxModels: taxModels,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: updatedQty,
      saleItemPrice: saleItemPrice,
    );
  }

  Future<Map<String, dynamic>?> updatedTotalAfterDiscountAndTax({
    required SaleItemModel? saleItemExisting,
    required double saleItemPrice,
    required List<TaxModel> taxModels,
    required DateTime now,
    required ItemModel itemModel,
    required String? newSaleItemId,
    required double updatedQty,
  }) async {
    return await _calculationHelper.updatedTotalAfterDiscountAndTax(
      state: state,
      updateState: (newState) => state = newState,
      saleItemExisting: saleItemExisting,
      saleItemPrice: saleItemPrice,
      taxModels: taxModels,
      now: now,
      itemModel: itemModel,
      newSaleItemId: newSaleItemId,
      updatedQty: updatedQty,
    );
  }

  void updateCustomVariant({
    required SaleItemModel? saleItemExisting,
    required VariantOptionModel varOptModel,
    required DateTime now,
    required bool isCustomVariant,
    required String? newSaleItemId,
  }) {
    _calculationHelper.updateCustomVariant(
      state: state,
      updateState: (newState) => state = newState,
      saleItemExisting: saleItemExisting,
      varOptModel: varOptModel,
      now: now,
      isCustomVariant: isCustomVariant,
      newSaleItemId: newSaleItemId,
    );
  }

  Future<bool> insertBulk(
    List<SaleItemModel> list, {
    bool isInsertToPending = true,
  }) async {
    return await _localRepository.upsertBulk(
      list,
      isInsertToPending: isInsertToPending,
    );
  }

  Future<int> insert(SaleItemModel saleItemModel) async {
    return await _localRepository.insert(saleItemModel, true);
  }

  Future<int> update(SaleItemModel saleItemModel) async {
    return await _localRepository.update(saleItemModel, true);
  }

  Future<int> delete(String id, {bool isInsertToPending = true}) async {
    return await _localRepository.delete(
      id,
      isInsertToPending: isInsertToPending,
    );
  }

  //
  // Future<bool> updateBulk(List<SaleItemModel> saleItemModels) async {
  //   return await _localRepository.updateBulk(saleItemModels, true);
  // }

  Future<bool> deleteSaleItemWhereSaleId(String idSale) async {
    return await _localRepository.deleteSaleItemWhereSaleId(idSale);
  }

  // Calculate discount for a single item using service
  Future<double> discountTotalPerItem(
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    // Validate inputs
    if (updatedQty <= 0) {
      prints('Warning: Invalid quantity $updatedQty for discount calculation');
      return 0.0;
    }

    if (itemPriceOrVariantPrice < 0) {
      prints(
        'Warning: Invalid price $itemPriceOrVariantPrice for discount calculation',
      );
      return 0.0;
    }

    return await _discountService.calculateDiscountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );
  }

  Future<double> getTaxAfterDiscountPerItem(
    double netSaleItem,
    List<TaxModel> taxModels,
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    // Validate inputs
    if (netSaleItem < 0) {
      prints('Warning: Negative net sale item $netSaleItem');
      return 0.0;
    }

    if (taxModels.isEmpty) return 0.0;

    // Calculate discount amount
    double discountAmount = await discountTotalPerItem(
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );

    // Ensure discount is not negative
    if (discountAmount < 0) discountAmount = 0.0;

    // Calculate tax percentage for Added taxes only
    final taxPercent = taxModels.fold<double>(
      0.0,
      (total, tm) =>
          tm.type == TaxTypeEnum.Added ? total + (tm.rate ?? 0.0) : total,
    );

    final perItem = netSaleItem - discountAmount;
    final totalTax = perItem * (taxPercent / 100);

    prints('TOTAL TAX AFTER DISCOUNT: $totalTax');
    return totalTax.isNegative ? 0.0 : totalTax;
  }

  // Calculate tax included after discount for a single item using service
  Future<double> getTaxIncludedAfterDiscountPerItem(
    double netSaleItem,
    List<TaxModel> taxModels,
    ItemModel itemModel, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    return await _taxService.calculateTaxIncludedAfterDiscountPerItem(
      netSaleItem,
      taxModels,
      itemModel,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );
  }

  // Calculate total after discount and tax using service
  Future<double> totalAfterDiscountAndTax(
    double subTotalPrice,
    ItemModel itemModel,
    List<TaxModel> taxModels, {
    required double updatedQty,
    required double itemPriceOrVariantPrice,
  }) async {
    return await _taxService.calculateTotalAfterDiscountAndTax(
      subTotalPrice,
      itemModel,
      taxModels,
      updatedQty: updatedQty,
      itemPriceOrVariantPrice: itemPriceOrVariantPrice,
    );
  }

  Future<List<SaleItemModel>> getListSaleItemByPredefinedOrderId(
    String predefinedOrderId, {
    required bool? isVoided,
    required bool? isPrintedKitchen,
    required List<String> categoryIds,
  }) async {
    return await _localRepository.getListSaleItemByPredefinedOrderId(
      predefinedOrderId,
      isVoided,
      isPrintedKitchen,
      categoryIds,
    );
  }

  Future<SaleItemModel> getSaleItemById(String idSale) async {
    return await _localRepository.getSaleItemById(idSale);
  }

  Future<List<SaleItemModel>> getListSaleItemBySaleId(
    List<String> idSale,
  ) async {
    return await _localRepository.getListSaleItemBySaleIds(idSale);
  }

  Future<List<SaleItemModel>> getListSaleItemBySaleIdWhereIsVoidedTrue(
    List<String> idSale,
  ) async {
    return await _localRepository.getListSaleItemBySaleIdWhereIsVoidedTrue(
      idSale,
    );
  }

  Future<List<SaleItemModel>> syncFromRemote() async {
    return await _syncHelper.syncFromRemote();
  }

  Future<void> updateSaleItemsToClear(
    List<SaleItemModel> listSaleItems,
    SaleModel saleModel,
  ) async {
    final saleItemNotifier = ServiceLocator.get<SaleItemNotifier>();

    for (SaleItemModel si in listSaleItems) {
      if (si.id != null && si.saleId != null && si.saleId == saleModel.id) {
        SaleItemModel updatedSI = si.copyWith(isVoided: true);
        saleItemNotifier.addOrUpdateListClearedSaleItem([updatedSI], saleModel);
      }
    }
  }
}

// Provider for the SaleItemsState
final saleItemProvider = StateNotifierProvider<SaleItemNotifier, SaleItemState>(
  (ref) {
    return SaleItemNotifier(
      localRepository: ServiceLocator.get<LocalSaleItemRepository>(),
      remoteRepository: ServiceLocator.get<SaleItemRepository>(),
      webService: ServiceLocator.get<IWebService>(),
      ref: ref,
    );
  },
);

// ============= SELECTOR PROVIDERS FOR PERFORMANCE =============
// Use these to listen to specific properties instead of the entire state
// This prevents unnecessary rebuilds when only specific data changes

/// Selector: Listen only to saleItems list
final saleItemsListProvider = Provider<List<SaleItemModel>>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.saleItems));
});

/// Selector: Listen only to orderOptionModel
final orderOptionModelProvider = Provider<OrderOptionModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.orderOptionModel));
});

/// Selector: Listen only to selectedTable
final selectedTableProvider = Provider<TableModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.selectedTable));
});

/// Selector: Listen only to currSaleModel
final currSaleModelProvider = Provider<SaleModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.currSaleModel));
});

/// Selector: Listen only to predefined order
final predefinedOrderModelProvider = Provider<PredefinedOrderModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.pom));
});

/// Selector: Listen only to payment type model
final paymentTypeModelProvider = Provider<PaymentTypeModel?>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.paymentTypeModel));
});

/// Selector: Listen only to total price calculations
final totalPriceProvider = Provider<double>((ref) {
  return ref.watch(
    saleItemProvider.select((state) => state.totalAfterDiscountAndTax),
  );
});

/// Selector: Listen only to isSplitPayment flag
final isSplitPaymentProvider = Provider<bool>((ref) {
  return ref.watch(saleItemProvider.select((state) => state.isSplitPayment));
});
