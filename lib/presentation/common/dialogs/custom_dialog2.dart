import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class CustomDialog2 extends StatelessWidget {
  /// A customizable dialog widget that can be directly returned in a build method
  ///
  /// Parameters:
  /// - [center]: Optional widget to display in the center of the dialog
  /// - [icon]: Optional icon to display at the top of the dialog
  /// - [title]: Optional title text for the dialog
  /// - [description]: Optional description text for the dialog
  /// - [dialogType]: Type of dialog (info, success, warning, danger)
  /// - [btnOkText]: Text for the primary/confirm button
  /// - [btnCancelText]: Text for the secondary/cancel button
  /// - [isDissmissable]: Whether dialog can be dismissed
  /// - [btnCancelOnPress]: Callback for cancel button press
  /// - [btnOkOnPress]: Callback for confirm button press
  /// - [maxWidth]: Optional maximum width for the dialog
  /// - [minWidth]: Optional minimum width for the dialog

  final Widget? center;
  final IconData? icon;
  final String? title;
  final String? description;
  final int dialogType;
  final String? btnOkText;
  final String? btnCancelText;
  final bool isDissmissable;
  final Function()? btnCancelOnPress;
  final Function()? btnOkOnPress;
  final double? maxWidth;
  final double? minWidth;

  const CustomDialog2({
    super.key,
    this.center,
    this.icon,
    this.title,
    this.description,
    this.dialogType = DialogType.info,
    this.btnOkText,
    this.btnCancelText,
    this.isDissmissable = true,
    this.btnCancelOnPress,
    this.btnOkOnPress,
    this.maxWidth,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;

    // Default width calculations if not provided
    double defaultMaxWidth = availableWidth / 3;
    double defaultMinWidth = availableWidth / 3;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? defaultMaxWidth,
          minWidth: minWidth ?? defaultMinWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getBgColor(dialogType),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: getTextColor(dialogType),
                      size: 32,
                    ),
                  ),
                ),
              if (icon != null) const Space(15),
              if (title != null)
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              if (title != null) const Space(12),
              if (description != null)
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextGray, fontSize: 14),
                ),
              if (description != null) const Space(15),
              if (center != null) center!,
              if (center != null) const Space(15),
              if (btnOkText != null || btnCancelText != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (btnCancelText != null)
                      Expanded(
                        child: ScaleTap(
                          onPressed:
                              btnCancelOnPress ??
                              () {
                                Navigator.of(context).pop(false);
                              },
                          child: Container(
                            decoration: BoxDecoration(
                              color: kPrimaryLightColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Center(
                                child: Text(
                                  btnCancelText!,
                                  style: const TextStyle(
                                    color: kTextGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (btnCancelText != null && btnOkText != null)
                      const SizedBox(width: 12),
                    if (btnOkText != null)
                      Expanded(
                        child: ScaleTap(
                          onPressed:
                              btnOkOnPress ??
                              () {
                                Navigator.of(context).pop(true);
                              },
                          child: Container(
                            decoration: BoxDecoration(
                              color: getTextColor(dialogType),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Center(
                                child: Text(
                                  btnOkText!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets the text color based on dialog type
  static Color getTextColor(int dialogType) {
    switch (dialogType) {
      case DialogType.success:
        return kTextSuccess;
      case DialogType.danger:
        return kTextDanger;
      case DialogType.warning:
        return kTextWarning;
      case DialogType.info:
      default:
        return kTextInfo;
    }
  }

  /// Gets the background color based on dialog type
  static Color getBgColor(int dialogType) {
    switch (dialogType) {
      case DialogType.success:
        return kBgSuccess;
      case DialogType.danger:
        return kBgDanger;
      case DialogType.warning:
        return kBgWarning;
      case DialogType.info:
      default:
        return kBgInfo;
    }
  }

  /// Shows the dialog using the showDialog method
  static Future<bool?> show(
    BuildContext context, {
    Widget? center,
    IconData? icon,
    String? title,
    String? description,
    int dialogType = DialogType.info,
    String? btnOkText,
    String? btnCancelText,
    bool isDissmissable = true,
    Function()? btnCancelOnPress,
    Function()? btnOkOnPress,
    double? maxWidth,
    double? minWidth,
  }) {
    return showDialog<bool>(
      barrierDismissible: isDissmissable,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => isDissmissable,
          child: CustomDialog2(
            center: center,
            icon: icon,
            title: title,
            description: description,
            dialogType: dialogType,
            btnOkText: btnOkText,
            btnCancelText: btnCancelText,
            isDissmissable: isDissmissable,
            btnCancelOnPress: btnCancelOnPress,
            btnOkOnPress: btnOkOnPress,
            maxWidth: maxWidth,
            minWidth: minWidth,
          ),
        );
      },
    );
  }
}
