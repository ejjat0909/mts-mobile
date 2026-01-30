import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_providers.dart';
import 'package:mts/providers/item/item_providers.dart';

class PageSearchBody extends ConsumerStatefulWidget {
  const PageSearchBody({
    super.key,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.context,
  });

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final BuildContext context;

  @override
  ConsumerState<PageSearchBody> createState() => _PageSearchBodyState();
}

class _PageSearchBodyState extends ConsumerState<PageSearchBody> {
  @override
  Widget build(BuildContext context) {
    final itemState = ref.watch(itemProvider);
    final downloadedFileNotifier = ref.watch(downloadedFileProvider.notifier);

    List<ItemModel> itemList =
        ref.read(itemProvider.notifier).getItemModelsByName();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount, // Number of items per row
            crossAxisSpacing: widget.crossAxisSpacing, // Horizontal spacing
            mainAxisSpacing: widget.mainAxisSpacing, // Vertical spacing
            childAspectRatio:
                MediaQuery.of(context).size.height *
                0.175 /
                100, // dont change this value
          ),
          itemCount: itemList.length,
          itemBuilder: (context, index) {
            // get item model

            final itemModel = itemList[index];
            final itemRepresentationModel = itemState.itemRepresentations
                .firstWhere(
                  (element) => element.id == itemModel.itemRepresentationId!,
                  orElse: () => ItemRepresentationModel(),
                );

            final downloadedFileModel = downloadedFileNotifier
                .getListDownloadedFilesFromHive()
                .firstWhere(
                  (element) =>
                      element.url == itemRepresentationModel.downloadUrl,
                  orElse: () => DownloadedFileModel(),
                );

            return MenuItem(
              itemModel: itemModel,
              index: index,
              itemRepresentationModel: itemRepresentationModel,
              downloadedFileModel: downloadedFileModel,
            );
          },
        ),
      ),
    );
  }
}
