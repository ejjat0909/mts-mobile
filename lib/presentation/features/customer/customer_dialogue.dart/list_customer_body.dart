import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/features/customer/customer_dialogue.dart/recent_customer_item.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';

class ListCustomerBody extends ConsumerStatefulWidget {
  const ListCustomerBody({super.key});

  @override
  ConsumerState<ListCustomerBody> createState() => _ListCustomerBodyState();
}

class _ListCustomerBodyState extends ConsumerState<ListCustomerBody> {
  List<CustomerModel> filteredCustomers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  void _filterCustomers(BuildContext context, String query) {
    final listCustomersFromDB = ref.read(customerProvider).items;
    setState(() {
      searchQuery = query;
      filteredCustomers =
          listCustomersFromDB
              .where(
                (customer) =>
                    (customer.name?.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ??
                        false) ||
                    (customer.phoneNo?.contains(query) ?? false),
              )
              .toList()
            ..sort(
              (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
                a.updatedAt ?? DateTime(1970),
              ),
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            MyTextFormField(
              labelText: 'search'.tr(),
              hintText: 'search'.tr(),
              leading: Padding(
                padding: EdgeInsets.only(
                  top: 20.h,
                  left: 10.w,
                  right: 10.w,
                  bottom: 20.h,
                ),
                child: const Icon(FontAwesomeIcons.magnifyingGlass, color: kBg),
              ),
              onChanged: (value) {
                _filterCustomers(context, value);
              },
            ),
            const Divider(),
            Text('recentCustomers'.tr(), style: AppTheme.mediumTextStyle()),
            const SizedBox(height: 10),
            Expanded(
              child: Builder(
                builder: (context) {
                  final listCustomers =
                      ref.watch(customerProvider).items..sort(
                        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
                          a.updatedAt ?? DateTime(1970),
                        ),
                      );
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        filteredCustomers.isNotEmpty
                            ? filteredCustomers.length
                            : listCustomers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final filteredList =
                          filteredCustomers.isNotEmpty
                              ? filteredCustomers[index]
                              : listCustomers[index];
                      return RecentCustomerItem(
                        filteredCustomers: filteredList,
                        press: () {
                          // navigate to view customer
                          ref
                              .read(dialogNavigatorProvider.notifier)
                              .setPageIndex(DialogNavigatorEnum.viewCustomer);

                          // assign selected customer
                          ref
                              .read(customerProvider.notifier)
                              .setCurrentCustomerModel(filteredList);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
