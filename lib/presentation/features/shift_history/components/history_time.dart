import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/presentation/common/widgets/no_permission.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/staff/staff_providers.dart';

class HistoryTime extends ConsumerStatefulWidget {
  final ShiftModel shiftModel;

  const HistoryTime({super.key, required this.shiftModel});

  @override
  ConsumerState<HistoryTime> createState() => _HistoryTimeState();
}

class _HistoryTimeState extends ConsumerState<HistoryTime> {
  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermission = permissionNotifier.hasViewShiftReportsPermission();
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      margin: const EdgeInsets.only(left: 200, right: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: kWhiteColor,
      ),
      child:
          hasPermission
              ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text('openedBy'.tr()),
                            FutureBuilder(
                              future: ref
                                  .read(staffProvider.notifier)
                                  .getClosedByAndOpenedBy(
                                    closedBy: widget.shiftModel.closedBy!,
                                    openedBy: widget.shiftModel.openedBy!,
                                  ),
                              builder: (context, snapshot) {
                                String openByName = '';
                                if (snapshot.hasData) {
                                  openByName =
                                      snapshot.data!['openByName'] as String;
                                }
                                return Flexible(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 7.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: canvasColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      openByName,
                                      style: const TextStyle(
                                        color: kWhiteColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // open time
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${DateTimeUtils.getDateFormat(widget.shiftModel.createdAt)} | ${DateTimeUtils.getTimeFormat(widget.shiftModel.createdAt)}',
                          style: AppTheme.normalTextStyle(),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text('closedBy'.tr()),
                            FutureBuilder(
                              future: ref
                                  .read(staffProvider.notifier)
                                  .getClosedByAndOpenedBy(
                                    closedBy: widget.shiftModel.closedBy!,
                                    openedBy: widget.shiftModel.openedBy!,
                                  ),
                              builder: (context, snapshot) {
                                String closeByName = '';
                                if (snapshot.hasData) {
                                  closeByName =
                                      snapshot.data!['closeByName'] as String;
                                }
                                return Flexible(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 7.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: canvasColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      closeByName,
                                      style: const TextStyle(
                                        color: kWhiteColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // close time
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${DateTimeUtils.getDateFormat(widget.shiftModel.closedAt)} | ${DateTimeUtils.getTimeFormat(widget.shiftModel.closedAt)}',
                          style: AppTheme.normalTextStyle(),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : NoPermission(),
    );
  }
}
