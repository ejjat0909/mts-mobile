/// Pagination filter request model
class PaginationFilterRequestModel {
  /// Page number
  int? page;

  /// Number of items per page
  int? take;

  /// Constructor
  PaginationFilterRequestModel({this.page = 1, this.take = 100});

  /// Create from JSON
  PaginationFilterRequestModel.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    take = json['take'];
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page'] = page;
    data['take'] = take;
    return data;
  }
}
