import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/staff/staff_list_response_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_response_model.dart';
import 'package:mts/domain/repositories/remote/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  @override
  Resource getStaffList() {
    return Resource(
      modelName: StaffModel.modelName,
      url: 'staffs/list',
      parse: (response) {
        return StaffListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource getStaffListWithPagination(String page) {
    return Resource(
      modelName: StaffModel.modelName,
      url: 'staffs/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return StaffListResponseModel(json.decode(response.body));
      },
    );
  }

  @override
  Resource validateStaffPin(String staffPin) {
    return Resource(
      url: 'login-pin',
      data: {'pin': staffPin},
      parse: (response) {
        return UserResponseModel(json.decode(response.body));
      },
    );
  }
}
