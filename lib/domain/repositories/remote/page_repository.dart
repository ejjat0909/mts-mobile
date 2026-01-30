import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Page Repository
abstract class PageRepository {
  /// Get list of pages with pagination
  Resource getPageList(String page);
}
