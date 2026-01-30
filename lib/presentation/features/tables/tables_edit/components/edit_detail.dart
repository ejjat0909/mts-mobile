import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/table_status_enum.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/form_bloc/tables_form_bloc.dart';
import 'package:mts/presentation/common/widgets/styled_dropdown.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';

class EditDetail extends ConsumerStatefulWidget {
  final Function(bool) onChangeSwitch;
  final Function(PredefinedOrderModel) onChangeOpenOrder;
  final bool isAvailable;
  final int? tableStatus;
  final TextEditingController? seatsController;
  final TablesFormBloc? tablesFormBloc;
  final String? selectedPredefinedOrderId;
  final TableModel tableModel;

  const EditDetail({
    super.key,
    required this.onChangeSwitch,
    required this.onChangeOpenOrder,
    this.isAvailable = true,
    this.tableStatus,
    this.seatsController,
    this.tablesFormBloc,
    this.selectedPredefinedOrderId,
    required this.tableModel,
  });

  @override
  ConsumerState<EditDetail> createState() => _EditDetailState();
}

class _EditDetailState extends ConsumerState<EditDetail> {
  late List<PredefinedOrderModel> predefinedOrderList;
  TextEditingController selectedPOController = TextEditingController();
  late FocusNode _seatsFocusNode;
  late bool isAvailable;

  List<PredefinedOrderModel> listPO = [];
  PredefinedOrderModel? selectedPO = PredefinedOrderModel(
    id: '-1',
    name: 'selectOpenOrder'.tr(),
    isCustom: false,
  );

  Future<List<PredefinedOrderModel>> _fetch() async {
    return await ref
        .read(predefinedOrderProvider.notifier)
        .getListPredefinedOrderWhereOccupied0();
  }

  Future<void> getListPO() async {
    listPO = await _fetch();
    setState(() {});
    if (listPO.isNotEmpty) {
      //filter out used PO

      List<PredefinedOrderModel> toRemove =
          ref.read(tableLayoutProvider).poBank;

      //   prints(toRemove.map((e) => e.name).join(','));
      List<PredefinedOrderModel> currList = listPO;
      currList.removeWhere(
        (element) =>
            toRemove.any((toRemoveItem) => toRemoveItem.id == element.id),
      );

      listPO = currList;

      listPO.insert(
        0,
        PredefinedOrderModel(
          id: '-1',
          isCustom: false,
          name: 'selectOpenOrder'.tr(),
        ),
      );

      selectedPO = listPO[0];

      if (widget.selectedPredefinedOrderId != null) {
        var list = listPO.where(
          (element) => element.id == widget.selectedPredefinedOrderId,
        );
        if (list.isEmpty) {
          selectedPO =
              (await ref
                  .read(predefinedOrderProvider.notifier)
                  .getPredefinedOrderById(widget.selectedPredefinedOrderId))!;
          listPO.insert(1, selectedPO!);
          widget.tablesFormBloc!.predefinedOrder.updateValue(selectedPO!.name!);
        } else {
          selectedPO = list.first;
          selectedPOController.text = selectedPO!.name!;
          widget.tablesFormBloc!.predefinedOrder.updateValue(selectedPO!.name!);
        }
      }
      setState(() {});
    }

    // selectedOutlet = listOutlets.firstWhere((device) => true);
    // if (listOutlets.isNotEmpty) selectedOutlet = listOutlets[0];
  }

  @override
  void initState() {
    super.initState();
    _seatsFocusNode = FocusNode();
    _seatsFocusNode.addListener(_handleFocusChange);
    getListPO();
    isAvailable = widget.isAvailable;
  }

  void _handleFocusChange() {
    if (_seatsFocusNode.hasFocus) {
      ref.read(barcodeScannerProvider.notifier).pauseScannerListener();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        ref.read(barcodeScannerProvider.notifier).resumeScannerListener();
      });
    }
  }

  @override
  void dispose() {
    _seatsFocusNode.removeListener(_handleFocusChange);
    _seatsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutState = ref.watch(tableLayoutProvider);
    final errorMessage = tableLayoutState.errorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'available'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Switch(
              value: isAvailable,
              onChanged:
                  widget.tableStatus == TableStatusEnum.OCCUPIED
                      ? null
                      : (value) {
                        widget.onChangeSwitch(value);
                        setState(() {
                          isAvailable = value;
                        });
                      },
            ),
          ],
        ),
        const SizedBox(height: 10),
        (ref
                .read(tableLayoutProvider.notifier)
                .tableShapeCanEdit(widget.tableModel))
            ? widget.tableStatus == TableStatusEnum.OCCUPIED
                ? TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 106, 106, 106),
                  ),
                  enabled: false,
                  controller: selectedPOController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(44, 214, 214, 214),
                  ),
                )
                : StyledDropdown<PredefinedOrderModel>(
                  items:
                      listPO.map<DropdownMenuItem<PredefinedOrderModel>>((
                        PredefinedOrderModel model,
                      ) {
                        return DropdownMenuItem<PredefinedOrderModel>(
                          value: model, // Set the value to the ID
                          child: Text(
                            model.name.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                  selected: selectedPO,
                  list: listPO,
                  setDropdownValue: (value) {
                    setState(() {
                      selectedPO = listPO.firstWhere(
                        (model) => model.id == value.id,
                      ); // Find the model based on the ID
                      //prints(selectedDivision.id);
                      widget.tablesFormBloc!.predefinedOrder.updateValue(
                        selectedPO!.id!.toString(),
                      );

                      widget.onChangeOpenOrder(selectedPO!);
                    });
                  },
                )
            : SizedBox.shrink(),
        SizedBox(height: errorMessage != '' ? 5 : 0),
        errorMessage != ''
            ? Text(
              errorMessage,
              style: const TextStyle(color: kTextRed),
              textAlign: TextAlign.start,
            )
            : Container(),
        // MyDropdownBlocBuilder(
        //   hint: 'Select Open Order',
        //   label: "Open Order",
        //   selectFieldBloc: widget.tablesFormBloc!.predefinedOrder,
        //   itemBuilder: (_, p1) => FieldItem(child: Text(p1.name!)),
        //   onChanged: (p0) {
        //     widget.onChangeOpenOrder(p0!);
        //   },
        // ),
        SizedBox(height: 15.h),
        (ref
                .read(tableLayoutProvider.notifier)
                .tableShapeCanEdit(widget.tableModel))
            ? TextField(
              focusNode: _seatsFocusNode,
              controller: widget.seatsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: kTextGray),
                  gapPadding: 10,
                ),
                contentPadding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: kTextGray),
                  gapPadding: 10,
                ),
                // we change the seats wording to 'Remarks' in en-json.dart file
                // requested by Hairi 18 November 2025
                labelText: 'seats'.tr(),
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            )
            : SizedBox.shrink(),
        // const SizedBox(height: 10),
      ],
    );
  }
}
