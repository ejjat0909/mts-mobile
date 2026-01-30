import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/temp/temp_model.dart';
import 'package:mts/presentation/common/dialogs/loading_gif_dialogue.dart';
import 'package:mts/presentation/common/layouts/background.dart';
import 'package:mts/presentation/features/after_login/components/choose_pos_device_body.dart';
import 'package:mts/presentation/features/after_login/components/choose_store_body.dart';
import 'package:mts/presentation/features/pin_lock/components/pin_lock_body.dart.dart';
import 'package:mts/presentation/features/pin_time_in_out/components/clock_in_success.dart';
import 'package:mts/presentation/features/pin_time_in_out/components/clock_out_success.dart';
import 'package:mts/presentation/features/pin_time_in_out/components/pin_clock_in_out_body.dart';
import 'package:mts/providers/app/app_state.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/app/app_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

class AfterLoginScreen extends ConsumerStatefulWidget {
  final String token;
  final bool? isFromHome;
  final TempModel? tempModel;
  final int? initialIndex;

  const AfterLoginScreen({
    super.key,
    this.isFromHome = false,
    this.tempModel,
    this.token = '',
    this.initialIndex, // for now only use in main.dart
  });

  static const routeName = '/after_login';

  @override
  ConsumerState<AfterLoginScreen> createState() => _AfterLoginScreenState();
}

class _AfterLoginScreenState extends ConsumerState<AfterLoginScreen> {
  Timer? timer;
  int pageIndex = 2;

  bool dialogShown = false;
  bool _isDisposed = false;
  late ValueNotifier<double> progressNotifier;
  late ValueNotifier<String> progressTextNotifier;
  late ValueNotifier<String> errorNotifier;

  // Store dialog context to close it even if widget is disposed
  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();

    progressNotifier = ValueNotifier<double>(0.0);
    progressTextNotifier = ValueNotifier<String>('');
    errorNotifier = ValueNotifier<String>(''); // Add errorNotifier

    if (widget.token != '') {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        if (widget.initialIndex != null) {
          pageIndex = widget.initialIndex!;
          setState(() {});
        }
        //  navigate to pin lock screen
        final myNavigator = ServiceLocator.get<MyNavigatorNotifier>();

        setLocalPageIndex(myNavigator);
      });
    }
  }

  void setLocalPageIndex(MyNavigatorNotifier myNavigator) {
    if (pageIndex == 0) {
      myNavigator.setPageIndex(pageIndex, 'chooseStore'.tr());
    } else if (pageIndex == 1) {
      myNavigator.setPageIndex(pageIndex, 'choosePosDevice'.tr());
    } else if (pageIndex == 2) {
      myNavigator.setPageIndex(pageIndex, 'pinLock'.tr());
    } else {
      // fallback choose store
      // if the code going to this block, please fix the bugs
      // maybe because not checking page index for 3,4,5
      // but if page index is 3,4,5, that is a bug not should not happen
      // so YOU should fix the bug
      prints("RARE CASE PAGE INDEX: $pageIndex");
      myNavigator.setPageIndex(0, 'chooseStore'.tr());
    }
  }

  void _updateProgress(AppState appContextState) {
    if (appContextState.isSyncing) {
      prints(
        'Updating progress: ${appContextState.syncProgress}% - ${appContextState.syncProgressText}',
      );
      progressNotifier.value = appContextState.syncProgress;
      progressTextNotifier.value = appContextState.syncProgressText;

      if (appContextState.syncProgress >= 100.0 && dialogShown) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && dialogShown && !_isDisposed) {
            prints('⚠️ Auto-closing dialog after reaching 100% progress');
            _closeLoadingDialog();
          }
        });
      }
    } else if (!appContextState.isSyncing && dialogShown) {
      prints('⚠️ Closing dialog because sync is no longer active');
      _closeLoadingDialog();
    }
  }

  void _showLoadingDialog() {
    if (!dialogShown && mounted && !_isDisposed) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          // Store dialog context for later use
          _dialogContext = dialogContext;
          return LoadingGifDialogue(
            gifPath: 'assets/images/play-download.gif',
            loadingText: 'Syncing'.tr(),
            progressNotifier: progressNotifier,
            speedNotifier: progressTextNotifier,
            errorNotifier: errorNotifier, // Add errorNotifier
          );
        },
      );

      // Safety timeout: force close dialog after 60 seconds if still open
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted && dialogShown && !_isDisposed) {
          prints('⚠️ Force closing dialog after 60 second timeout');
          _closeLoadingDialog();
        }
      });
    }
  }

  void _closeLoadingDialog() {
    if (dialogShown) {
      dialogShown = false;

      // Try to close using dialog context first (more reliable)
      if (_dialogContext != null) {
        try {
          if (Navigator.canPop(_dialogContext!)) {
            Navigator.of(_dialogContext!, rootNavigator: true).pop();
            prints('✅ Dialog closed using dialog context');
            _dialogContext = null;
            return;
          }
        } catch (e) {
          prints('⚠️ Failed to close dialog using dialog context: $e');
        }
      }

      // Fallback: try to close using widget context
      if (mounted && !_isDisposed) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
            prints('✅ Dialog closed using widget context');
            _dialogContext = null;
            return;
          }
        } catch (e) {
          prints('⚠️ Failed to close dialog using widget context: $e');
        }
      }

      // If both methods fail, just clear the reference
      _dialogContext = null;
      prints('⚠️ Dialog could not be closed, but state cleared');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Close dialog if it's shown
    if (dialogShown) {
      _closeLoadingDialog();
    }

    progressNotifier.dispose();
    progressTextNotifier.dispose();
    errorNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appContextState = ref.watch(appProvider);
    bool isSyncing = appContextState.isSyncing;

    // Listen to app context changes and update progress
    ref.listen<AppState>(appProvider, (previous, next) {
      _updateProgress(next);
    });

    // Update progress notifiers when app context changes
    _updateProgress(appContextState);

    // Handle dialog based on syncing state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        if (isSyncing && !dialogShown) {
          _showLoadingDialog();
        } else if (!isSyncing && dialogShown) {
          _closeLoadingDialog();
        }
      }
    });

    return WillPopScope(
      onWillPop: () {
        return NavigationUtils.showExitPopup(context);
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            const Positioned(
              top: 0.0,
              bottom: 0.0,
              right: 0.0,
              left: 0.0,
              child: Background(),
            ),
            Positioned(child: getScreen()),
            Positioned(
              bottom: 10.0,
              right: 20.0,
              child: SafeArea(
                child: InkWell(
                  onTap: () async {
                    await ref
                        .read(userProvider.notifier)
                        .logoutConfirmation(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'logout'.tr(),
                      style: const TextStyle(
                        // underline text
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getScreen() {
    // 0 = storebody
    // 1 = choose pos device
    // 2 = pin lock
    // 3 = pin clock in out body
    // 4 = success clock in
    // 5 = success clock out
    pageIndex = ref.watch(myNavigatorProvider).pageIndex;
    switch (pageIndex) {
      case 0:
        return ChooseStoreBody(currentBodyIndex: pageIndex);
      case 1:
        return ChoosePosDeviceBody(currentBodyIndex: pageIndex);
      case 2:
        return PinLockBody(currentIndex: pageIndex);
      case 3:
        return PinClockInOutBody(currentIndex: pageIndex);
      case 4:
        return ClockInSuccess(
          afterLoginContext: context,
          currentIndex: pageIndex,
          isFromHome: widget.isFromHome,
          tempModel: widget.tempModel,
        );
      case 5:
        return ClockOutSuccess(currentIndex: pageIndex);
      default:
        return PinLockBody(currentIndex: 2);
    }
  }
}
