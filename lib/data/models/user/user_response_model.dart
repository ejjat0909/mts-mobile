import 'package:mts/core/network/base_api_response.dart';
import 'package:mts/data/models/meta_model.dart';
import 'package:mts/data/models/paginator_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/user/login_form_error_model.dart';

class UserResponseModel
    extends BaseAPIResponse<UserModel, LoginFormErrorModel> {
  UserResponseModel(super.fullJson);

  @override
  Map<String, dynamic>? dataToJson(UserModel? data) {
    if (data != null) {
      return this.data!.toJson();
    }
    return null;
  }

  @override
  Map<String, dynamic>? metaToJson(MetaModel? meta) {
    if (meta != null) {
      return this.meta!.toJson();
    }
    return null;
  }

  @override
  Map<String, dynamic>? errorsToJson(LoginFormErrorModel? errors) {
    return errors?.toJson();
  }

  @override
  UserModel? jsonToData(Map<String, dynamic>? json) {
    return json!['data'] != null ? UserModel.fromJson(json['data']) : null;
  }

  @override
  MetaModel? jsonToMeta(Map<String, dynamic>? json) {
    if (json != null) {
      if (json['meta'] != null) {
        return MetaModel.fromJson(json['meta']);
      }
    }
    return null;
  }

  @override
  LoginFormErrorModel? jsonToError(Map<String, dynamic> json) {
    if (json['errors'] != null) {
      return LoginFormErrorModel.fromJson(json['errors']);
    }
    return null;
  }

  @override
  PaginatorModel? jsonToPaginator(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  PaginatorModel? paginatorToJson(PaginatorModel? paginatorModel) {
    throw UnimplementedError();
  }
}
