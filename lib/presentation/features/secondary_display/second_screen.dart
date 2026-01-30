import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final SecondaryDisplayService _showSecondaryDisplayFacade =
      ServiceLocator.get<SecondaryDisplayService>();

  @override
  Widget build(BuildContext context) {
    // prints("height : ${MediaQuery.of(context).size.height}");
    // prints("width : ${MediaQuery.of(context).size.width}");
    return ScreenUtilInit(
      designSize: const Size(850, 530),
      builder: (context, child) {
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          navigatorKey: _showSecondaryDisplayFacade.navigatorKey,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case MainCustomerDisplay.routeName:
                    return const MainCustomerDisplay();

                  case CustomerShowReceipt.routeName:
                    return const CustomerShowReceipt();

                  // case CustomerFeedback.routeName:
                  //   return const CustomerFeedback();

                  default:
                    return const MainCustomerDisplay();
                }
              },
            );
          },
        );
      },
    );
  }
}
