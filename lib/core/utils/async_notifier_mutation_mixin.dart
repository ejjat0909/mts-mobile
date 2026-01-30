import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin to provide common mutation operations for AsyncNotifier classes
/// Handles loading, error, and success states consistently
mixin AsyncNotifierMutationMixin<T> on AsyncNotifier<T> {
  /// Executes a mutation operation with standardized state management
  ///
  /// [action] - The async operation to execute (returns result of type R)
  /// [onSuccess] - Function to transform the current state on successful operation
  ///
  /// Returns the result of the action
  Future<R> mutate<R>(
    Future<R> Function() action,
    T Function(T currentState) onSuccess,
  ) async {
    final previous = state.value; // Capture state before loading

    // Set loading while preserving hasValue flag
    state =
        previous != null
            ? AsyncValue<T>.loading().copyWithPrevious(
              AsyncValue.data(previous),
            )
            : const AsyncValue.loading();

    try {
      final result = await action();

      // Only update state if we have a previous value to work with
      if (previous != null) {
        state = AsyncValue.data(onSuccess(previous));
      } else {
        // If no previous state, trigger a rebuild to fetch fresh data
        ref.invalidateSelf();
      }

      return result;
    } catch (e, stackTrace) {
      // Restore previous state on error if available
      if (previous != null) {
        state = AsyncValue<T>.error(
          e,
          stackTrace,
        ).copyWithPrevious(AsyncValue.data(previous));
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }
}
