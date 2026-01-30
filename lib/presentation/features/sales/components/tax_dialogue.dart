import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/sales/components/tax_item.dart';

import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';

class TaxDialogue extends ConsumerStatefulWidget {
  const TaxDialogue({super.key});

  @override
  ConsumerState<TaxDialogue> createState() => _TaxDialogueState();
}

class _TaxDialogueState extends ConsumerState<TaxDialogue> {
  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 1.5,
          maxWidth: availableWidth / 1.5,
        ),
        child: Column(
          children: [
            const Space(10),
            AppBar(
              elevation: 0,
              backgroundColor: white,
              title: Row(
                children: [Text('tax'.tr(), style: AppTheme.h1TextStyle())],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: canvasColor),
                onPressed: () {
                  NavigationUtils.pop(context);
                  ref
                      .read(dialogNavigatorProvider.notifier)
                      .setPageIndex(DialogNavigatorEnum.reset);
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    final taxlist = ref.watch(taxProvider).items;
                    if (taxlist.isNotEmpty) {
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, // Number of items per row
                              crossAxisSpacing: 10, // Horizontal spacing
                              mainAxisSpacing: 10, // Vertical spacing
                              childAspectRatio: 1.5,
                            ),
                        itemCount: taxlist.length,
                        itemBuilder: (context, index) {
                          return TaxItem(
                            // onPressed: () {
                            //   NavigationUtils.pop(context);
                            //   context.read<SaleItemNotifier>().setSalesDiscount(
                            //       dummyListDiscount[index].value ?? 0);
                            // },
                            isSelected: index == 6,
                            taxModel: taxlist[index],
                          );
                        },
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              FontAwesomeIcons.tag,
                              color: kTextGray,
                              size: 50,
                            ),
                            Space(20.h),
                            Text(
                              'taxNotAvailable'.tr(),
                              style: AppTheme.mediumTextStyle(
                                color: kTextGray.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
