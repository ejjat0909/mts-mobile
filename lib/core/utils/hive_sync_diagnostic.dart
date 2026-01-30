// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:mts/core/services/hive_init_helper.dart';
// import 'package:mts/core/services/hive_sync_helper.dart';
// import 'package:mts/core/utils/log_utils.dart';
// import 'package:mts/data/models/sale/sale_model.dart';
// import 'package:mts/data/models/sale_item/sale_item_model.dart';
// import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
// import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';

// /// Diagnostic helper to verify Hive sync is working correctly
// ///
// /// Usage:
// /// ```dart
// /// await HiveSyncDiagnostic.runFullDiagnostic();
// /// ```
// class HiveSyncDiagnostic {
//   /// Run complete diagnostic check for Hive sync
//   static Future<void> runFullDiagnostic() async {
//     await LogUtils.info('🔍 Starting Hive Sync Diagnostic...');

//     try {
//       // Check 1: Verify Hive is initialized
//       await _checkHiveInitialization();

//       // Check 2: Verify sync helper is running
//       await _checkSyncHelperStatus();

//       // Check 3: Verify boxes are open
//       await _checkHiveBoxes();

//       // Check 4: Test queueing
//       await _testQueueing();

//       // Check 5: Monitor sync for 2 seconds
//       await _monitorSync();

//       await LogUtils.info('✅ Hive Sync Diagnostic Complete!');
//     } catch (e) {
//       await LogUtils.error('❌ Diagnostic failed', e);
//     }
//   }

//   /// Check if Hive is properly initialized
//   static Future<void> _checkHiveInitialization() async {
//     await LogUtils.info('📦 Check 1: Hive Initialization');

//     try {
//       final stats = await HiveInitHelper.getCacheStatistics();
//       final totalSize = await HiveInitHelper.getTotalCacheSize();

//       await LogUtils.info('  ✅ Hive initialized');
//       await LogUtils.info('  📊 Cache statistics: $stats');
//       await LogUtils.info('  📊 Total cache size: $totalSize items');
//     } catch (e) {
//       await LogUtils.error('  ❌ Hive initialization check failed', e);
//     }
//   }

//   /// Check if sync helper is running
//   static Future<void> _checkSyncHelperStatus() async {
//     await LogUtils.info('🔄 Check 2: Sync Helper Status');

//     try {
//       final stats = await HiveSyncHelper().getSyncStatistics();

//       if (stats['isRunning'] == true) {
//         await LogUtils.info('  ✅ Sync helper is RUNNING');
//       } else {
//         await LogUtils.warning('  ⚠️ Sync helper is NOT running');
//       }

//       await LogUtils.info('  📊 Sync stats: $stats');
//     } catch (e) {
//       await LogUtils.error('  ❌ Sync helper check failed', e);
//     }
//   }

//   /// Check if key boxes are open
//   static Future<void> _checkHiveBoxes() async {
//     await LogUtils.info('📁 Check 3: Hive Boxes Status');

//     final boxNames = [
//       SaleModel.modelBoxName,
//       SaleItemModel.modelBoxName,
//       SaleModifierModel.modelBoxName,
//       SaleModifierOptionModel.modelBoxName,
//     ];

//     for (final boxName in boxNames) {
//       try {
//         final isOpen = HiveInitHelper.isBoxOpen(boxName);
//         if (isOpen) {
//           final box = Hive.box<Map>(boxName);
//           await LogUtils.info('  ✅ $boxName: OPEN (${box.length} items)');
//         } else {
//           await LogUtils.warning('  ❌ $boxName: CLOSED');
//         }
//       } catch (e) {
//         await LogUtils.error('  ❌ Error checking box $boxName', e);
//       }
//     }
//   }

//   /// Test the queue mechanism
//   static Future<void> _testQueueing() async {
//     await LogUtils.info('📤 Check 4: Queue Mechanism Test');

//     try {
//       // Queue a test item
//       final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';

//       await LogUtils.info('  Queuing test item: $testId');
//       HiveSyncHelper().queueSync(SaleModel.modelBoxName, testId);

//       // Check queue status
//       final stats = await HiveSyncHelper().getSyncStatistics();

//       if (stats['totalQueued'] != null && stats['totalQueued'] > 0) {
//         await LogUtils.info('  ✅ Queue mechanism working (${stats['totalQueued']} items queued)');
//       } else {
//         await LogUtils.warning('  ⚠️ Items queued but may not be processed yet');
//       }
//     } catch (e) {
//       await LogUtils.error('  ❌ Queue test failed', e);
//     }
//   }

//   /// Monitor sync activity for 2 seconds
//   static Future<void> _monitorSync() async {
//     await LogUtils.info('⏱️ Check 5: Monitoring Sync Activity (2s)');

//     try {
//       const monitorDuration = Duration(seconds: 2);
//       final startTime = DateTime.now();

//       while (DateTime.now().difference(startTime) < monitorDuration) {
//         final stats = await HiveSyncHelper().getSyncStatistics();

//         await LogUtils.debug(
//           '  [${DateTime.now().toIso8601String()}] '
//           'Queue: ${stats['totalQueued']}, '
//           'Synced: ${stats['totalSynced']}'
//         );

//         await Future.delayed(const Duration(milliseconds: 500));
//       }

//       final finalStats = await HiveSyncHelper().getSyncStatistics();
//       await LogUtils.info('  ✅ Final sync stats: $finalStats');
//     } catch (e) {
//       await LogUtils.error('  ❌ Monitoring failed', e);
//     }
//   }

//   /// Test write to Hive and verify queueing
//   static Future<void> testHiveWriteAndSync() async {
//     await LogUtils.info('🧪 Running Hive Write & Sync Test...');

//     try {
//       // 1. Write to Hive
//       final testSaleId = 'test_sale_${DateTime.now().millisecondsSinceEpoch}';
//       final testData = {
//         'id': testSaleId,
//         'outlet_id': 'test_outlet',
//         'staff_id': 'test_staff',
//         'table_id': null,
//         'customer_id': null,
//         'charged_at': DateTime.now().toIso8601String(),
//         'remarks': 'Diagnostic test',
//         'total_price': 0.0,
//         'running_number': 0,
//       };

//       final box = Hive.box<Map>(SaleModel.modelBoxName);
//       await box.put(testSaleId, testData);

//       await LogUtils.info('✅ Wrote test data to Hive: $testSaleId');

//       // 2. Queue for sync
//       HiveSyncHelper().queueSync(SaleModel.modelBoxName, testSaleId);
//       await LogUtils.info('✅ Queued for sync: $testSaleId');

//       // 3. Wait for sync
//       await Future.delayed(const Duration(seconds: 1));

//       // 4. Check stats
//       final stats = await HiveSyncHelper().getSyncStatistics();
//       await LogUtils.info('✅ Sync stats after 1s: $stats');

//       await LogUtils.info('✅ Test Complete!');
//     } catch (e) {
//       await LogUtils.error('❌ Test failed', e);
//     }
//   }
// }
