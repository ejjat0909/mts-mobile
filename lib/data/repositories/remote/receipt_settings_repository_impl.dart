import 'dart:convert';

import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_list_response_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/domain/repositories/remote/receipt_settings_repository.dart';

/// Implementation of [ReceiptSettingsRepository] for remote data source
class ReceiptSettingsRepositoryImpl implements ReceiptSettingsRepository {
  /// Get list of receipt settings
  @override
  Resource getListReceiptSettings() {
    final OutletModel outletModel = ServiceLocator.get<OutletModel>();
    prints('Outlet model for receipt setting ${outletModel.id}');

    return Resource(
      modelName: ReceiptSettingsModel.modelName,
      url: 'receipt-settings/list',
      parse: (response) {
        return ReceiptSettingsListResponseModel(json.decode(response.body));
      },
    );
  }
}
