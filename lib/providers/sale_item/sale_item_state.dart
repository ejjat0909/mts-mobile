import 'package:freezed_annotation/freezed_annotation.dart';
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
import 'package:mts/data/models/variant_option/variant_option_model.dart';

part 'sale_item_state.freezed.dart';

@freezed
class SaleItemState with _$SaleItemState {
  factory SaleItemState({
    required List<SaleItemModel> saleItems,
    @Default({}) Set<String> saleItemIds,
    @Default([]) List<SaleModel> selectedOpenOrders,
    @Default([]) List<ModifierOptionModel> listModifierOptionDB,
    @Default([]) List<ModifierModel> listModifiers,
    @Default([]) List<ModifierOptionModel> listSelectedModifierOption,
    @Default([]) List<SaleModifierModel> saleModifiers,
    @Default([]) List<SaleModifierOptionModel> saleModifierOptions,
    @Default([]) List<CategoryModel?> listCategories,
    @Default({}) Map<int, CategoryModel?> selectedCategories,
    @Default([]) List<ItemModel?> listItems,
    @Default({}) Map<int, ItemModel?> selectedItems,
    @Default([]) List<Map<String, dynamic>> orderList,
    @Default([]) List<Map<String, dynamic>> listTotalDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTotalAfterDiscountAndTax,
    @Default([]) List<Map<String, dynamic>> listCustomVariant,
    @Default(0.0) double totalDiscount,
    @Default(0.0) double taxAfterDiscount,
    @Default(0.0) double taxIncludedAfterDiscount,
    @Default(0.0) double totalAfterDiscountAndTax,
    @Default(0.0) double totalWithAdjustedPrice,
    @Default(0.0) double adjustedPrice,
    @Default(0.0) double salesTax,
    @Default(0.0) double salesDiscount,
    @Default(0.0) double totalAmountRemaining,
    @Default(0.0) double totalAmountPaid,
    @Default(0.0) double totalPriceAllSaleItemAfterDiscountAndTax,
    SaleModel? currSaleModel,
    PaymentTypeModel? paymentTypeModel,
    OrderOptionModel? orderOptionModel,
    TableModel? selectedTable,
    VariantOptionModel? variantOptionModel,
    PredefinedOrderModel? pom,
    @Default('') String categoryId,
    @Default(false) bool isEditMode,
    @Default(true) bool canBackToSalesPage,
    @Default(false) bool isSplitPayment,
    String? error,
    @Default(false) bool isLoading,
  }) = _SaleItemState;
}
