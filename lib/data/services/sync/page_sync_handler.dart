import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/page_repository.dart';
import 'package:mts/providers/page_item_notifier.dart';

class PageSyncHandler implements SyncHandler {
  final LocalPageRepository _localRepository;
  final PageItemNotifier _pageItemNotifier;

  PageSyncHandler({
    LocalPageRepository? localRepository,
    PageItemNotifier? pageItemNotifier,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalPageRepository>(),
       _pageItemNotifier =
           pageItemNotifier ?? ServiceLocator.get<PageItemNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PageModel model = PageModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PageModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PageModel model = PageModel.fromJson(data);

    await _localRepository.upsertBulk([model], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PageModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    PageModel model = PageModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    await _pageItemNotifier.removePage(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(PageModel.modelName, meta);
  }
}
