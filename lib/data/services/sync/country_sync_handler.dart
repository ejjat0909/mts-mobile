// import 'package:mts/app/di/service_locator.dart';
// import 'package:mts/bloc/sync/base_sync_bloc.dart';
// import 'package:mts/data/models/country/country_model.dart';
// import 'package:mts/data/models/meta_model.dart';
// import 'package:mts/data/services/sync/sync_handler.dart';
// import 'package:mts/domain/repositories/local/country_repository.dart';
// import 'package:mts/domain/repositories/remote/sync_repository.dart';
// import 'package:mts/providers/country_notifier.dart';

// /// Sync handler for Country model
// class CountrySyncHandler implements SyncHandler {
//   final LocalCountryRepository _localRepository;
//   final CountryNotifier _countryNotifier;

//   /// Constructor with dependency injection
//   CountrySyncHandler({
//     SyncRepository? syncRepository,
//     LocalCountryRepository? localRepository,
//     CountryNotifier? countryNotifier,
//   }) : _localRepository =
//            localRepository ?? ServiceLocator.get<LocalCountryRepository>(),
//        _countryNotifier =
//            countryNotifier ?? ServiceLocator.get<CountryNotifier>();

//   @override
//   Future<void> handleCreated(Map<String, dynamic> data) async {
//     CountryModel model = CountryModel.fromJson(data);
//     // Insert or update the country in the local database
//     await _localRepository.refreshBulkHiveBox([
//       model,
//     ], isInsertToPending: false);
//     // Update the notifier to refresh UI
//     _countryNotifier.addOrUpdate(model);

//     MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
//     await BaseSyncBloc.saveMetaData(CountryModel.modelName, meta);
//   }

//   @override
//   Future<void> handleUpdated(Map<String, dynamic> data) async {
//     CountryModel model = CountryModel.fromJson(data);
//     // Insert or update the country in the local database
//     await _localRepository.refreshBulkHiveBox([
//       model,
//     ], isInsertToPending: false);
//     // Update the notifier to refresh UI
//     _countryNotifier.addOrUpdate(model);

//     MetaModel meta = MetaModel(lastSync: (model.updatedAt?.toUtc()));
//     await BaseSyncBloc.saveMetaData(CountryModel.modelName, meta);
//   }

//   @override
//   Future<void> handleDeleted(Map<String, dynamic> data) async {
//     CountryModel country = CountryModel.fromJson(data);
//     // Delete the country from the local database
//     await _localRepository.deleteBulk([country], false);
//     // Update the notifier to refresh UI
//     _countryNotifier.remove(country.id!);

//     MetaModel meta = MetaModel(lastSync: (country.updatedAt?.toUtc()));
//     await BaseSyncBloc.saveMetaData(CountryModel.modelName, meta);
//   }
// }
