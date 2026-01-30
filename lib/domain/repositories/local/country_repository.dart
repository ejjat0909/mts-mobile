import 'package:mts/data/models/country/country_model.dart';

abstract class LocalCountryRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single country record
  Future<int> insert(
    CountryModel countryModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing country record
  Future<int> update(
    CountryModel countryModel, {
    required bool isInsertToPending,
  });

  /// Deletes a country record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple country records at once
  Future<bool> upsertBulk(
    List<CountryModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple country records at once
  Future<bool> deleteBulk(
    List<CountryModel> listCountry, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<CountryModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all country records
  Future<List<CountryModel>> getListCountryModel();

  /// Retrieves a country by ID
  Future<CountryModel?> getCountryModelById(String countryId);

  // ==================== Delete Operations ====================

  /// Deletes all country records
  Future<bool> deleteAll();
}
