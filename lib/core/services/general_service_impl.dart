import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/core/services/general_service.dart';
import 'package:mts/presentation/common/dialogs/loading_gif_dialogue.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
import 'package:mts/providers/category_discount/category_discount_providers.dart';
import 'package:mts/providers/category_tax/category_tax_providers.dart';
import 'package:mts/providers/discount_item/discount_item_providers.dart';
import 'package:mts/providers/discount/discount_providers.dart';
import 'package:mts/providers/discount_outlet/discount_outlet_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/feature/feature_providers.dart';
import 'package:mts/providers/item_modifier/item_modifier_providers.dart';
import 'package:mts/providers/item_tax/item_tax_providers.dart';
import 'package:mts/providers/order_option_tax/order_option_tax_providers.dart';
import 'package:mts/providers/outlet_payment_type/outlet_payment_type_providers.dart';
import 'package:mts/providers/outlet_tax/outlet_tax_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';
import 'package:mts/providers/timecard/timecard_providers.dart';
import 'package:path_provider/path_provider.dart';

class DownloadTask {
  final String url;
  final String filePath;
  final DownloadedFileModel downloadedFileModel;
  final int index;

  DownloadTask({
    required this.url,
    required this.filePath,
    required this.downloadedFileModel,
    required this.index,
  });
}

class AsyncImageQueue {
  final int concurrency;
  final Dio dio;
  final DownloadedFileFacade downloadedFileFacade;
  final ValueNotifier<double> progressNotifier;
  final ValueNotifier<String> speedNotifier;
  final int totalUrls;

  int _completedUrls = 0;
  final Stopwatch _stopwatch = Stopwatch();

  AsyncImageQueue({
    required this.concurrency,
    required this.dio,
    required this.downloadedFileFacade,
    required this.progressNotifier,
    required this.speedNotifier,
    required this.totalUrls,
  }) {
    _stopwatch.start();
  }

  Future<void> processQueue(List<DownloadTask> tasks) async {
    final pool = List.generate(concurrency, (_) => Future.value());

    for (final task in tasks) {
      final next = pool.removeAt(0).then((_) => _downloadImage(task));
      pool.add(next);
    }

    await Future.wait(pool);
  }

  Future<void> _downloadImage(DownloadTask task) async {
    try {
      await dio.download(
        Uri.encodeFull(task.url),
        task.filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double singleFileProgress = (received / total);
            double overallProgress =
                (_completedUrls + singleFileProgress) / totalUrls * 100;
            progressNotifier.value = overallProgress;
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
            'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': imageUrlReferer,
          },
        ),
      );

      _completedUrls++;

      final updatedFile = task.downloadedFileModel.copyWith(
        isDownloaded: true,
        updatedAt: DateTime.now(),
      );

      await downloadedFileFacade.upsertBulk([updatedFile]);
    } catch (e) {
      prints('Error downloading ${task.url}: $e');
    }
  }
}

/// Implementation of the General Facade
class GeneralServiceImpl implements GeneralService {
  final PusherDatasource _pusherService;
  final IDatabaseHelpers _db;

  GeneralServiceImpl({
    required PusherDatasource pusherService,
    required IDatabaseHelpers db,
    required SecureStorageApi secureStorageApi,
  }) : _pusherService = pusherService,
       _db = db;

  /// Factory constructor using ServiceLocator for easier migration from static methods
  factory GeneralServiceImpl.fromServiceLocator() {
    return GeneralServiceImpl(
      pusherService: ServiceLocator.get<PusherDatasource>(),
      db: ServiceLocator.get<IDatabaseHelpers>(),
      secureStorageApi: ServiceLocator.get<SecureStorageApi>(),
    );
  }

  // Use for pin input field
  @override
  Future<void> getAllDataFromLocalDb(
    WidgetRef ref,
    BuildContext? context,
    Function(bool) isLoadingCallback, {
    required Function(bool) isDownloadData,
    required bool needDownloadImages,
  }) async {
    isLoadingCallback(true);

    // Map of futures with keys to easily reference the results
    Map<String, Future<dynamic>> futures = {
      'listItemRepresentation':
          _itemRepresentationFacade.getListItemRepresentationModel(),
      'listPageItem': _pageItemFacade.getListPageItemModel(),
      'listItem': _itemFacade.getListItemModel(),
      'listCategories': _categoryFacade.getListCategoryModel(),
      'listPages': _pageFacade.getListPage(),
      'listModifier': _modifierFacade.getListModifierModel(),
      'listItemModifier': _itemModifierFacade.getListItemModifier(),
      'listModifierOption': _modifierOptionFacade.getListModifierOptionModel(),
      'listCustomers': _customerFacade.getListCustomerModel(),
      'listOrderOption': _orderOptionFacade.getListOrderOptionModel(),
      'listReceiptModel': _receiptFacade.getListReceiptModel(),
      'listTax': _taxFacade.getListTaxModel(),
      'listItemTax': _itemTaxFacade.getListitemTax(),
      'listDiscount': _discountFacade.getListDiscountModel(),
      'listReceiptItems': _receiptItemFacade.getListReceiptItems(),
      'listUser': _userFacade.getListUserModels(),
      'listSaleModel': _saleFacade.getListSaleModel(),
      'listStaff': _staffFacade.getListStaffModel(),
      'listPrinter': _printerSettingFacade.getListPrinterSetting(),
      'listDevice': _deviceFacade.getListDevicesFromLocalDB(),
      'listOutlet': _outletFacade.getListOutletsFromLocalDB(),
      'listDownloadedFiles': _downloadedFileFacade.getListDownloadedFile(),
      'listTableSections': _tableSectionFacade.getTableSections(),
      'listTable': _tableFacade.getTables(),
      'listDiscountItem': _discountItemFacade.getListDiscountItem(),
      'listPermission': _permissionFacade.getListPermissions(),
      'listCashManagement': _cashManagementFacade.getListCashManagementModel(),
      'listPaymentTypes': _paymentTypeFacade.getListPaymentType(),
      'listSaleItems': _saleItemFacade.getListSaleItem(),
      'listSaleModifiers': _saleModifierFacade.getListSaleModifierModel(),
      'listSaleModifierOptions':
          _saleModifierOptionFacade.getListSaleModifierOption(),
      'listSaleVariantOptions':
          _saleVariantOptionFacade.getListSaleVariantOption(),
      'listShifts': _shiftFacade.getListShiftModel(),
      'listFeatures': _featureFacade.getListFeatures(),
      'listCategoryTaxes': _categoryTaxFacade.getListCategoryTaxModel(),
      'listCategoryDiscounts':
          _categoryDiscountFacade.getListCategoryDiscount(),
      'listOrderOptionTaxes': _orderOptionTaxFacade.getListOrderOptionTax(),
      'listOutletTaxes': _outletTaxFacade.getListOutletTaxModel(),
      'listDiscountOutlets': _discountOutletFacade.getListDiscountOutlet(),
      'listOutletPaymentTypes':
          _outletPaymentTypeFacade.getListOutletPaymentTypeModel(),
      'listPredefinedOrders': _predefinedOrderFacade.getListPredefinedOrder(),
      'listDepartmentPrinters':
          _departmentPrinterFacade.getListDepartmentPrinter(),
      'listReceiptSettings': _receiptSettingsFacade.getListReceiptSettings(),
      'listTimecards': _timecardFacade.getListTimeCard(),
      'latestSlideshow': _slideshowFacade.getLatestModel(),
      'listFeatureCompanies': _featureCompanyFacade.getListFeatureCompanies(),
      'listPendingChanges': _pendingChangesFacade.getListPendingChangesModel(),
    };

    // Execute all the futures concurrently
    final results = await Future.wait(futures.values);

    // Create a map to easily access the results by their keys
    final resultMap = Map.fromIterables(futures.keys, results);

    // tak perlu sebab pusheehr still running while pin lock, if terminated, it will auto trigger sync
    // await _itemRepresentationFacade.upsertBulk(
    //   resultMap['listItemRepresentation'],
    // );

    List<PageModel> listPages = resultMap['listPages'];
    // prints(listPages.map((p) => p.id).toList());
    if (listPages.isNotEmpty) {
      // set current page for page
      ref.read(pageItemProvider.notifier).setCurrentPageId(listPages.first.id!);
      ref.read(pageItemProvider.notifier).setLastPageId(listPages.first.id!);
    }
    // set page item
    // ServiceLocator.get<PageItemNotifier>().addOrUpdateListPageItem(
    //   resultMap['listPageItem'],
    // );

    // await _itemFacade.upsertBulk(resultMap['listItem']);

    // ServiceLocator.get<ModifierNotifier>().addOrUpdateList(
    //   resultMap['listModifier'],
    // );
    // set also to saleItemsProvider list modifier
    ref
        .read(saleItemProvider.notifier)
        .addOrUpdateModifierList(resultMap['listModifier']);
    ref
        .read(itemModifierProvider.notifier)
        .upsertBulk(resultMap['listItemModifier']);

    // ServiceLocator.get<ModifierOptionNotifier>().addOrUpdateList(
    //   resultMap['listModifierOption'],
    // );
    // set also to saleItemsProvider list modifier option
    ref
        .read(saleItemProvider.notifier)
        .addOrUpdateModifierOptionList(resultMap['listModifierOption']);

    // ServiceLocator.get<CustomerNotifier>().addOrUpdateList(
    //   resultMap['listCustomers'],
    // );

    // ServiceLocator.get<OrderOptionNotifier>().addOrUpdateList(
    //   resultMap['listOrderOption'],
    // );
    List<OrderOptionModel> listOrderOption =
        (resultMap['listOrderOption'] as List<OrderOptionModel>?) ?? [];
    if (listOrderOption.isNotEmpty) {
      ref
          .read(saleItemProvider.notifier)
          .setOrderOptionModel(listOrderOption.first);
    }

    ref.read(taxProvider.notifier).addOrUpdateList(resultMap['listTax']);
    ref.read(itemTaxProvider.notifier).upsertBulk(resultMap['listItemTax']);

    ref
        .read(discountProvider.notifier)
        .addOrUpdateList(resultMap['listDiscount']);
    ref
        .read(discountItemProvider.notifier)
        .upsertBulk(resultMap['listDiscountItem']);

    // ServiceLocator.get<UserNotifier>().addOrUpdateList(resultMap['listUser']);

    // ServiceLocator.get<StaffNotifier>().addOrUpdateList(resultMap['listStaff']);

    // ServiceLocator.get<OutletNotifier>().addOrUpdateList(
    //   resultMap['listOutlet'],
    // );

    // ServiceLocator.get<DeviceNotifier>().addOrUpdateList(
    //   resultMap['listDevice'],
    // );

    ref
        .read(tableLayoutProvider.notifier)
        .addOrUpdateListTable(resultMap['listTable']);

    ref
        .read(tableLayoutProvider.notifier)
        .addOrUpdateListSections(resultMap['listTableSections']);

    // set permission list
    // ServiceLocator.get<PermissionNotifier>().addOrUpdateList(
    //   resultMap['listPermission'],
    // );

    // Set downloaded files in the notifier

    // Set cash management list
    ref
        .read(cashManagementProvider.notifier)
        .addOrUpdateList(resultMap['listCashManagement']);

    // Set payment types list

    // Set sale items list
    // ServiceLocator.get<SaleItemNotifier>().setListSaleItems(
    //   resultMap['listSaleItems'],
    // );

    // Set sale modifiers list

    // Set sale modifier options list

    // Set sale variant options list

    // Set shifts list
    // ServiceLocator.get<ShiftNotifier>().setListShift(
    //   resultMap['listShifts'],
    // );

    // Set features list
    ref
        .read(featureProvider.notifier)
        .addOrUpdateList(resultMap['listFeatures']);

    // Set category taxes list
    ref
        .read(categoryTaxProvider.notifier)
        .upsertBulk(resultMap['listCategoryTaxes']);

    // Set category discounts list
    ref
        .read(categoryDiscountProvider.notifier)
        .upsertBulk(resultMap['listCategoryDiscounts']);

    // Set order option taxes list
    ref
        .read(orderOptionTaxProvider.notifier)
        .upsertBulk(resultMap['listOrderOptionTaxes']);

    // Set outlet taxes list
    ref
        .read(outletTaxProvider.notifier)
        .addOrUpdateList(resultMap['listOutletTaxes']);

    // Set discount outlets list
    ref
        .read(discountOutletProvider.notifier)
        .upsertBulk(resultMap['listDiscountOutlets']);

    // Set outlet payment types list
    ref
        .read(outletPaymentTypeProvider.notifier)
        .addOrUpdateList(resultMap['listOutletPaymentTypes']);

    // Set predefined orders list
    // ServiceLocator.get<PredefinedOrderNotifier>().addOrUpdateList(
    //   resultMap['listPredefinedOrders'],
    // );

    // Set department printers list
    // ServiceLocator.get<DepartmentPrinterNotifier>().addOrUpdateList(
    //   resultMap['listDepartmentPrinters'],
    // );

    // Set timecards list
    ref
        .read(timecardProvider.notifier)
        .addOrUpdateList(resultMap['listTimecards']);

    // Set slideshow data
    ref
        .read(slideshowProvider.notifier)
        .addOrUpdateList(
          resultMap['latestSlideshow'] != null
              ? SlideshowModel.fromJson(resultMap['latestSlideshow'])
              : null,
        );

    // Set feature companies list
    ref
        .read(featureCompanyProvider.notifier)
        .addOrUpdateList(resultMap['listFeatureCompanies']);

    // Set pending changes list
    // ServiceLocator.get<PendingChangesNotifier>().setListPendingChanges(
    //   resultMap['listPendingChanges'],
    // );

    // Set printing logs list

    isLoadingCallback(false);
    if (needDownloadImages) {
      await downloadImages(context, isDownloadData);
      // await _itemRepresentationFacade.upsertBulk(
      //   resultMap['listItemRepresentation'],
      // );
    }
  }

  @override
  Future<void> downloadImages(
    BuildContext? context,
    Function(bool) onDownload,
  ) async {
    ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
    ValueNotifier<String> speedNotifier = ValueNotifier<String>('0 B/s');
    ValueNotifier<String> errorNotifier = ValueNotifier<String>('');
    onDownload(true);
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return LoadingGifDialogue(
            gifPath: 'assets/images/play-download.gif',
            loadingText: 'downloadData'.tr(),
            progressNotifier: progressNotifier,
            speedNotifier: speedNotifier,
            errorNotifier: errorNotifier,
          );
        },
      );
    }

    Timer? timer;
    int lastReceived = 0;
    Stopwatch stopwatch = Stopwatch()..start();

    List<DownloadedFileModel> listUpdatedDownloadedFiles = [];

    List<DownloadedFileModel> listDownloadedFiles =
        await _downloadedFileFacade.getListDownloadedFile();

    Dio dio = Dio();
    var directory =
        Platform.isAndroid
            ? await getDownloadsDirectory()
            : await getApplicationDocumentsDirectory();

    directory ??= await getApplicationDocumentsDirectory();

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final downloadedFilesHaveUrl =
        listDownloadedFiles
            .where((df) => df.url != null && !df.isDownloaded!)
            .toList();

    if (downloadedFilesHaveUrl.isEmpty) {
      onDownload(false);
      return;
    }
    int totalUrls = downloadedFilesHaveUrl.length;

    for (DownloadedFileModel df in downloadedFilesHaveUrl) {
      DownloadedFileModel updatedDf = df.copyWith(
        updatedAt: DateTime.now(),
        path:
            df.fileName != null
                ? '${directory.path}/${DownloadedFileModel.modelName}/${df.fileName}'
                : '${directory.path}/${DownloadedFileModel.modelName}/${FormatUtils.getFileNameFromUrl(df.url!)}',
      );

      listUpdatedDownloadedFiles.add(updatedDf);
    }

    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (stopwatch.elapsedMilliseconds > 0) {
        double bytesPerSecond = lastReceived / 1;
        speedNotifier.value = FormatUtils.formatSpeed(
          bytesPerSecond.toDouble(),
        );
        lastReceived = 0;
        stopwatch.reset();
      }
    });

    final downloadTasks = <DownloadTask>[];
    for (int i = 0; i < listUpdatedDownloadedFiles.length; i++) {
      if (listUpdatedDownloadedFiles[i].url != null &&
          listUpdatedDownloadedFiles[i].path != null) {
        downloadTasks.add(
          DownloadTask(
            url: listUpdatedDownloadedFiles[i].url!,
            filePath: listUpdatedDownloadedFiles[i].path!,
            downloadedFileModel: listUpdatedDownloadedFiles[i],
            index: i,
          ),
        );
      }
    }

    final asyncQueue = AsyncImageQueue(
      concurrency: 3,
      dio: dio,
      downloadedFileFacade: _downloadedFileFacade,
      progressNotifier: progressNotifier,
      speedNotifier: speedNotifier,
      totalUrls: totalUrls,
    );

    try {
      await asyncQueue.processQueue(downloadTasks);
    } catch (e) {
      prints('Error in download queue: $e');
    }

    prints('Images downloaded successfully!');

    if (context != null) {
      NavigationUtils.pop(context);
    }
    onDownload(false);

    timer.cancel();
    stopwatch.stop();
  }

  @override
  Future<void> deleteDatabaseProcess() async {
    await _db.dropDb();
  }

  @override
  Future<bool> initializePusher(String shiftId) async {
    //  final secureStorage = ServiceLocator.get<SecureStorageApi>();
    String? channelName = shiftId.isNotEmpty ? 'private-shift-$shiftId' : null;
    // await secureStorage.saveObject('channelName', channelName);
    // prints("Pusher Channel: $channelName");
    // prints("Pusher Key: $pusherKey");
    // prints("Pusher Cluster: $pusherCluster");

    // Save pusher config
    if (shiftId.isNotEmpty && channelName != null) {
      await _pusherService.savePusherConfig(
        apiKey: pusherKey,
        cluster: pusherCluster,
        channelName: channelName,
      );

      // Initialize pusher
      return await _pusherService.initPusher(
        apiKey: pusherKey,
        cluster: pusherCluster,
        channelName: channelName,
      );
    } else {
      return false;
    }
  }

  @override
  Future<void> subscribePusher() async {
    ShiftModel shiftModel = await _shiftFacade.getLatestShift();
    await initializePusher(shiftModel.id ?? '');
  }
}
