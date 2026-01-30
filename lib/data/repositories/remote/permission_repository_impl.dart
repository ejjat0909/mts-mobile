import 'dart:convert';

import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/domain/repositories/remote/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  /// Get all permissions
  @override
  Resource getAllPermissions() {
    return Resource(
      modelName: PermissionModel.modelName,
      url: 'permissions/all',
      parse: (response) {
        return DefaultResponseModel(json.decode(response.body));
      },
    );
  }
}
