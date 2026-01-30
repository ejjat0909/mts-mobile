import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/table_section/table_section_list_response_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/domain/repositories/remote/table_section_repository.dart';

/// Implementation of [TableSectionRepository] for remote data source
class TableSectionRepositoryImpl implements TableSectionRepository {
  /// Get list of table sections from API with pagination
  @override
  Resource getTableSectionList(String page) {
    return Resource(
      modelName: TableSectionModel.modelName,
      url: 'table-sections/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return TableSectionListResponseModel(json.decode(response.body));
      },
    );
  }
}
