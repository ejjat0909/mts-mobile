import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:super_banners/super_banners.dart';

class Header extends StatelessWidget {
  final String price;
  final String seller;
  final String status;

  const Header({
    super.key,
    required this.price,
    required this.seller,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                price,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Sold By $seller', textAlign: TextAlign.center),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: CornerBanner(
            bannerPosition: CornerBannerPosition.topRight,
            bannerColor: status == 'paid'.tr() ? Colors.green : Colors.red,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
              child: Text(
                status.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
