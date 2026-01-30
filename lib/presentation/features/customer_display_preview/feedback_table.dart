import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';

class FeedbackTable extends StatefulWidget {
  final Map<Object?, Object?>? acceptedData;

  const FeedbackTable({super.key, required this.acceptedData});

  @override
  State<FeedbackTable> createState() => _FeedbackTableState();
}

class _FeedbackTableState extends State<FeedbackTable> {
  String totalPaid = '0.00';
  String change = '0.00';

  void getData(Map<Object?, Object?>? data) {
    if (data == null) return;

    final map = Map.fromEntries(
      data.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final paid = map[DataEnum.totalPaid];
    if (paid is num) {
      totalPaid = paid.toStringAsFixed(2);
    }

    final changeAmount = map[DataEnum.change];
    if (changeAmount is num) {
      change = changeAmount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    getData(widget.acceptedData);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(children: [buildTop(), const Divider(), buildBottom()]),
      ),
    );
  }

  Widget buildTop() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade300, size: 100),
          Text(
            'thankYou'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              decoration: TextDecoration.none,
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String getFeedback() {
    final rawMap = widget.acceptedData;

    if (rawMap == null) return '';

    // Convert keys to String
    final map = Map.fromEntries(
      rawMap.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final slideshowData = map[DataEnum.slideshow];
    if (slideshowData is Map) {
      final json = Map<String, dynamic>.from(slideshowData);
      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.feedbackDescription ?? '';
    }

    return '';
  }

  Widget buildBottom() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    color: Colors.white,
    child: Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          getFeedback(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            decoration: TextDecoration.none,
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.normal,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey.shade100,
                        ),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        height: 40,
                        child: Text(
                          //"Total Paid",
                          'totalPaid'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        FormatUtils.formatNumber(totalPaid),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey.shade100,
                        ),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        height: 40,
                        child: Text(
                          //"Change",
                          'change'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        FormatUtils.formatNumber(change),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      getPromotionLink(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String getPromotionLink() {
    final rawMap = widget.acceptedData;

    if (rawMap == null) return '';

    // Convert to Map<String, dynamic> safely
    final map = Map.fromEntries(
      rawMap.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final slideshowData = map[DataEnum.slideshow];
    if (slideshowData is Map) {
      final json = Map<String, dynamic>.from(slideshowData);
      final sdModel = SlideshowModel.fromJson(json);
      return sdModel.promotionlink ?? '';
    }

    return '';
  }
}
