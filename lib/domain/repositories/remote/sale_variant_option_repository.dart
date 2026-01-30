import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Sale Variant Option Repository
abstract class SaleVariantOptionRepository {
  /// Get list of sale variant options
  Resource getSaleVariantOptionList();
}
