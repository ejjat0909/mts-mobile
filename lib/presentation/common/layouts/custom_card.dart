import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCard extends StatelessWidget {
  final String? title;
  final Widget body;

  const CustomCard({super.key, this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: -4,
              blurRadius: 20,
              offset: const Offset(0, 9), // changes position of shadow
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title != null
                ? Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 5),
                  child: Text(title!, style: const TextStyle(fontSize: 17)),
                )
                : const SizedBox(),
            title != null ? const Divider() : const SizedBox(),
            Flexible(
              child: body,
              // child: body,
            ),
          ],
        ),
      ),
    );
  }
}
