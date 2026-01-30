import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';

part 'split_payment_state.freezed.dart';

@freezed
class SplitPaymentState with _$SplitPaymentState {
  const factory SplitPaymentState({
    @Default([]) List<SaleItemModel> saleItems,
    @Default([]) List<SaleModifierModel> saleModifiers,
    @Default([]) List<SaleModifierOptionModel> saleModifierOptions,
    @Default([]) List<Map<String, dynamic>> listTotalDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTotalAfterDiscAndTax,
    @Default(0) double totalDiscount,
    @Default(0) double taxAfterDiscount,
    @Default(0) double taxIncludedAfterDiscount,
    @Default(0) double totalAfterDiscountAndTax,
    @Default(0) double totalWithAdjustedPrice,
    @Default(0) double adjustedPrice,
    String? paymentTypeName,
    PaymentTypeModel? paymentTypeModel,
    @Default(0) double totalAmountRemaining,
    @Default(0.0) double totalAmountPaid,
    SaleModel? currSaleModel,
  }) = _SplitPaymentState;
}
