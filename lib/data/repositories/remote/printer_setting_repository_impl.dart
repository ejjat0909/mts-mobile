import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_list_response_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/domain/repositories/remote/printer_setting_repository.dart';

class PrinterSettingRepositoryImpl implements PrinterSettingRepository {
  /// Get list of printer settings without pagination
  @override
  Resource getPrinterSetting() {
    OutletModel outletModel = GetIt.instance<OutletModel>();
    return Resource(
      modelName: PrinterSettingModel.modelName,
      url: 'printer-settings/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return PrinterSettingListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of printer settings with pagination
  @override
  Resource getPrinterSettingWithPagination(String page) {
    return Resource(
      modelName: PrinterSettingModel.modelName,
      url: 'printer-settings/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return PrinterSettingListResponseModel(json.decode(response.body));
      },
    );
  }
}
