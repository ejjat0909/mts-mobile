import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/time_card/timecard_list_response_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/domain/repositories/remote/timecard_repository.dart';

class TimecardRepositoryImpl implements TimecardRepository {
  @override
  Resource getTimecardList() {
    return Resource(
      modelName: TimecardModel.modelName,
      url: 'timecards/list',
      parse: (response) {
        return TimeCardListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getTimecardListPaginated(String page) {
    return Resource(
      modelName: TimecardModel.modelName,
      url: 'timecards/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return TimeCardListResponseModel(json.decode(response.body));
      },
    );
  }
}
