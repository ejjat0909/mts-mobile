import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/department_printer/department_printer_list_response_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/domain/repositories/remote/department_printer_repository.dart';

class DepartmentPrinterRepositoryImpl implements DepartmentPrinterRepository {
  /// Get department printers without pagination
  @override
  Resource getDepartmentPrinter(String? companyId) {
    return Resource(
      modelName: DepartmentPrinterModel.modelName,
      url: 'department-printers/list',
      parse: (response) {
        return DepartmentPrinterListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get department printers with pagination
  @override
  Resource getDepartmentPrinterList(String page, {String? companyId}) {
    return Resource(
      modelName: DepartmentPrinterModel.modelName,
      url: 'department-printers/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return DepartmentPrinterListResponseModel(json.decode(response.body));
      },
    );
  }
}
