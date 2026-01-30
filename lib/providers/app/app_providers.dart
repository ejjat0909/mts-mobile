import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState());

  // Set current route
  void setCurrentRoute(String route) {
    state = state.copyWith(currentRoute: route);
  }

  // Set online status
  void setOnlineStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  // Set theme mode
  void setDarkMode(bool isDarkMode) {
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  // Set app version
  void setAppVersion(String version) {
    state = state.copyWith(appVersion: version);
  }

  // Add or update context value
  void setContextValue(String key, dynamic value) {
    final updatedContext = Map<String, dynamic>.from(state.additionalContext);
    updatedContext[key] = value;
    state = state.copyWith(additionalContext: updatedContext);
  }

  // Remove context value
  void removeContextValue(String key) {
    final updatedContext = Map<String, dynamic>.from(state.additionalContext);
    updatedContext.remove(key);
    state = state.copyWith(additionalContext: updatedContext);
  }

  // Clear all additional context
  void clearAdditionalContext() {
    state = state.copyWith(additionalContext: {});
  }

  void setIsSyncing(bool isSyncing) {
    state = state.copyWith(
      isSyncing: isSyncing,
      syncProgress:
          isSyncing ? 0.0 : 0.0, // Reset progress when starting/stopping sync
      syncProgressText: isSyncing ? 'Starting sync...' : '',
    );
  }

  bool getIsSyncing() {
    return state.isSyncing;
  }

  void setSyncProgress(double progress, String progressText) {
    state = state.copyWith(
      syncProgress: progress,
      syncProgressText: progressText,
    );
  }

  void updateSyncProgress(double progress, String progressText) {
    if (state.isSyncing) {
      state = state.copyWith(
        syncProgress: progress,
        syncProgressText: progressText,
      );
    }
  }

  // Set everDontHaveInternet status
  void setEverDontHaveInternet(bool everDontHaveInternet) {
    state = state.copyWith(everDontHaveInternet: everDontHaveInternet);
  }

  // Get everDontHaveInternet status
  bool getEverDontHaveInternet() {
    return state.everDontHaveInternet;
  }
}

// Provider for the AppState
final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});
