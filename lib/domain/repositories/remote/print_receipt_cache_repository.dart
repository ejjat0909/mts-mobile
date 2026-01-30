import 'package:mts/data/datasources/remote/resource.dart';

abstract class PrintReceiptCacheRepository {
  Resource getPrintReceiptCacheList();

  Resource getPrintReceiptCacheListPaginated(String page);
}
