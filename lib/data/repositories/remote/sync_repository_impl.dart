import 'dart:convert';

import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/pending_changes/pending_changes_sync_request_model.dart';
import 'package:mts/data/models/pending_process/pending_process_list_response_model.dart';
import 'package:mts/data/models/sync_check/sync_check_response_model.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';

/// Implementation of SyncRepository
class SyncRepositoryImpl implements SyncRepository {
  /// [sync deletedDatas]
  @override
  Resource syncPendingChanges(PendingChangesSyncRequestModel requestModel) {
    return Resource(
      url: 'sync/pending-changes',
      data: requestModel.toJson(),
      parse: (response) {
        try {
          return PendingProcessListResponseModel(json.decode(response.body));
        } catch (e) {
          return PendingProcessListResponseModel({
            'is_success': false,
            'message': 'Server error occurred during sync',
            'status_code': response.statusCode,
          });
        }
      },
    );
  }

  /// Check models to sync
  @override
  Resource syncCheck({required Map<String, dynamic> data}) {
    return Resource(
      url: 'sync/check',
      data: data,
      parse: (response) {
        try {
          return SyncCheckResponseModel(json.decode(response.body));
        } catch (e) {
          return SyncCheckResponseModel({
            'is_success': false,
            'message': 'Server error occurred during sync check',
            'status_code': response.statusCode,
          });
        }
      },
    );
  }
}
