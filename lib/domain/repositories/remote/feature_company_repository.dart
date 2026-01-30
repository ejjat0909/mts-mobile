import 'package:mts/data/datasources/remote/resource.dart';

/// Repository interface for remote feature company operations
abstract class RemoteFeatureCompanyRepository {
  /// Get list of feature companies
  Resource getFeatureCompanyList();
}
