import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Table Repository
abstract class TableRepository {

  /// Get list of tables from API with pagination
  Resource getTableList(String page);
}
