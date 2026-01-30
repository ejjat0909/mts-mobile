import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_type_enum.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:provider/provider.dart';

class EditTableDetailDialog extends StatefulWidget {
  final Widget? headerRightAction;
  final Function()? saveAction;
  final Function()? cancelAction;
  final Widget? content;
  TextEditingController? headerTitleController;
  final String footerTitle;
  final bool isDissmissable = true;
  final TableModel tableModel;

  EditTableDetailDialog({
    super.key,
    this.headerRightAction,
    this.saveAction,
    this.cancelAction,
    this.content,
    this.headerTitleController,
    this.footerTitle = '',
    required this.tableModel,
  });

  @override
  State<EditTableDetailDialog> createState() => _EditTableDetailDialogState();
}

class _EditTableDetailDialogState extends State<EditTableDetailDialog> {
  final _barcodeScannerNotifier = ServiceLocator.get<BarcodeScannerNotifier>();

  @override
  void initState() {
    super.initState();
    // _barcodeScannerNotifier.initialize();
    _barcodeScannerNotifier.initializeForEditTableDetailDialogue();
  }

  @override
  void dispose() {
    // Reinitialize to sales screen when dialog closes
    _barcodeScannerNotifier.reinitializeToSalesScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    final scannerNotifier = context.watch<BarcodeScannerNotifier>();
    if (scannerNotifier.editTableDetailDialogueBarcode != null &&
        scannerNotifier.editTableDetailDialogueBarcode!.isNotEmpty) {
      widget.headerTitleController?.text =
          scannerNotifier.editTableDetailDialogueBarcode!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scannerNotifier.clearScannedItem();
    });

    return Dialog(
      clipBehavior: Clip.antiAlias,
      // insetPadding:
      //     const EdgeInsets.only(left: 450, right: 450, top: 160, bottom: 145),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 2.1,
          maxWidth: availableWidth / 3,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          child: Column(
            //  mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //Header part
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child:
                        (widget.tableModel.type !=
                                    TableTypeEnum.LINEHORIZONTAL &&
                                widget.tableModel.type !=
                                    TableTypeEnum.LINEVERTICAL)
                            ? Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: widget.headerTitleController,

                                    maxLength: 9,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      //prefixText: 'Table ',
                                      isDense: true,
                                      counterText: '',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: const BorderSide(
                                          color: kTextGray,
                                        ),
                                        gapPadding: 10,
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        15,
                                        10,
                                        15,
                                        10,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: const BorderSide(
                                          color: kTextGray,
                                        ),
                                        gapPadding: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(flex: 4, child: SizedBox()),
                              ],
                            )
                            : const SizedBox(),
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
              //   Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
              const SizedBox(height: 10),
              Expanded(child: widget.content ?? const SizedBox(height: 0)),

              //Footer
              // const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ButtonTertiary(
                      onPressed: widget.cancelAction ?? () {},
                      text: 'Cancel',
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ButtonPrimary(
                      onPressed: widget.saveAction ?? () {},
                      text: widget.footerTitle,
                      size: Size(20, 45.h),
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
}
