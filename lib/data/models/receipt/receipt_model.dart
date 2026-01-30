import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';

class ReceiptModel {
  /// Model name for sync handler registry
  static const String modelName = 'Receipt';
  static const String modelBoxName = 'receipt_box';
  String? id;
  String? showUUID;
  String? outletId;
  String? shiftId;
  String? staffId; // charged by
  String? staffName;
  String? orderedByStaffId; // use staff id
  String? orderedByStaffName;
  String? customerId;
  String? customerName;
  double? cash;
  String? refundedReceiptId;
  String? paymentType;
  String? orderOption;
  String? orderOptionId;

  /// [1 = normal, 2 = refunded, 3 = cancelled]
  int? receiptStatus;
  double? totalDiscount;
  int? taxPercentage;
  double? payableAmount;
  double? cost;
  double? grossSale;
  double? netSale;
  double? totalCollected;
  double? grossProfit;
  String? posDeviceName;
  String? posDeviceId;
  String? openOrderName;
  double? adjustedPrice;
  double? totalTaxes;
  double? totalIncludedTaxes;
  double? totalCashRounding;
  String? remarks;
  String? runningNumber;
  bool? isChangePaymentType;
  // table name not included in local db
  String? tableName;

  DateTime? createdAt;
  DateTime? updatedAt;

  // not included in local db
  List<ReceiptItemModel>? receiptItems;

  ReceiptModel({
    this.id,
    this.showUUID,
    this.outletId,
    this.shiftId,
    this.staffId,
    this.staffName,
    this.orderedByStaffId,
    this.orderedByStaffName,
    this.customerId,
    this.customerName,
    this.cash,
    this.remarks,
    this.posDeviceName,
    this.posDeviceId,
    this.refundedReceiptId,
    this.paymentType,
    this.orderOption,
    this.orderOptionId,
    this.openOrderName,
    this.adjustedPrice,
    this.totalTaxes,
    this.totalIncludedTaxes,
    this.totalCashRounding,
    this.receiptStatus,
    this.totalDiscount,
    this.taxPercentage,
    this.runningNumber,
    this.payableAmount,
    this.cost,
    this.grossSale,
    this.netSale,
    this.totalCollected,
    this.grossProfit,
    this.createdAt,
    this.updatedAt,
    this.isChangePaymentType,
    this.tableName,
  });

  ReceiptModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    showUUID = FormatUtils.parseToString(json['show_uuid']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    shiftId = FormatUtils.parseToString(json['shift_id']);
    staffId = FormatUtils.parseToString(json['staff_id']);
    staffName = FormatUtils.parseToString(json['staff_name']);
    orderedByStaffId = FormatUtils.parseToString(json['ordered_by_staff_id']);
    orderedByStaffName = FormatUtils.parseToString(
      json['ordered_by_staff_name'],
    );
    customerId = FormatUtils.parseToString(json['customer_id']);
    customerName = FormatUtils.parseToString(json['customer_name']);
    cash = FormatUtils.parseToDouble(json['cash']);
    tableName = FormatUtils.parseToString(json['table_name']);
    remarks = FormatUtils.parseToString(json['remarks']);
    posDeviceName = FormatUtils.parseToString(json['pos_device_name']);
    posDeviceId = FormatUtils.parseToString(json['pos_device_id']);
    adjustedPrice = FormatUtils.parseToDouble(json['adjusted_price']);
    totalCashRounding = FormatUtils.parseToDouble(json['total_cash_rounding']);
    totalTaxes = FormatUtils.parseToDouble(json['total_taxes']);
    totalIncludedTaxes = FormatUtils.parseToDouble(
      json['total_included_taxes'],
    );
    refundedReceiptId = FormatUtils.parseToString(json['refunded_receipt_id']);
    paymentType = FormatUtils.parseToString(json['payment_type']);
    orderOption = FormatUtils.parseToString(json['order_option']);
    orderOptionId = FormatUtils.parseToString(json['order_option_id']);
    openOrderName = FormatUtils.parseToString(json['open_order_name']);
    receiptStatus = FormatUtils.parseToInt(json['receipt_status']);

    totalDiscount = FormatUtils.parseToDouble(json['total_discount']);

    taxPercentage = FormatUtils.parseToInt(json['tax_percentage']);

    runningNumber = FormatUtils.parseToString(json['running_number']);
    payableAmount = FormatUtils.parseToDouble(json['payable_amount']);
    cost = FormatUtils.parseToDouble(json['cost']);
    grossSale = FormatUtils.parseToDouble(json['gross_sale']);
    netSale = FormatUtils.parseToDouble(json['net_sale']);
    totalCollected = FormatUtils.parseToDouble(json['total_collected']);
    grossProfit = FormatUtils.parseToDouble(json['gross_profit']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    isChangePaymentType = FormatUtils.parseToBool(
      json['is_change_payment_type'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['show_uuid'] = showUUID;
    data['outlet_id'] = outletId;
    data['shift_id'] = shiftId;
    data['ordered_by_staff_id'] = orderedByStaffId;
    data['ordered_by_staff_name'] = orderedByStaffName;
    data['staff_id'] = staffId;
    data['staff_name'] = staffName;
    data['customer_id'] = customerId;
    data['customer_name'] = customerName;
    data['cash'] = cash;
    data['remarks'] = remarks;
    data['table_name'] = tableName;
    data['pos_device_name'] = posDeviceName;
    data['pos_device_id'] = posDeviceId;
    data['adjusted_price'] = adjustedPrice;
    data['total_taxes'] = totalTaxes;
    data['total_included_taxes'] = totalIncludedTaxes;
    data['total_cash_rounding'] = totalCashRounding;
    data['refunded_receipt_id'] = refundedReceiptId;
    data['payment_type'] = paymentType;
    data['order_option'] = orderOption;
    data['order_option_id'] = orderOptionId;
    data['open_order_name'] = openOrderName;
    data['receipt_status'] = receiptStatus;
    data['total_discount'] = totalDiscount;
    data['tax_percentage'] = taxPercentage;
    data['running_number'] = runningNumber;
    data['payable_amount'] = payableAmount;
    data['cost'] = cost;
    data['gross_sale'] = grossSale;
    data['gross_profit'] = grossProfit;
    data['net_sale'] = netSale;
    data['total_collected'] = totalCollected;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    data['is_change_payment_type'] = FormatUtils.boolToInt(isChangePaymentType);
    return data;
  }

  // List<ReceiptItemModel> getReceiptItemsList() {
  //   return receiptItems ?? [];
  // }

  // void setReceiptItems(List<ReceiptItemModel> list) {
  //   receiptItems = list;
  // }

  // copy with
  ReceiptModel copyWith({
    String? id,
    String? showUUID,
    String? outletId,
    String? shiftId,
    String? orderedByStaffId,
    String? staffId,
    String? staffName,
    String? tableName,
    String? orderedByStaffName,
    String? customerId,
    String? customerName,
    double? cash,
    String? remarks,
    String? posDeviceName,
    String? posDeviceId,
    String? refundedReceiptId,
    String? paymentType,
    String? orderOption,
    String? orderOptionId,
    String? openOrderName,
    double? adjustedPrice,
    double? totalTaxes,
    double? totalIncludedTaxes,
    double? totalCashRounding,
    String? runningNumber,
    int? receiptStatus,
    double? totalDiscount,
    int? taxPercentage,
    double? payableAmount,
    double? cost,
    double? grossSale,
    double? grossProfit,
    double? netSale,
    double? totalCollected,
    DateTime? createdAt,
    DateTime? updatedAt,

    bool? isChangePaymentType,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      showUUID: showUUID ?? this.showUUID,
      outletId: outletId ?? this.outletId,
      shiftId: shiftId ?? this.shiftId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      orderedByStaffName: orderedByStaffName ?? this.orderedByStaffName,
      orderedByStaffId: orderedByStaffId ?? this.orderedByStaffId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      cash: cash ?? this.cash,
      remarks: remarks ?? this.remarks,
      tableName: tableName ?? this.tableName,
      posDeviceName: posDeviceName ?? this.posDeviceName,
      posDeviceId: posDeviceId ?? this.posDeviceId,
      refundedReceiptId: refundedReceiptId ?? this.refundedReceiptId,
      paymentType: paymentType ?? this.paymentType,
      orderOption: orderOption ?? this.orderOption,
      orderOptionId: orderOptionId ?? this.orderOptionId,
      openOrderName: openOrderName ?? this.openOrderName,
      runningNumber: runningNumber ?? this.runningNumber,
      adjustedPrice: adjustedPrice ?? this.adjustedPrice,
      totalTaxes: totalTaxes ?? this.totalTaxes,
      totalIncludedTaxes: totalIncludedTaxes ?? this.totalIncludedTaxes,
      totalCashRounding: totalCashRounding ?? this.totalCashRounding,
      receiptStatus: receiptStatus ?? this.receiptStatus,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      payableAmount: payableAmount ?? this.payableAmount,
      cost: cost ?? this.cost,
      grossSale: grossSale ?? this.grossSale,
      grossProfit: grossProfit ?? this.grossProfit,
      netSale: netSale ?? this.netSale,
      totalCollected: totalCollected ?? this.totalCollected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isChangePaymentType: isChangePaymentType ?? this.isChangePaymentType,
    );
  }
}
