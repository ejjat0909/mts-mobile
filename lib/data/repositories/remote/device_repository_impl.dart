import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/pos_device/pos_device_list_response_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/domain/repositories/remote/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  /// Get list of devices
  @override
  Resource getDeviceList() {
    return Resource(
      modelName: PosDeviceModel.modelName,
      url: 'pos-devices/list',
      parse: (response) {
        return PosDeviceListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of devices with pagination
  @override
  Resource getDeviceListWithPagination(String page) {
    return Resource(
      modelName: PosDeviceModel.modelName,
      url: 'pos-devices/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return PosDeviceListResponseModel(json.decode(response.body));
      },
    );
  }
}
