import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';

part 'downloaded_file_state.freezed.dart';

/// Immutable state class for DownloadedFile domain using Freezed
@freezed
class DownloadedFileState with _$DownloadedFileState {
  const factory DownloadedFileState({
    @Default([]) List<DownloadedFileModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DownloadedFileState;
}
