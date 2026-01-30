import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/table/table_list_response_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/domain/repositories/remote/table_repository.dart';

class TableRepositoryImpl implements TableRepository {
  @override
  Resource getTableList(String page) {
    return Resource(
      modelName: TableModel.modelName,
      url: 'tables/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return TableListResponseModel(json.decode(response.body));
      },
    );
  }
}
