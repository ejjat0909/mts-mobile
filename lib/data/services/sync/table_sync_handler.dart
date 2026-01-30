import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/table_repository.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

/// Sync handler for SecondDisplay model
class TableSyncHandler implements SyncHandler {
  final LocalTableRepository _localRepository;
  final ProviderContainer _container;

  /// Constructor with dependency injection
  TableSyncHandler({
    LocalTableRepository? localRepository,
    ProviderContainer? container,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalTableRepository>(),
       _container = container ?? ServiceLocator.get<ProviderContainer>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    TableModel model = TableModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );
    _container.read(tableLayoutProvider.notifier).addOrUpdateListTable([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TableModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    TableModel model = TableModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );
    _container.read(tableLayoutProvider.notifier).addOrUpdateListTable([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TableModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    TableModel model = TableModel.fromJson(data);

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    _container.read(tableLayoutProvider.notifier).deleteBulkTable([model]);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TableModel.modelName, meta);
  }
}
