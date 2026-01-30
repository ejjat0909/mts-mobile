import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/services/hive_inspector.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'hive_box_details_page.dart';

class HiveListPage extends StatefulWidget {
  const HiveListPage({super.key});

  @override
  State<HiveListPage> createState() => _HiveListPageState();
}

class _HiveListPageState extends State<HiveListPage> {
  late Future<Map<String, dynamic>> _boxesFuture;

  @override
  void initState() {
    super.initState();
    _boxesFuture = HiveInspector.inspectAllBoxes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => NavigationUtils.pop(context),
        ),
        title: const Text(
          'Hive Inspector - Box List',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _boxesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading boxes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _boxesFuture = HiveInspector.inspectAllBoxes();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final boxesData = snapshot.data ?? {};
          final boxes = boxesData.entries.toList();

          if (boxes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64.w,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Hive boxes found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _boxesFuture = HiveInspector.inspectAllBoxes();
              });
              await _boxesFuture;
            },
            child: ListView.builder(
              itemCount: boxes.length,
              padding: EdgeInsets.all(8.w),
              itemBuilder: (context, index) {
                final boxEntry = boxes[index];
                final boxName = boxEntry.key;
                final boxData = boxEntry.value as Map<String, dynamic>;
                final itemCount = boxData['count'] as int? ?? 0;
                final isEmpty = boxData['isEmpty'] as bool? ?? true;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: isEmpty ? Colors.grey[300] : kPrimaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEmpty ? Icons.folder_open : Icons.storage,
                        color: isEmpty ? Colors.grey : Colors.white,
                      ),
                    ),
                    title: Text(
                      boxName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isEmpty
                                ? Colors.grey[200]
                                : kPrimaryLightColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$itemCount items',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isEmpty ? Colors.grey : kPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isEmpty) ...[
                          SizedBox(width: 8.w),
                          Chip(
                            label: const Text(
                              'Empty',
                              style: TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.grey[200],
                          ),
                        ]
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => HiveBoxDetailsPage(
                                  boxName: boxName,
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}