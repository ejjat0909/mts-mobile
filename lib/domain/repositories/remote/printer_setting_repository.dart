import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Printer Setting Repository
abstract class PrinterSettingRepository {
  /// Get printer settings without pagination
  Resource getPrinterSetting();
  
  /// Get printer settings with pagination
  Resource getPrinterSettingWithPagination(String page);
}
