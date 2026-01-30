import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/order_option_tax_repository.dart';

class OrderOptionTaxSyncHandler implements SyncHandler {
  final LocalOrderOptionTaxRepository _localRepository;
  final OrderOptionTaxNotifier _orderOptionTaxNotifier;
  final void Function()? _onOrderOptionChanged;

  /// constructor
  OrderOptionTaxSyncHandler({
    LocalOrderOptionTaxRepository? localRepository,
    OrderOptionTaxNotifier? orderOptionTaxNotifier,
    void Function()? onOrderOptionChanged,
  }) : _localRepository =
           localRepository ??
           ServiceLocator.get<LocalOrderOptionTaxRepository>(),
       _orderOptionTaxNotifier =
           orderOptionTaxNotifier ??
           ServiceLocator.get<OrderOptionTaxNotifier>(),
       _onOrderOptionChanged = onOrderOptionChanged;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    OrderOptionTaxModel model = OrderOptionTaxModel.fromJson(data);
    // Don't insert to pending changes for server data
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    _orderOptionTaxNotifier.addOrUpdateList([model]);

    _onOrderOptionChanged?.call();

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OrderOptionTaxModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    OrderOptionTaxModel model = OrderOptionTaxModel.fromJson(data);
    await _localRepository.upsertBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _orderOptionTaxNotifier.addOrUpdateList([model]);

    _onOrderOptionChanged?.call();

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OrderOptionTaxModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    OrderOptionTaxModel model = OrderOptionTaxModel.fromJson(data);
    await _localRepository.deleteBulk([
      model,
    ], false); // Don't insert to pending changes for server data
    _orderOptionTaxNotifier.remove(model.orderOptionId!, model.taxId!);

    _onOrderOptionChanged?.call();

    // save meta data to save last sync
    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(OrderOptionTaxModel.modelName, meta);
  }
}
