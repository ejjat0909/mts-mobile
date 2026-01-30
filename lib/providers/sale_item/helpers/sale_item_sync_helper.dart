import '../../../core/network/web_service.dart';
import '../../../core/utils/log_utils.dart';
import '../../../data/models/sale_item/sale_item_list_response_model.dart';
import '../../../data/models/sale_item/sale_item_model.dart';
import '../../../domain/repositories/remote/sale_item_repository.dart';

/// Helper class for sale item synchronization operations
/// Extracted from SaleItemNotifier to improve maintainability
class SaleItemSyncHelper {
  final SaleItemRepository _remoteRepository;
  final IWebService _webService;

  SaleItemSyncHelper(this._remoteRepository, this._webService);

  /// Synchronizes sale items from remote API with pagination support
  /// Returns a list of all sale items fetched from all pages
  Future<List<SaleItemModel>> syncFromRemote() async {
    List<SaleItemModel> allSaleItems = [];
    int currentPage = 1;
    int? lastPage;

    do {
      // Fetch current page
      prints('Fetching sale items page $currentPage');
      SaleItemListResponseModel responseModel = await _webService.get(
        _remoteRepository.getListSaleItemsWithPagination(
          currentPage.toString(),
        ),
      );

      if (responseModel.isSuccess && responseModel.data != null) {
        // Process items from current page
        List<SaleItemModel> pageSaleItems = responseModel.data!;

        // Add items from current page to the list
        allSaleItems.addAll(pageSaleItems);

        // Get pagination info
        if (responseModel.paginator != null) {
          lastPage = responseModel.paginator!.lastPage;
          prints(
            'Pagination SALE ITEM: current page=$currentPage, last page=$lastPage, total items=${responseModel.paginator!.total}',
          );
        } else {
          // If no paginator info, assume we're done
          break;
        }

        // Move to next page
        currentPage++;
      } else {
        // If request failed, stop pagination
        prints(
          'Failed to fetch sale items page $currentPage: ${responseModel.message}',
        );
        break;
      }
    } while (lastPage != null && currentPage <= lastPage);

    prints(
      'Fetched a total of ${allSaleItems.length} sale items from all pages',
    );
    return allSaleItems;
  }
}
