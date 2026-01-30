import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class InventoryModel {
  /// Model name for sync handler registry
  static const String modelName = 'Inventory';
  static const String modelBoxName = 'inventory_box';

  /// Name of the inventory item
  String? name;

  /// Unique identifier for this inventory record
  String? id;

  /// Foreign key reference to the company
  String? companyId;

  /// Current quantity of the item in stock
  double? currentQuantity;

  /// Average cost per unit of the item
  double? averageCost;

  /// Selling price of the item
  double? sellingPrice;

  /// Last purchase cost per unit
  double? lastCost;

  /// User ID of who created this inventory record
  String? createdById;

  /// User ID of who last updated this inventory record
  String? updatedById;

  /// Timestamp when this inventory record was created
  DateTime? createdAt;

  /// Timestamp when this inventory record was last updated
  DateTime? updatedAt;

  /// Foreign key reference to the category
  String? categoryId;

  /// Flag to enable/disable this inventory item
  bool? isEnabled;

  InventoryModel({
    this.name,
    this.id,
    this.companyId,
    this.currentQuantity,
    this.averageCost,
    this.sellingPrice,
    this.lastCost,
    this.createdById,
    this.updatedById,
    this.createdAt,
    this.updatedAt,
    this.categoryId,
    this.isEnabled,
  });

  InventoryModel.fromJson(Map<String, dynamic> json) {
    name = FormatUtils.parseToString(json['name']);
    id = FormatUtils.parseToString(json['id']);
    companyId = FormatUtils.parseToString(json['company_id']);
    currentQuantity = FormatUtils.parseToDouble(json['current_quantity']);
    averageCost = FormatUtils.parseToDouble(json['average_cost']);
    sellingPrice = FormatUtils.parseToDouble(json['selling_price']);
    lastCost = FormatUtils.parseToDouble(json['last_cost']);
    createdById = FormatUtils.parseToString(json['created_by_id']);
    updatedById = FormatUtils.parseToString(json['updated_by_id']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    categoryId = FormatUtils.parseToString(json['category_id']);
    isEnabled = FormatUtils.parseToBool(json['is_enabled']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    data['company_id'] = companyId;
    data['current_quantity'] = currentQuantity;
    data['average_cost'] = averageCost;
    data['selling_price'] = sellingPrice;
    data['last_cost'] = lastCost;
    data['created_by_id'] = createdById;
    data['updated_by_id'] = updatedById;
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    data['category_id'] = categoryId;
    data['is_enabled'] = FormatUtils.boolToInt(isEnabled);
    return data;
  }

  InventoryModel copyWith({
    String? name,
    String? id,
    String? companyId,
    double? currentQuantity,
    double? averageCost,
    double? sellingPrice,
    double? lastCost,
    String? createdById,
    String? updatedById,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    bool? isEnabled,
  }) {
    return InventoryModel(
      name: name ?? this.name,
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      averageCost: averageCost ?? this.averageCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      lastCost: lastCost ?? this.lastCost,
      createdById: createdById ?? this.createdById,
      updatedById: updatedById ?? this.updatedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
