import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/async_notifier_mutation_mixin.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/models/cash_drawer_log/cash_drawer_log_model.dart';
import 'package:mts/data/repositories/local/local_cash_drawer_log_repository_impl.dart';
import 'package:mts/domain/repositories/local/cash_drawer_log_repository.dart';
import 'package:mts/providers/cash_drawer_log/cash_drawer_log_state.dart';

/// AsyncNotifier for CashDrawerLog domain
class CashDrawerLogNotifier extends AsyncNotifier<CashDrawerLogState>
    with AsyncNotifierMutationMixin<CashDrawerLogState> {
  late final CashDrawerLogRepository _repository;

  @override
  Future<CashDrawerLogState> build() async {
    _repository = ref.read(cashDrawerLogLocalRepoProvider);

    // Load canonical data from local DB
    final dbItems = await _repository.getListCashDrawerLogs();

    return CashDrawerLogState(items: dbItems);
  }

  /// Insert single log
  Future<int> insert(CashDrawerLogModel model) async {
    model.id ??= IdUtils.generateUUID();
    model.createdAt ??= DateTime.now();
    model.updatedAt ??= DateTime.now();

    return mutate(
      () => _repository.insert(model, isInsertToPending: true),
      (currentState) => currentState.copyWith(
        items: [...currentState.items, model],
      ),
    );
  }

  /// Update single log
  Future<int> updateLog(CashDrawerLogModel model) async {
    model.updatedAt = DateTime.now();

    return mutate(
      () => _repository.update(model, isInsertToPending: true),
      (currentState) => currentState.copyWith(
        items: currentState.items
            .map((e) => e.id == model.id ? model : e)
            .toList(),
      ),
    );
  }

  /// Delete log by ID
  Future<int> delete(String id) async {
    return mutate(
      () => _repository.delete(id, isInsertToPending: true),
      (currentState) => currentState.copyWith(
        items: currentState.items.where((e) => e.id != id).toList(),
      ),
    );
  }

}

/// AsyncNotifier provider
final cashDrawerLogProvider =
    AsyncNotifierProvider<CashDrawerLogNotifier, CashDrawerLogState>(
      () => CashDrawerLogNotifier(),
    );

/// Provider for sorted logs
final sortedCashDrawerLogsProvider = Provider<List<CashDrawerLogModel>>((ref) {
  final state = ref.watch(cashDrawerLogProvider).value;
  if (state == null) return [];
  final sorted = [...state.items];
  sorted.sort((a, b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });
  return sorted;
});

/// Provider to get log by ID
final cashDrawerLogByIdProvider = Provider.family<CashDrawerLogModel?, String>((
  ref,
  id,
) {
  final state = ref.watch(cashDrawerLogProvider).value;
  if (state == null) return null;

  // Use firstWhereOrNull from collection package OR try/catch
  try {
    return state.items.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
});
