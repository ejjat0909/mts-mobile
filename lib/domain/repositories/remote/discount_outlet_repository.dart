import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';

/// Interface for Discount Outlet Repository
abstract class DiscountOutletRepository {
  /// Get discount outlets without pagination
  Resource getDiscountOutlet();

  /// Get discount outlets with pagination
  Resource getDiscountOutletList(String page);

  Future<int> insert(DiscountOutletModel row);
}
