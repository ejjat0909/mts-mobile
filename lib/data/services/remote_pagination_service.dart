import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';

/// Generic service for handling paginated API requests
///
/// This service eliminates code duplication across 50+ remote repositories
/// by providing a single, reusable pagination implementation.
///
/// Type Parameters:
/// - [T]: The model type (e.g., CashManagementModel, CustomerModel)
/// - [R]: The response model type (e.g., CashManagementListResponseModel)
///
/// The response model [R] must have:
/// - `bool isSuccess` - indicates if request succeeded
/// - `List<T>? data` - the list of items from current page
/// - `Paginator? paginator` - pagination metadata (with lastPage)
/// - `String? message` - error message if request failed
class RemotePaginationService {
  final IWebService _webService;

  RemotePaginationService({required IWebService webService})
    : _webService = webService;

  /// Fetch all items from all pages of a paginated API endpoint
  ///
  /// Parameters:
  /// - [getPagedResource]: Function that creates a Resource for a specific page number
  /// - [extractData]: Function to extract List<T> from response model
  /// - [extractPaginator]: Function to extract paginator from response model
  /// - [extractMessage]: Function to extract error message from response model
  /// - [checkSuccess]: Function to check if response was successful
  /// - [entityName]: Display name for logging (e.g., 'cash managements', 'customers')
  ///
  /// Returns:
  /// - List of all items from all pages (empty list if fetch fails)
  ///
  /// Example:
  /// ```dart
  /// final items = await _paginationService.fetchAllPaginated<CashManagementModel, CashManagementListResponseModel>(
  ///   getPagedResource: (page) => getCashManagementListPaginated(page),
  ///   extractData: (response) => response.data,
  ///   extractPaginator: (response) => response.paginator,
  ///   extractMessage: (response) => response.message,
  ///   checkSuccess: (response) => response.isSuccess,
  ///   entityName: 'cash managements',
  /// );
  /// ```
  Future<List<T>> fetchAllPaginated<T, R>({
    required Resource Function(String page) getPagedResource,
    required List<T>? Function(R response) extractData,
    required dynamic Function(R response) extractPaginator,
    required String? Function(R response) extractMessage,
    required bool Function(R response) checkSuccess,
    required String entityName,
  }) async {
    try {
      List<T> allItems = [];
      int currentPage = 1;
      int? lastPage;

      do {
        prints('Fetching $entityName page $currentPage');

        // Fetch current page
        R responseModel = await _webService.get(
          getPagedResource(currentPage.toString()),
        );

        if (checkSuccess(responseModel)) {
          final data = extractData(responseModel);

          if (data != null) {
            // Add items from current page
            allItems.addAll(data);

            // Get pagination info
            final paginator = extractPaginator(responseModel);
            if (paginator != null && paginator.lastPage != null) {
              lastPage = paginator.lastPage as int?;
              prints(
                'Pagination: page=$currentPage/$lastPage, items=${data.length}, total=${paginator.total ?? 'unknown'}',
              );
            } else {
              // No paginator = single page response
              break;
            }

            currentPage++;
          } else {
            // No data in response
            break;
          }
        } else {
          // Request failed, stop pagination
          prints(
            'Failed to fetch $entityName page $currentPage: ${extractMessage(responseModel)}',
          );
          break;
        }
      } while (lastPage != null && currentPage <= lastPage);

      prints('Fetched total ${allItems.length} $entityName from all pages');
      return allItems;
    } catch (e) {
      await LogUtils.error('Error in fetchAllPaginated for $entityName', e);
      return [];
    }
  }
}
