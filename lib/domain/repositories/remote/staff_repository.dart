import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Staff Repository
abstract class StaffRepository {
  Resource getStaffList();
  Resource getStaffListWithPagination(String page);
  Resource validateStaffPin(String staffPin);
}
