import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/error_log/error_log_model.dart';

/// Interface for remote error log repository operations
abstract class RemoteErrorLogRepository {
  /// Send error log to remote server
  Resource sendErrorLog(ErrorLogModel errorLogModel);

  /// Get error logs from remote server
  Resource getErrorLogs();

  /// Sync error logs with remote server
  Resource syncErrorLogs(List<ErrorLogModel> errorLogs);
}