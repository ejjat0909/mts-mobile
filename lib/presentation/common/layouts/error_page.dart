import 'package:flutter/material.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';

class ErrorPage extends StatelessWidget {
  final String? index;

  const ErrorPage({super.key, this.index});

  @override
  Widget build(BuildContext context) {
    // if (isDebug) {
    //   return Center(child: Text(text));
    // }
    return Center(child: ThemeSpinner.spinner());
  }
}
