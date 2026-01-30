import 'package:mts/data/models/city/city_model.dart';

abstract class LocalCityRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single city record
  Future<int> insert(CityModel cityModel, {required bool isInsertToPending});

  /// Updates an existing city record
  Future<int> update(CityModel cityModel, {required bool isInsertToPending});

  /// Deletes a city record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple city records at once
  Future<bool> upsertBulk(
    List<CityModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple city records at once
  Future<bool> deleteBulk(
    List<CityModel> listCity, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<CityModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all city records
  Future<List<CityModel>> getListCityModel();

  /// Retrieves a city by ID
  Future<CityModel?> getCityModelById(String cityId);

  // ==================== Delete Operations ====================

  /// Deletes all city records
  Future<bool> deleteAll();
}
