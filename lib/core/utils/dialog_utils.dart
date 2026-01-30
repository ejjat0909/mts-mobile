import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_gif_dialogue.dart';
import 'package:mts/presentation/features/pin_dialogue/pin_dialogue_screen.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

/// Dialog utility functions
class DialogUtils {
  /// Show a confirmation dialog
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String description,
    required VoidCallback onPressed,
    Icon? icon,
    String? title,
    String? confirmText,
    String? cancelText,
  }) {
    return ConfirmDialog.show(
      context,
      description: description,
      onPressed: onPressed,
      icon: icon,
      title: title,
      btnConfirmText: confirmText,
      btnCancelText: cancelText,
    );
  }

  /// Show a custom dialog
  static Future<void> showCustomDialog(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onPressed,
    String? buttonText,
    IconData? icon,
  }) {
    return CustomDialog.show(
      context,
      title: title,
      description: description,
      btnOkOnPress: onPressed,
      btnOkText: buttonText,
      icon: icon,
    );
  }

  static Future<void> showUnSavedOrderDialogue(BuildContext context) {
    return CustomDialog.show(
      context,
      dialogType: DialogType.warning,
      icon: FontAwesomeIcons.triangleExclamation,
      title: 'unSavedOrder'.tr(),
      description: 'unSavedOrderList'.tr(),
      btnOkOnPress: () {
        NavigationUtils.pop(context);
      },
      btnOkText: 'ok'.tr(),
    );
  }

  /// Show a loading dialog with GIF
  static Future<void> showLoadingDialog(
    BuildContext context, {
    required String loadingText,
    required String gifPath,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return LoadingGifDialogue(gifPath: gifPath, loadingText: loadingText);
      },
    );
  }

  /// Show a simple alert dialog
  static Future<void> showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonText ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show a dialog with multiple options
  static Future<T?> showOptionsDialog<T>(
    BuildContext context, {
    required String title,
    required List<Widget> options,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: options),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static void printerErrorDialogue(
    BuildContext context,
    String message,
    String? ip,
    String? description,
  ) {
    CustomDialog.show(
      context,
      dialogType: DialogType.danger,
      icon: FontAwesomeIcons.print,
      title: message,
      description:
          description ??
          (ip != null
              ? "${'pleaseCheckYourPrinterWithIP'.tr()} $ip \n ${'doYouWantToPrintAgain'.tr()}"
              : 'Please check your printer.'),
      btnOkText: 'ok'.tr(),
      btnOkOnPress: () {
        NavigationUtils.pop(context);
      },
    );
  }

  /// Show a dialog with text input
  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    required String hintText,
    String? initialValue,
    String? confirmButtonText,
    String? cancelButtonText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hintText),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelButtonText ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(confirmButtonText ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show loading dialog with GIF
  static Future<dynamic> showLoadingGifDialog({
    required BuildContext context,
    required String loadingText,
    required String gifPath,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return LoadingGifDialogue(gifPath: gifPath, loadingText: loadingText);
      },
    );
  }

  /// Show a custom date range picker dialog
  ///
  /// This method displays a date range picker dialog and updates the provided
  /// ReceiptNotifier with the selected date range.
  ///
  /// Parameters:
  /// - context: The BuildContext for showing the dialog
  /// - receiptNotifier: The ReceiptNotifier to update with the selected date range
  /// - onSelectDate: Callback function to execute after a date is selected
  static Future<void> showCustomDatePicker(
    BuildContext context,
    ReceiptNotifier receiptNotifier, {
    required Function() onSelectDate,
  }) async {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    List<DateTime>? dateTimeList = await showOmniDateTimeRangePicker(
      context: context,
      startInitialDate: DateTime.now(),
      isForceEndDateAfterStartDate: true,
      // user cannot choose end date before start date
      startFirstDate: DateTime(2023, 1, 1),
      startLastDate: DateTime.now().add(const Duration(days: 3652)),
      endInitialDate: DateTime.now(),
      endFirstDate: DateTime(2023, 1, 1),
      endLastDate: DateTime.now().add(const Duration(days: 3652)),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: BoxConstraints(
        maxHeight: availableHeight,
        maxWidth: availableWidth / 3,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(Tween(begin: 0, end: 1)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: false,
      theme: ThemeData(primaryColorLight: kPrimaryColor),
    );

    if (dateTimeList != null) {
      if (dateTimeList.isNotEmpty) {
        receiptNotifier.setSelectedDateRange(
          DateTimeRange(start: dateTimeList[0], end: dateTimeList[1]),
        );

        onSelectDate();
      }
    }
  }

  static void showNoPermissionDialogue(context) {
    CustomDialog.show(
      context,
      icon: FontAwesomeIcons.lock,
      title: 'youDontHavePermissionForThisAction'.tr(),
      btnOkText: 'OK',
      btnOkOnPress: () {
        NavigationUtils.pop(context);
      },
    );
  }

  static void showFeatureNotAvailable(context) {
    CustomDialog.show(
      context,
      icon: FontAwesomeIcons.lock,
      title: 'thisFeatureIsNotAvailable'.tr(),
      btnOkText: 'OK',
      btnOkOnPress: () {
        NavigationUtils.pop(context);
      },
    );
  }

  /// Show a PIN dialog
  ///
  /// This method displays a PIN entry dialog for authentication purposes.
  ///
  /// Parameters:
  /// - context: The BuildContext for showing the dialog
  /// - onSuccess: Callback function to execute when PIN is successfully entered
  /// - onError: Callback function to execute when there's an error (receives error message)
  /// - barrierDismissible: Whether the dialog can be dismissed by tapping outside (default: true)
  ///
  /// Returns a Future that completes when the dialog is dismissed
  static Future<void> showPinDialog(
    BuildContext context, {
    required String permission,
    required Function() onSuccess,
    required Function(String message) onError,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        return PinDialogueScreen(
          permission: permission,
          onSuccess: onSuccess,
          onError: onError,
        );
      },
    );
  }
}
