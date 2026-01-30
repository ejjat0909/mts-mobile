import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class InventoryOutletModel {
  // Static model name for use in pending changes
  static const String modelName = 'InventoryOutlet';
  static const String modelBoxName = 'inventory_outlets_box';

  // Properties
  String? id;
  String? outletId;
  String? inventoryId;
  double? currentQuantity;
  double? lowStockThreshold;
  DateTime? lowStockNotifiedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? isEnabled;

  // Constructor
  InventoryOutletModel({
    this.id,
    this.outletId,
    this.inventoryId,
    this.currentQuantity,
    this.lowStockThreshold,
    this.lowStockNotifiedAt,
    this.createdAt,
    this.updatedAt,
    this.isEnabled,
  });

  // Factory constructor from JSON
  InventoryOutletModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    inventoryId = FormatUtils.parseToString(json['inventory_id']);
    currentQuantity = FormatUtils.parseToDouble(json['current_quantity']);
    lowStockThreshold = FormatUtils.parseToDouble(json['low_stock_threshold']);
    lowStockNotifiedAt =
        json['low_stock_notified_at'] != null
            ? DateTime.parse(json['low_stock_notified_at'])
            : null;
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    isEnabled = FormatUtils.parseToBool(json['is_enabled']);
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['outlet_id'] = outletId;
    data['inventory_id'] = inventoryId;
    data['current_quantity'] = currentQuantity;
    data['low_stock_threshold'] = lowStockThreshold;

    if (lowStockNotifiedAt != null) {
      data['low_stock_notified_at'] = DateTimeUtils.getDateTimeFormat(
        lowStockNotifiedAt,
      );
    }
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    data['is_enabled'] = FormatUtils.boolToInt(isEnabled);

    return data;
  }

  // Copy with method for immutability
  InventoryOutletModel copyWith({
    String? id,
    String? outletId,
    String? inventoryId,
    double? currentQuantity,
    double? lowStockThreshold,
    DateTime? lowStockNotifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEnabled,
  }) {
    return InventoryOutletModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      inventoryId: inventoryId ?? this.inventoryId,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      lowStockNotifiedAt: lowStockNotifiedAt ?? this.lowStockNotifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
