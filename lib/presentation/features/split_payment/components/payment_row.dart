import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/button_circle_delete.dart';

class PaymentRow extends StatefulWidget {
  final Function() onPressDelete;
  final int length;
  final TextEditingController inputController;
  final ValueChanged<String> onSelectedChanged;
  final String selectedValue;
  final bool isPaid;
  final ValueChanged<bool> onPressPaid;

  const PaymentRow({
    super.key,
    required this.onPressDelete,
    required this.length,
    required this.inputController,
    required this.onSelectedChanged,
    required this.selectedValue,
    required this.isPaid,
    required this.onPressPaid,
  });

  @override
  State<PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends State<PaymentRow> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: kTextGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: widget.selectedValue,
                  onChanged: (value) {
                    setState(() {
                      widget.onSelectedChanged(value.toString());
                    });
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'cash'.tr(),
                      child: Text('cash'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'card'.tr(),
                      child: Text('card'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'ewallet'.tr(),
                      child: Text('eWallet'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: widget.inputController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: kTextGray),
                  gapPadding: 10,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimaryColor),
                  gapPadding: 10,
                ),
                contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: kTextGray),
                  gapPadding: 10,
                ),
                fillColor: Colors.white,
                filled: true,
                labelStyle: AppTheme.normalTextStyle(color: kTextGray),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: !widget.isPaid ? kPrimaryColor : Colors.green,
              fixedSize: const Size.fromWidth(110),
              backgroundColor: !widget.isPaid ? Colors.white : kBgGreen,
              side: BorderSide(
                color: !widget.isPaid ? kPrimaryColor : Colors.transparent,
              ),
            ),
            onPressed:
                () => setState(() {
                  widget.onPressPaid(!widget.isPaid);
                }),
            icon: Icon(!widget.isPaid ? Icons.money : Icons.done),
            label: Text(!widget.isPaid ? 'charge'.tr() : 'paid'.tr()),
          ),
          ButtonCircleDelete(
            onPressed: () {
              widget.onPressDelete();
              widget.inputController.clear();
              if (widget.length == 1) {
                widget.onSelectedChanged('cash'.tr());
                widget.onPressPaid(false);
              }
            },
          ),
        ],
      ),
    );
  }
}
