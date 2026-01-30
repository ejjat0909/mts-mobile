import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/features/cash_management/components/body.dart';
import 'package:mts/presentation/features/home/components/custom_appbar.dart';

class CashManagementScreen extends StatefulWidget {
  final Function() onBackPress;

  const CashManagementScreen({super.key, required this.onBackPress});

  @override
  State<CashManagementScreen> createState() => _CashManagementScreenState();
}

class _CashManagementScreenState extends State<CashManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        leftSidePress: () {
          widget.onBackPress();
          NavigationUtils.pop(context);
        },
        leftSideIcon: FontAwesomeIcons.arrowLeft,
        leftSideTitle: 'payInOut'.tr(),
        rightSideTitle: 'cashManagement'.tr(),
      ),
      body: const Body(),
    );
  }
}
