import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/presentation/features/settings/printer/list_printer/list_printer_screen.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';

class PrinterScreen extends ConsumerWidget {
  const PrinterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigator = ref.watch(myNavigatorProvider);
    switch (navigator.selectedTab) {
      default:
        return const ListPrinterScreen();
    }
  }
}
