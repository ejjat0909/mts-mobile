import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Device Repository
abstract class DeviceRepository {
  /// Get list of devices
  Resource getDeviceList();
  
  /// Get list of devices with pagination
  Resource getDeviceListWithPagination(String page);
}
