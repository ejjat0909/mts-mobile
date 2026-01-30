import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/table_section_repository.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

class TableSectionSyncHandler implements SyncHandler {
  final LocalTableSectionRepository _localRepository;
  final ProviderContainer _container;

  TableSectionSyncHandler({
    LocalTableSectionRepository? localRepository,
    ProviderContainer? container,
  }) : _localRepository =
           localRepository ?? ServiceLocator.get<LocalTableSectionRepository>(),
       _container = container ?? ServiceLocator.get<ProviderContainer>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    TableSectionModel model = TableSectionModel.fromJson(data);
    final notifier = _container.read(tableLayoutProvider.notifier);
    TableSectionModel? currentSection = notifier.currSection;
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );
    notifier.addOrUpdateListSections([model]);
    if (currentSection != null) {
      notifier.setCurrSection(currentSection);
    }

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TableSectionModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    TableSectionModel model = TableSectionModel.fromJson(data);
    final notifier = _container.read(tableLayoutProvider.notifier);
    TableSectionModel? currentSection = notifier.currSection;
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    await _localRepository.upsertBulk(
      [model],
      isInsertToPending: false,
      isQueue: false,
    );
    notifier.addOrUpdateListSections([model]);
    if (currentSection != null) {
      notifier.setCurrSection(currentSection);
    }
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TableSectionModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    TableSectionModel model = TableSectionModel.fromJson(data);
    final notifier = _container.read(tableLayoutProvider.notifier);
    // get current section
    TableSectionModel? currentSection = notifier.currSection;
    List<TableSectionModel> sections = notifier.sections;
    TableSectionModel? firstSection =
        sections.isNotEmpty ? sections.first : null;

    await _localRepository.deleteBulk([model], isInsertToPending: false);
    notifier.deleteBulkSections([model]);
    if (currentSection?.id == model.id) {
      if (firstSection != null) {
        notifier.setCurrSection(firstSection);
      }
    } else {
      if (currentSection != null) {
        notifier.setCurrSection(currentSection);
      }
    }

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(TableSectionModel.modelName, meta);
  }
}
