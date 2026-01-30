import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';

/// Interface for Discount Item Repository
abstract class DiscountItemRepository {
  /// Get discount items without pagination
  Resource getDiscountItem();

  /// Get discount items with pagination
  Resource getDiscountItemList(String page);

  Future<int> insert(DiscountItemModel row);
}
