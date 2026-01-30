import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/repositories/local/local_customer_repository_impl.dart';
import 'package:mts/data/services/sync_service.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/domain/repositories/local/customer_repository.dart';

/// Provider for CustomerSyncHandler
final customerSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return CustomerSyncHandler(
    localRepository: ref.read(customerLocalRepoProvider),
  );
});

/// Sync handler for Customer model
class CustomerSyncHandler implements SyncHandler {
  final LocalCustomerRepository _localRepository;

  /// Constructor with dependency injection
  CustomerSyncHandler({required LocalCustomerRepository localRepository})
    : _localRepository = localRepository;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    CustomerModel model = CustomerModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // _customerNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CustomerModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    CustomerModel model = CustomerModel.fromJson(data);
    await _localRepository.upsertBulk([model], isInsertToPending: false);
    // _customerNotifier.addOrUpdate(model);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CustomerModel.modelName, meta);
  }

  @override
  Future<void> handleDeleted(Map<String, dynamic> data) async {
    CustomerModel model = CustomerModel.fromJson(data);
    await _localRepository.deleteBulk([model], isInsertToPending: false);

    // _customerNotifier.remove(model.id!);

    MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
    await SyncService.saveMetaData(CustomerModel.modelName, meta);
  }
}
