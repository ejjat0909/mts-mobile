/// Base model class for all models
abstract class Model<T> {
  /// Created at timestamp
  DateTime? createdAt;

  /// Updated at timestamp
  DateTime? updatedAt;

  /// Constructor
  Model({this.createdAt, this.updatedAt});

  /// Convert model to JSON
  Map<String, dynamic> toJson();

  /// Create model from JSON
  T fromJson(Map<String, Object?> json);
}
