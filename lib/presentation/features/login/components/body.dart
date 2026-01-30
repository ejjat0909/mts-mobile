import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mts/presentation/features/login/components/login_form.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: LoginForm(),
      ),
    );
  }
}
