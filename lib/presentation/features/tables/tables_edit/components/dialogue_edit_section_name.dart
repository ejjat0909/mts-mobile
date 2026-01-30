import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/button_circle_delete.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_secondary.dart';

class DialogueEditSectionName extends StatefulWidget {
  final Function(String) onSave;
  final Function() onDelete;
  final String currentSectName;

  const DialogueEditSectionName({
    super.key,
    required this.onSave,
    required this.onDelete,
    required this.currentSectName,
  });

  @override
  State<DialogueEditSectionName> createState() =>
      _DialogueEditSectionNameState();
}

class _DialogueEditSectionNameState extends State<DialogueEditSectionName> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('editSectionName'.tr(), style: AppTheme.h1TextStyle()),
              ButtonCircleDelete(onPressed: widget.onDelete),
            ],
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _controller,
            decoration: InputDecoration(
              isDense: true,
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
              contentPadding: const EdgeInsets.fromLTRB(15, 18, 15, 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: kTextGray),
                gapPadding: 10,
              ),
              fillColor: Colors.white,
              filled: true,
              labelStyle: AppTheme.normalTextStyle(color: kTextGray),
              labelText: widget.currentSectName,
              hintText: 'New section name (unchanged)',
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: ButtonSecondary(
                  onPressed: (() => NavigationUtils.pop(context)),
                  text: 'Cancel',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: ButtonPrimary(
                  onPressed: () {
                    widget.onSave(_controller.text);
                    NavigationUtils.pop(context);
                  },
                  text: 'Save',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
