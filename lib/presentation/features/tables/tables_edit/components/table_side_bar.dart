import 'package:flutter/material.dart';

class TableSideBar extends StatelessWidget {
  final String title;
  final Widget body;

  const TableSideBar({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        // border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1)),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 10,
        //     offset: const Offset(-2, 0),
        //   ),
        // ],
      ),
      child: body,
    );
  }
}
