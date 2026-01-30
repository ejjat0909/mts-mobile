import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';

part 'department_printer_state.freezed.dart';

/// Immutable state class for DepartmentPrinter domain using Freezed
@freezed
class DepartmentPrinterState with _$DepartmentPrinterState {
  const factory DepartmentPrinterState({
    @Default([]) List<DepartmentPrinterModel> items,
    @Default([]) List<DepartmentPrinterModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _DepartmentPrinterState;
}
