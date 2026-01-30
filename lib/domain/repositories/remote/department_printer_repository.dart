import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Department Printer Repository
abstract class DepartmentPrinterRepository {
  /// Get department printers without pagination
  Resource getDepartmentPrinter(String? companyId);
  
  /// Get department printers with pagination
  Resource getDepartmentPrinterList(String page, {String? companyId});
}
