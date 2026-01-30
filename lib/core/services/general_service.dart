import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interface for the General Facade
///
/// This facade provides a simplified interface for general application operations,
/// abstracting the complexity of interacting with multiple repositories
/// (local, remote, sync) and other services.
abstract class GeneralService {
  /// Get all data from local database and update the notifiers
  Future<void> getAllDataFromLocalDb(
    WidgetRef ref,
    BuildContext? context,
    Function(bool) isLoadingCallback, {
    required Function(bool) isDownloadData,
    required bool needDownloadImages,
  });

  /// Download images from remote server
  Future<void> downloadImages(BuildContext? context, Function(bool) onDownload);

  /// Delete the database
  Future<void> deleteDatabaseProcess();

  /// Initialize Pusher for real-time updates
  Future<bool> initializePusher(String companyId);

  Future<void> subscribePusher();
}
