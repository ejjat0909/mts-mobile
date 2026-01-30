import 'package:flutter/material.dart';

class Body extends StatefulWidget {
  final String email;

  const Body({super.key, required this.email});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // InputNewPassword(email: widget.email)
            ],
          ),
        ),
      ),
    );
  }
}
