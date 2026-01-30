import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/remote_pagination_service.dart';
import 'package:mts/providers/core/core_providers.dart';

/// ================================
/// Data Services Providers
/// ================================

/// Provider for RemotePaginationService
final remotePaginationServiceProvider = Provider<RemotePaginationService>((
  ref,
) {
  return RemotePaginationService(webService: ref.read(webServiceProvider));
});
