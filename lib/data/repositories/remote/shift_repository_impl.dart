import 'dart:convert';

import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/shift/shift_list_response_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/domain/repositories/remote/shift_repository.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  @override
  Resource getShiftList() {
    final OutletModel outletModel = ServiceLocator.get<OutletModel>();
    return Resource(
      modelName: ShiftModel.modelName,
      url: 'shifts/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return ShiftListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getShiftListWithPagination(String page) {
    final OutletModel outletModel = ServiceLocator.get<OutletModel>();
    return Resource(
      modelName: ShiftModel.modelName,
      url: 'shifts/list',
      params: {'outlet': outletModel.id, 'page': page, 'take': '20'},
      parse: (response) {
        return ShiftListResponseModel(json.decode(response.body));
      },
    );
  }
}
