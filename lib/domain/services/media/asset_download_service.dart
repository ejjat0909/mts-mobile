import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/domain/repositories/local/downloaded_file_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for downloading and managing assets (images, files)
///
/// This service handles:
/// - Concurrent asset downloads with progress tracking
/// - Speed calculation and reporting
/// - File path management
/// - Download state persistence
class AssetDownloadService {
  final LocalDownloadedFileRepository _downloadedFileRepository;
  final Dio _dio;

  AssetDownloadService({
    required LocalDownloadedFileRepository downloadedFileRepository,
    Dio? dio,
  }) : _downloadedFileRepository = downloadedFileRepository,
       _dio = dio ?? Dio();

  /// Download all pending assets with progress tracking
  ///
  /// Parameters:
  /// - [onProgress]: Callback for overall progress (0-100)
  /// - [onSpeed]: Callback for download speed (formatted string)
  /// - [onError]: Callback for error messages
  /// - [concurrency]: Number of simultaneous downloads (default: 3)
  ///
  /// Returns the number of successfully downloaded files
  Future<int> downloadPendingAssets({
    ValueNotifier<double>? onProgress,
    ValueNotifier<String>? onSpeed,
    ValueNotifier<String>? onError,
    int concurrency = 3,
  }) async {
    try {
      // Get files that need downloading
      final allDownloadedFiles =
          await _downloadedFileRepository.getListDownloadedFile();

      final filesToDownload =
          allDownloadedFiles
              .where((df) => df.url != null && !df.isDownloaded!)
              .toList();

      if (filesToDownload.isEmpty) {
        prints('No files to download');
        return 0;
      }

      prints('Found ${filesToDownload.length} files to download');

      // Prepare download directory
      final directory = await _getDownloadDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Prepare download tasks with file paths
      final downloadTasks = <_DownloadTask>[];
      for (final file in filesToDownload) {
        final updatedFile = file.copyWith(
          updatedAt: DateTime.now(),
          path:
              file.fileName != null
                  ? '${directory.path}/${DownloadedFileModel.modelName}/${file.fileName}'
                  : '${directory.path}/${DownloadedFileModel.modelName}/${FormatUtils.getFileNameFromUrl(file.url!)}',
        );

        if (updatedFile.url != null && updatedFile.path != null) {
          downloadTasks.add(
            _DownloadTask(
              url: updatedFile.url!,
              filePath: updatedFile.path!,
              downloadedFileModel: updatedFile,
            ),
          );
        }
      }

      // Execute downloads
      final queue = _AsyncDownloadQueue(
        concurrency: concurrency,
        dio: _dio,
        repository: _downloadedFileRepository,
        progressNotifier: onProgress,
        speedNotifier: onSpeed,
        totalFiles: downloadTasks.length,
      );

      await queue.processQueue(downloadTasks);

      prints('Successfully downloaded ${downloadTasks.length} files');
      return downloadTasks.length;
    } catch (e) {
      prints('Error downloading assets: $e');
      onError?.value = e.toString();
      rethrow;
    }
  }

  /// Get the appropriate download directory based on platform
  Future<Directory> _getDownloadDirectory() async {
    Directory? directory =
        Platform.isAndroid
            ? await getDownloadsDirectory()
            : await getApplicationDocumentsDirectory();

    return directory ?? await getApplicationDocumentsDirectory();
  }
}

/// Internal class for managing download tasks
class _DownloadTask {
  final String url;
  final String filePath;
  final DownloadedFileModel downloadedFileModel;

  _DownloadTask({
    required this.url,
    required this.filePath,
    required this.downloadedFileModel,
  });
}

/// Internal class for managing concurrent downloads with progress tracking
class _AsyncDownloadQueue {
  final int concurrency;
  final Dio dio;
  final LocalDownloadedFileRepository repository;
  final ValueNotifier<double>? progressNotifier;
  final ValueNotifier<String>? speedNotifier;
  final int totalFiles;

  int _completedFiles = 0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _speedTimer;
  int _lastReceived = 0;

  _AsyncDownloadQueue({
    required this.concurrency,
    required this.dio,
    required this.repository,
    this.progressNotifier,
    this.speedNotifier,
    required this.totalFiles,
  }) {
    _stopwatch.start();
    _startSpeedTimer();
  }

  void _startSpeedTimer() {
    _speedTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_stopwatch.elapsedMilliseconds > 0) {
        final bytesPerSecond = _lastReceived / 1.0;
        speedNotifier?.value = FormatUtils.formatSpeed(bytesPerSecond);
        _lastReceived = 0;
        _stopwatch.reset();
      }
    });
  }

  Future<void> processQueue(List<_DownloadTask> tasks) async {
    final pool = List.generate(concurrency, (_) => Future.value());

    for (final task in tasks) {
      final next = pool.removeAt(0).then((_) => _downloadFile(task));
      pool.add(next);
    }

    await Future.wait(pool);

    _speedTimer?.cancel();
    _stopwatch.stop();
  }

  Future<void> _downloadFile(_DownloadTask task) async {
    try {
      await dio.download(
        Uri.encodeFull(task.url),
        task.filePath,
        onReceiveProgress: (received, total) {
          _lastReceived = received;

          if (total != -1) {
            final singleFileProgress = (received / total);
            final overallProgress =
                (_completedFiles + singleFileProgress) / totalFiles * 100;
            progressNotifier?.value = overallProgress;
          }
        },
      );

      // Mark as downloaded
      final updatedModel = task.downloadedFileModel.copyWith(
        isDownloaded: true,
        updatedAt: DateTime.now(),
      );

      await repository.upsertBulk([updatedModel], isInsertToPending: false);

      _completedFiles++;
      progressNotifier?.value = (_completedFiles / totalFiles) * 100;

      prints('Downloaded: ${task.downloadedFileModel.fileName}');
    } catch (e) {
      prints('Error downloading ${task.url}: $e');
      // Continue with other downloads even if one fails
    }
  }
}

/// Provider for AssetDownloadService
final assetDownloadServiceProvider = Provider<AssetDownloadService>((ref) {
  return AssetDownloadService(
    downloadedFileRepository:
        ServiceLocator.get<LocalDownloadedFileRepository>(),
  );
});
