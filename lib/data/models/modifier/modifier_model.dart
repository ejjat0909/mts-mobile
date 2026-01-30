import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';

class ModifierModel {
  /// Model name for sync handler registry
  static const String modelName = 'Modifier';
  static const String modelBoxName = 'modifier_box';
  String? id;
  String? name;
  List<ModifierOptionModel>? _modifierOptions;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Internal helper to return currently attached options
  List<ModifierOptionModel> _currentModifierOptions() {
    return _modifierOptions ?? [];
  }

  /// Get modifier options synchronously (returns the current value)
  List<ModifierOptionModel>? get modifierOptions {
    return _modifierOptions;
  }

  /// Set modifier options directly (used when options are included in JSON)
  set modifierOptions(List<ModifierOptionModel>? options) {
    _modifierOptions = options;
  }

  ModifierModel({
    this.id,
    this.name,
    List<ModifierOptionModel>? modifierOptions,
    this.createdAt,
    this.updatedAt,
  }) : _modifierOptions = modifierOptions;

  ModifierModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    name = FormatUtils.parseToString(json['name']);
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  ModifierModel.fromJsonReceiptItem(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['modifier_options'] != null) {
      _modifierOptions = <ModifierOptionModel>[];
      json['modifier_options'].forEach((v) {
        _modifierOptions!.add(ModifierOptionModel.fromJson(v));
      });
    }
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  Map<String, dynamic> toJsonForReceiptItem() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (_modifierOptions != null) {
      data['modifier_options'] =
          _modifierOptions!.map((v) => v.toJson()).toList();
    }
    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }
    return data;
  }

  /// Helper method to load modifier options
  /// This is useful when you need to ensure options are loaded before accessing them
  Future<List<ModifierOptionModel>> loadModifierOptions() async {
    // Model no longer fetches data itself; options should be provided
    // by repositories/providers. This method returns currently attached options.
    return _currentModifierOptions();
  }
}
