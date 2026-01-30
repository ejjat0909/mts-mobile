/// Paginator model for API responses
class PaginatorModel {
  /// Total pages
  final int? total;

  /// Current page
  final int? count;

  /// Next page
  final int? lastPage;

  /// Previous page
  final int? perPage;

  /// Constructor
  PaginatorModel({this.total, this.count, this.lastPage, this.perPage});

  /// From json
  factory PaginatorModel.fromJson(Map<String, dynamic> json) {
    return PaginatorModel(
      total: json['total'],
      count: json['count'],
      lastPage: json['lastPage'],
      perPage: json['perPage'],
    );
  }

  /// To json
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['count'] = count;
    data['lastPage'] = lastPage;
    data['perPage'] = perPage;
    return data;
  }
}
