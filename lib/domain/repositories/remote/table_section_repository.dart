import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Table Section Repository
abstract class TableSectionRepository {
  

  
  /// Get list of table sections from API with pagination
  Resource getTableSectionList(String page);
}
