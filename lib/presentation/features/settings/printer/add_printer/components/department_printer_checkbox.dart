import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/providers/department_printer/department_printer_providers.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';

class DepartmentPrinterCheckbox extends ConsumerStatefulWidget {
  final Function(List<DepartmentPrinterModel>) onSelectionChanged;
  final List<DepartmentPrinterModel> initialSelectedDepartments;
  final bool isEnabled;

  const DepartmentPrinterCheckbox({
    super.key,
    required this.onSelectionChanged,
    required this.initialSelectedDepartments,
    required this.isEnabled,
  });

  @override
  ConsumerState<DepartmentPrinterCheckbox> createState() =>
      _DepartmentPrinterCheckboxState();
}

class _DepartmentPrinterCheckboxState
    extends ConsumerState<DepartmentPrinterCheckbox> {
  Map<String, bool> selectedDepartments = {};
  List<DepartmentPrinterModel> allDepartments = [];

  @override
  void initState() {
    super.initState();
    prints(widget.initialSelectedDepartments);
    for (DepartmentPrinterModel dp in widget.initialSelectedDepartments) {
      selectedDepartments[dp.id!] = true;
    }
  }

  List<DepartmentPrinterModel> _getSelectedDepartments() {
    return allDepartments
        .where((dept) => selectedDepartments[dept.id] == true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          ref
              .read(departmentPrinterProvider.notifier)
              .getListDepartmentPrinterModel(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          allDepartments = snapshot.data!;
          // initialize any unchecked department as false
          for (DepartmentPrinterModel dp in allDepartments) {
            selectedDepartments.putIfAbsent(dp.id!, () => false);
          }

          return Column(
            children: List.generate(allDepartments.length, (index) {
              DepartmentPrinterModel department = allDepartments[index];
              return Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(department.name ?? 'no name'),
                  value: selectedDepartments[department.id],
                  enableFeedback: true,
                  enabled: widget.isEnabled,
                  visualDensity: const VisualDensity(
                    horizontal: 0.0,
                    vertical: -4.0,
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      selectedDepartments[department.id!] = value ?? false;
                    });
                    widget.onSelectionChanged(_getSelectedDepartments());
                  },
                ),
              );
            }),
          );
        } else {
          return Text('noDepartmentPrinter'.tr());
        }
      },
    );
  }
}
