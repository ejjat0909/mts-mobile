import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Deleted Repository
abstract class DeletedRepository {
  /// Get list of deleted records without pagination
  Resource getDeletedList();

  /// Get list of deleted records with pagination
  Resource getDeletedListPaginated(String page);
}
