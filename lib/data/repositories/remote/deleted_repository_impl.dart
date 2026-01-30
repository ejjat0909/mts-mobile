import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/deleted/deleted_list_response_model.dart';
import 'package:mts/data/models/deleted/deleted_model.dart';
import 'package:mts/domain/repositories/remote/deleted_repository.dart';

class DeletedRepositoryImpl implements DeletedRepository {
  /// Get list of deleted records without pagination
  @override
  Resource getDeletedList() {
    return Resource(
      modelName: DeletedModel.modelName,
      url: 'deleted-models/list',
      parse: (response) {
        return DeletedListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of deleted records with pagination
  @override
  Resource getDeletedListPaginated(String page) {
    return Resource(
      modelName: DeletedModel.modelName,
      url: 'deleted-models/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return DeletedListResponseModel(json.decode(response.body));
      },
    );
  }
}
