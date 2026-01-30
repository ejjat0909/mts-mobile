import 'dart:convert';

import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/error_log/error_log_model.dart';
import 'package:mts/data/models/error_log/error_log_response_model.dart';
import 'package:mts/domain/repositories/remote/error_log_repository.dart';

/// Implementation of [RemoteErrorLogRepository] that uses Resource pattern
class RemoteErrorLogRepositoryImpl implements RemoteErrorLogRepository {
  /// Send error log to remote server
  @override
  Resource sendErrorLog(ErrorLogModel errorLogModel) {
    return Resource(
      url: 'error-logs',
      data: errorLogModel.toJson(),
      parse: (response) {
        return ErrorLogResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get error logs from remote server
  @override
  Resource getErrorLogs() {
    return Resource(
      url: 'error-logs',
      parse: (response) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => ErrorLogModel.fromJson(json)).toList();
      },
    );
  }

  /// Sync error logs with remote server
  @override
  Resource syncErrorLogs(List<ErrorLogModel> errorLogs) {
    return Resource(
      url: 'error-logs/sync',
      data: {
        'error_logs': errorLogs.map((errorLog) => errorLog.toJson()).toList(),
      },
      parse: (response) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      },
    );
  }
}