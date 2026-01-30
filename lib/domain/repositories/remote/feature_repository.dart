import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Feature Repository
abstract class RemoteFeatureRepository {
  /// Get the API endpoint for retrieving the list of features
  Resource getFeatureList();
}