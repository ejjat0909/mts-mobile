import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';

/// Interface for Remote Cash Management Repository
abstract class RemoteCashManagementRepository {
  /// Get list of cash management records
  ///
  /// This method returns a Resource object that can be used to fetch
  /// cash management records from the API.

  /// Get list of cash management records with pagination
  ///
  /// This method returns a Resource object that can be used to fetch
  /// cash management records from the API with pagination.
  ///
  /// @param page The page number to fetch
  Resource getCashManagementListPaginated(String page);

  /// Fetch all cash management records from all pages
  ///
  /// This method handles pagination internally and returns all records.
  /// Pagination logic belongs in the repository layer (Clean Architecture).
  ///
  /// Returns:
  /// - List of all cash management records from all pages
  /// - Empty list if fetch fails or no data exists
  Future<List<CashManagementModel>> fetchAllPaginated();
}
