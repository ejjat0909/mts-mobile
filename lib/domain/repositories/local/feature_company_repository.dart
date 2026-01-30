import 'package:mts/data/models/feature/feature_company_model.dart';

abstract class LocalFeatureCompanyRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single feature company record
  Future<int> insert(FeatureCompanyModel featureCompanyModel);

  /// Updates an existing feature company record
  Future<int> update(FeatureCompanyModel featureCompanyModel);

  /// Deletes a feature company record by ID
  Future<int> delete(String id);

  // ==================== Bulk Operations ====================

  /// Inserts multiple feature company records at once
  Future<bool> upsertBulk(
    List<FeatureCompanyModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple feature company records at once
  Future<bool> deleteBulk(List<FeatureCompanyModel> listFeatureCompanies);

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<FeatureCompanyModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all feature company records
  Future<List<FeatureCompanyModel>> getListFeatureCompanies();

  // ==================== Delete Operations ====================

  /// Deletes all feature company records
  Future<bool> deleteAll();
}
