import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/permission/permission_providers.dart';

class TableOccupiedDialog extends ConsumerStatefulWidget {
  final String headerTitle;
  final Widget? headerRightAction;
  final Function()? saveAction;
  final Function() editOrderAction;
  final Widget? content;
  final TextEditingController? headerTitleController;
  final String footerTitle;
  final bool isDissmissable;

  const TableOccupiedDialog({
    super.key,
    required this.headerTitle,
    this.headerRightAction,
    this.saveAction,
    required this.editOrderAction,
    this.content,
    this.headerTitleController,
    required this.footerTitle,
    this.isDissmissable = true,
  });

  @override
  ConsumerState<TableOccupiedDialog> createState() =>
      _TableOccupiedDialogState();

  static Future<void> show(
    BuildContext context, {
    StateSetter? stateSetter,
    bool dismissOnTouchOutside = true,
    bool isTitleBold = false,
    required String headerTitle,
    Widget? headerRightAction,
    Function()? saveAction,
    required Function() editOrderAction,
    Widget? content,
    TextEditingController? headerTitleController,
    required String footerTitle,
    bool isDissmissable = true,
  }) async {
    return await showDialog(
      barrierDismissible: isDissmissable,
      context: context,
      builder: (BuildContext context) {
        return TableOccupiedDialog(
          headerTitle: headerTitle,
          headerRightAction: headerRightAction,
          saveAction: saveAction,
          editOrderAction: editOrderAction,
          content: content,
          headerTitleController: headerTitleController,
          footerTitle: footerTitle,
          isDissmissable: isDissmissable,
        );
      },
    );
  }
}

class _TableOccupiedDialogState extends ConsumerState<TableOccupiedDialog> {
  @override
  Widget build(BuildContext context) {
    final hasPermission = ref.watch(hasAcceptPaymentPermissionProvider);
    return WillPopScope(
      onWillPop: () async => widget.isDissmissable,
      child: Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 350, maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //Header part
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          widget.headerTitleController == null
                              ? Text(
                                widget.headerTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : Expanded(
                                child: TextField(
                                  controller: widget.headerTitleController,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    // border: OutlineInputBorder(
                                    //   borderSide: BorderSide.none,
                                    //   borderRadius:
                                    //       BorderRadius.circular(20),
                                    // ),
                                    // filled: true,
                                    // fillColor: const Color.fromARGB(
                                    //     44, 214, 214, 214),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        children: [
                          widget.headerRightAction ?? const SizedBox(height: 0),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: Colors.grey.withValues(alpha: 0.2),
                  thickness: 1,
                ),
                const SizedBox(height: 10),
                Expanded(child: widget.content ?? const SizedBox(height: 0)),

                //Footer
                const SizedBox(height: 15),

                SizedBox(
                  width: 500,
                  child: Row(
                    children: [
                      Expanded(
                        child: ButtonTertiary(
                          onPressed: widget.editOrderAction,
                          text: 'Edit Order',
                        ),
                      ),
                      hasPermission ? 5.widthBox : 0.widthBox,
                      hasPermission
                          ? Expanded(
                            child: ButtonPrimary(
                              onPressed: widget.saveAction ?? () {},
                              text: widget.footerTitle,
                            ),
                          )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
