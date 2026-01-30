import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';

class TableContent extends StatefulWidget {
  final Widget body;
  final Widget? rightAction;
  final bool darkMode;
  final String title;
  final void Function()? onBackPressed;
  final void Function()? onMenuPressed;
  final void Function()? onTextPressed;

  const TableContent({
    super.key,
    required this.body,
    this.onMenuPressed,
    this.onBackPressed,
    required this.title,
    required this.rightAction,
    this.darkMode = false,
    this.onTextPressed,
  });

  @override
  State<TableContent> createState() => _TableContentState();
}

class _TableContentState extends State<TableContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.darkMode ? kHeader : Colors.white,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.5),
        //     spreadRadius: 5,
        //     blurRadius: 7,
        //     offset: Offset(0, 3), // changes position of shadow
        //   ),
        // ],
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(widget.darkMode ? 0 : 20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(32.0)),
                child: Material(
                  shadowColor: Colors.transparent,
                  color: Colors.transparent,
                  child:
                      widget.onMenuPressed != null
                          ? IconButton(
                            icon: Icon(
                              Icons.menu,
                              color:
                                  widget.darkMode ? Colors.white : Colors.black,
                            ),
                            onPressed: widget.onMenuPressed,
                          )
                          : IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color:
                                  widget.darkMode ? Colors.white : Colors.black,
                            ),
                            onPressed: widget.onBackPressed,
                          ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.darkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              widget.rightAction != null
                  ? widget.rightAction!
                  : const SizedBox(),
            ],
          ),
          const Divider(height: 1),
          Expanded(flex: 2, child: Container(child: widget.body)),
        ],
      ),
    );
  }
}
