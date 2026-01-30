import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Item Representation Repository
abstract class ItemRepresentationRepository {
  Resource getItemRepresentation();

  /// Get item representation with pagination
  Resource getItemRepresentationWithPagination(String page);
}
