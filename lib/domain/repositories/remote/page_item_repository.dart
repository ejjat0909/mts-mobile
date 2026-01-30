import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Page Item Repository
abstract class PageItemRepository {
  /// Get list of page items with pagination
  Resource getPageItemList(String page);
}
