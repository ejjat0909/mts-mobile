import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Timecard Repository
abstract class TimecardRepository {
  /// Get list of timecards from API
  Resource getTimecardList();
  
  /// Get list of timecards from API with pagination
  Resource getTimecardListPaginated(String page);
}
