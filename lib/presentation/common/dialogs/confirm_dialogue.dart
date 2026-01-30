import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class ConfirmDialog extends StatefulBuilder {
  // ignore: use_key_in_widget_constructors
  const ConfirmDialog({required super.builder});

  static Future<bool?> show(
    BuildContext context, {
    StateSetter? stateSetter,
    bool dismissOnTouchOutside = true,
    bool isDissmissable = true,
    Icon? icon,
    String? btnCancelText,
    String? btnConfirmText,
    final Function()? btnCancelPress,
    String? title,
    required String description,
    required final Function() onPressed,
    int dialogType = DialogType.warning,
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
                                  icon.icon,
                                  color: getTextColor(dialogType),
                                  size: 30,
                                ),
                              ),
                            )
                            : Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: getBgColor(dialogType),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.warning_amber,
                                  color: getTextColor(dialogType),
                                  size: 30,
                                ),
                              ),
                            ),
                        const Space(10),
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
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: kTextGray),
                        ),
                        const Space(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ScaleTap(
                                onPressed:
                                    btnCancelPress ??
                                    () {
                                      NavigationUtils.pop(context, false);
                                    },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryLightColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Center(
                                      child: Text(
                                        btnCancelText ?? 'cancel'.tr(),
                                        style: const TextStyle(
                                          color: kTextGray,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ScaleTap(
                                onPressed: () {
                                  onPressed();
                               
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: getTextColor(dialogType),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Center(
                                      child: Text(
                                        btnConfirmText ?? 'confirm'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white,
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
