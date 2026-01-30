import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/cash_management/components/pay_in_out_item.dart';

class PayInOutSidebar extends StatelessWidget {
  final List<CashManagementModel> cashManagementList;

  const PayInOutSidebar({super.key, required this.cashManagementList});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2, // Retaining the Expanded widget
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: kPrimaryColor.withValues(alpha: 1),
              width: 0.05,
            ),
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(1, 4),
              blurRadius: 10,
              spreadRadius: 0,
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ],
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Check if the list is empty or not and display accordingly
    if (cashManagementList.isNotEmpty) {
      // Grouping items by date
      Map<String, List<CashManagementModel>> groupedItems = {};
      for (CashManagementModel cmm in cashManagementList) {
        String formattedDate = DateFormat(
          'dd MMMM yyyy',
          'en_US',
        ).format(cmm.createdAt!);
        if (groupedItems[formattedDate] == null) {
          groupedItems[formattedDate] = [];
        }
        groupedItems[formattedDate]!.add(cmm);
      }

      // Sort items within each group by `createdAt` in descending order
      groupedItems.forEach((date, items) {
        items.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      });

      // Sort dates in descending order
      List<String> sortedKeys =
          groupedItems.keys.toList()..sort(
            (a, b) => DateFormat(
              'dd MMMM yyyy',
              'en_US',
            ).parse(b).compareTo(DateFormat('dd MMMM yyyy', 'en_US').parse(a)),
          );

      return listPayInOut(sortedKeys, groupedItems);
    } else {
      return emptyListCMM();
    }
  }

  Column emptyListCMM() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          FontAwesomeIcons.moneyBillWave,
          size: 100,
          color: kTextGray.withValues(alpha: 0.5),
        ),
        const Space(40),
        Text('noPayInOut'.tr(), style: AppTheme.mediumTextStyle()),
      ],
    );
  }

  Widget listPayInOut(
    List<String> sortedKeys,
    Map<String, List<CashManagementModel>> groupedItems,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers:
          sortedKeys.map((date) {
            List<CashManagementModel> items = groupedItems[date]!;
            DateTime dateTime = DateFormat('dd MMMM yyyy', 'en_US').parse(date);
            bool isToday = DateTime.now().difference(dateTime).inDays == 0;
            String displayDate = isToday ? 'Today - $date' : date;

            return SliverStickyHeader(
              header: Container(
                color: kTextGrayOpaque,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  displayDate,
                  style: const TextStyle(
                    color: kWhiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PayInOutItem(cmm: items[index]),
                  childCount: items.length,
                ),
              ),
            );
          }).toList(),
    );
  }
}
