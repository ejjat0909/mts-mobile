import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Shift Repository
abstract class ShiftRepository {
  Resource getShiftList();

  /// Get shift list with pagination
  Resource getShiftListWithPagination(String page);
}
