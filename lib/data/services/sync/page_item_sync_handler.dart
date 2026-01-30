import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/page_item_repository.dart';
import 'package:mts/providers/page_item_notifier.dart';

/// Sync handler for PageItem model
class PageItemSyncHandler implements SyncHandler {
  final LocalPageItemRepository _localRepository;
  final PageItemNotifier _pageItemNotifier;

  /// Constructor with dependency injection
  PageItemSyncHandler({
    LocalPageItemRepository? localRepository,
    PageItemNotifier? pageItemNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalPageItemRepository>(),
       _pageItemNotifier =
           pageItemNotifier ?? ServiceLocator.get<PageItemNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PageItemModel model = PageItemModel.fromJson(data);
    // Fix page itemable type format
    for (PageItemModel pageItem in [model]) {
      // Convert from App\\Models\\Item to App/Models/Item for local storage
      if (pageItem.pageItemableType != null &&
          pageItem.pageItemableType!.contains('\\')) {
        pageItem.pageItemableType = pageItem.pageItemableType!.replaceAll(
          '\\',
          '/',
        );
      }
    }

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // _pageItemNotifier.addOrUpdateListPageItem([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PageItemModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PageItemModel model = PageItemModel.fromJson(data);
    // Fix page itemable type format
    for (PageItemModel pageItem in [model]) {
      // Convert from App\\Models\\Item to App/Models/Item for local storage
      if (pageItem.pageItemableType != null &&
          pageItem.pageItemableType!.contains('\\')) {
        pageItem.pageItemableType = pageItem.pageItemableType!.replaceAll(
          '\\',
          '/',
        );
      }
    }

    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // _pageItemNotifier.addOrUpdateListPageItem([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PageItemModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PageItemModel model = PageItemModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    await _pageItemNotifier.removePageItem(pageItemModel: model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PageItemModel.modelName, meta);
  }
}
