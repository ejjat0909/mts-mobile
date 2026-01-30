import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Item Repository
abstract class ItemRepository {
  Resource getItemList(String page);
}
