import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class InventoryTransactionModel {
  /// Model name for sync handler registry
  static const String modelName = 'InventoryTransaction';
  static const String modelBoxName = 'inventory_transaction_box';

  String? id;
  String? inventoryId;
  String? companyId;
  String? outletId;
  int? type; // other, in, out
  String? reason;
  // quantity sebelum by default 0
  double? quantity;
  // yang tambah atau tolak positif number shj
  double? countedQuantity;
  // just the difference tambah atau tolak
  double? differenceQuantity;
  double? unitCost;
  double? totalCost;
  String? supplierId;
  String? performedById;
  DateTime? performedAt;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  // quantity after changes
  double? stockAfter;
  String? name;

  InventoryTransactionModel({
    this.id,
    this.inventoryId,
    this.companyId,
    this.outletId,
    this.type,
    this.reason,
    this.quantity,
    this.countedQuantity,
    this.differenceQuantity,
    this.unitCost,
    this.totalCost,
    this.supplierId,
    this.performedById,
    this.performedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.stockAfter,
    this.name,
  });

  InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    inventoryId = FormatUtils.parseToString(json['inventory_id']);
    companyId = FormatUtils.parseToString(json['company_id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    type = FormatUtils.parseToInt(json['type']);
    reason = FormatUtils.parseToString(json['reason']);
    quantity = FormatUtils.parseToDouble(json['quantity']);
    countedQuantity = FormatUtils.parseToDouble(json['counted_quantity']);
    differenceQuantity = FormatUtils.parseToDouble(json['difference_quantity']);
    unitCost = FormatUtils.parseToDouble(json['unit_cost']);
    totalCost = FormatUtils.parseToDouble(json['total_cost']);
    supplierId = FormatUtils.parseToString(json['supplier_id']);
    performedById = FormatUtils.parseToString(json['performed_by_id']);
    performedAt =
        json['performed_at'] != null
            ? DateTime.parse(json['performed_at'])
            : null;
    notes = FormatUtils.parseToString(json['notes']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    stockAfter = FormatUtils.parseToDouble(json['stock_after']);
    name = FormatUtils.parseToString(json['name']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['inventory_id'] = inventoryId;
    data['company_id'] = companyId;
    data['outlet_id'] = outletId;
    data['type'] = type;
    data['reason'] = reason;
    data['quantity'] = quantity;
    data['counted_quantity'] = countedQuantity;
    data['difference_quantity'] = differenceQuantity;
    data['unit_cost'] = unitCost;
    data['total_cost'] = totalCost;
    data['supplier_id'] = supplierId;
    data['performed_by_id'] = performedById;

    if (performedAt != null) {
      data['performed_at'] = DateTimeUtils.getDateTimeFormat(performedAt);
    }

    data['notes'] = notes;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    data['stock_after'] = stockAfter;
    data['name'] = name;

    return data;
  }

  InventoryTransactionModel copyWith({
    String? id,
    String? inventoryId,
    String? companyId,
    String? outletId,
    int? type,
    String? reason,
    double? quantity,
    double? countedQuantity,
    double? differenceQuantity,
    double? unitCost,
    double? totalCost,
    String? supplierId,
    String? performedById,
    DateTime? performedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? stockAfter,
    String? name,
  }) {
    return InventoryTransactionModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      companyId: companyId ?? this.companyId,
      outletId: outletId ?? this.outletId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      differenceQuantity: differenceQuantity ?? this.differenceQuantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      supplierId: supplierId ?? this.supplierId,
      performedById: performedById ?? this.performedById,
      performedAt: performedAt ?? this.performedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stockAfter: stockAfter ?? this.stockAfter,
      name: name ?? this.name,
    );
  }
}
