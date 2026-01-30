import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/button_circle_delete.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_secondary.dart';

class TabbedCard extends StatefulWidget {
  final List<Tab> tabs;
  final List<Widget> children;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;
  final double? scrHeight;

  const TabbedCard({
    super.key,
    required this.tabs,
    required this.children,
    this.onSave,
    this.onDelete,
    this.onCancel,
    this.scrHeight,
  });

  @override
  State<TabbedCard> createState() => _TabbedCardState();
}

class _TabbedCardState extends State<TabbedCard> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    double scrHeight = MediaQuery.of(context).size.height - 290.h;

    TabController controller = TabController(
      length: widget.tabs.length,
      vsync: this,
    );
    return Container(
      constraints: BoxConstraints(minHeight: widget.scrHeight ?? scrHeight),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: -4,
                  blurRadius: 35,
                  offset: const Offset(0, 9), // changes position of shadow
                ),
              ],
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    isScrollable: true,
                    labelColor: kPrimaryColor,
                    unselectedLabelColor: kTextGray,
                    controller: controller,
                    tabs: widget.tabs,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: widget.scrHeight ?? scrHeight,
                  child: TabBarView(
                    controller: controller,
                    children: widget.children,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (widget.onSave != null)
            Row(
              children: [
                if (widget.onDelete != null)
                  ButtonCircleDelete(onPressed: widget.onDelete),
                const Spacer(),
                if (widget.onCancel != null)
                  ButtonSecondary(
                    onPressed: widget.onCancel,
                    text: 'cancel'.tr(),
                  ),
                const SizedBox(width: 10),
                if (widget.onSave != null)
                  ButtonPrimary(onPressed: widget.onSave, text: 'save'.tr()),
              ],
            ),
        ],
      ),
    );
  }
}
