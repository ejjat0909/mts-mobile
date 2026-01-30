import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class CustomDialog {
  final BuildContext context;

  const CustomDialog({required this.context});

  static Future<bool?> show(
    BuildContext context, {
    StateSetter? stateSetter,
    bool dismissOnTouchOutside = true,
    Widget? center,
    // Widget? top,
    IconData? icon,
    String? title,
    String? description,
    int dialogType = DialogType.info,
    String? btnOkText,
    String? btnCancelText,
    bool isDissmissable = true,
    Function()? btnCancelOnPress,
    Function()? btnOkOnPress,
  }) async {
    return await showDialog<bool>(
      barrierDismissible: isDissmissable,
      context: context,
      builder: (BuildContext context) {
        double availableWidth = MediaQuery.of(context).size.width;
        return StatefulBuilder(
          builder: (context, setter) {
            stateSetter = setter;
            return WillPopScope(
              onWillPop: () async => isDissmissable,
              child: Dialog(
                // insetPadding: const EdgeInsets.only(
                //     left: 450, right: 450, top: 180, bottom: 180),
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: availableWidth / 3,
                    minWidth: availableWidth / 3,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        icon != null
                            ? Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: getBgColor(dialogType),
                              ),
                              child: Center(
                                child: Icon(
                                  icon,
                                  color: getTextColor(dialogType),
                                  size: 30,
                                ),
                              ),
                            )
                            : const Space(0),
                        // top ?? Space(0),
                        icon != null ? const Space(10) : const Space(0),
                        title != null
                            ? Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                            : const Space(0),
                        title != null ? const Space(10) : const Space(0),
                        description != null
                            ? Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kTextGray),
                            )
                            : const Space(0),
                        description != null ? const Space(10) : const Space(0),
                        center ?? const SizedBox(height: 0),
                        center != null ? const Space(10) : const Space(0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            btnCancelText != null
                                ? Expanded(
                                  child: ScaleTap(
                                    onPressed: btnCancelOnPress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: kPrimaryLightColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Center(
                                          child: Text(
                                            btnCancelText,
                                            style: const TextStyle(
                                              color: kTextGray,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                : Container(),
                            btnCancelText != null && btnOkText != null
                                ? const SizedBox(width: 10)
                                : const SizedBox(width: 0),
                            btnOkText != null
                                ? Expanded(
                                  child: ScaleTap(
                                    onPressed: btnOkOnPress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: getTextColor(dialogType),

                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Center(
                                          child: Text(
                                            btnOkText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                : Container(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Color getTextColor(int dialogType) {
    if (dialogType == DialogType.success) {
      return kTextSuccess;
    } else if (dialogType == DialogType.danger) {
      return kTextDanger;
    } else if (dialogType == DialogType.warning) {
      return kTextWarning;
    } else {
      return kTextInfo;
    }
  }

  static Color getBgColor(int dialogType) {
    if (dialogType == DialogType.success) {
      return kBgSuccess;
    } else if (dialogType == DialogType.danger) {
      return kBgDanger;
    } else if (dialogType == DialogType.warning) {
      return kBgWarning;
    } else {
      return kBgInfo;
    }
  }
}
