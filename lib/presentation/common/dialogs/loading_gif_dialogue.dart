import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gif/gif.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class LoadingGifDialogue extends StatefulWidget {
  final String gifPath;
  final String loadingText;
  final ValueNotifier<double>? progressNotifier;
  final ValueNotifier<String>? speedNotifier;
  final ValueNotifier<String>? errorNotifier;

  const LoadingGifDialogue({
    super.key,
    required this.gifPath,
    required this.loadingText,
    this.progressNotifier,
    this.speedNotifier,
    this.errorNotifier,
  });

  @override
  State<LoadingGifDialogue> createState() => _LoadingGifDialogueState();
}

class _LoadingGifDialogueState extends State<LoadingGifDialogue>
    with TickerProviderStateMixin {
  late final GifController gifController;
  final int _fps = 30;

  @override
  void initState() {
    gifController = GifController(vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    gifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false, // Prevent back button from dismissing the dialog
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Do nothing - prevent back button action
        // You could show a message here if needed
      },
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: availableHeight / 2,
            maxWidth: availableWidth / 3.5,
          ),
          child:
              widget.errorNotifier != null
                  ? ValueListenableBuilder<String>(
                    valueListenable: widget.errorNotifier!,
                    builder: (context, error, child) {
                      if (error == '') {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 20,
                              ),
                              child: Column(
                                children: [
                                  widget.progressNotifier == null
                                      ? AnimatedTextKit(
                                        repeatForever: true,
                                        animatedTexts: [
                                          TyperAnimatedText(
                                            widget.loadingText,
                                            textStyle: textStyleMedium(
                                              color: kBlackColor,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${widget.loadingText} ',
                                            style: textStyleMedium(
                                              color: kBlackColor,
                                            ),
                                          ),
                                          ValueListenableBuilder<double>(
                                            valueListenable:
                                                widget.progressNotifier!,
                                            builder: (
                                              context,
                                              progress,
                                              child,
                                            ) {
                                              return Text(
                                                '${progress.toStringAsFixed(0)}%',
                                                style: textStyleMedium(
                                                  color: kBlackColor,
                                                ),
                                              );
                                            },
                                          ),
                                          // const SizedBox(width: 10),
                                          // widget.speedNotifier == null
                                          //     ? Container()
                                          //     : Expanded(
                                          //       child: ValueListenableBuilder<
                                          //         String
                                          //       >(
                                          //         valueListenable:
                                          //             widget.speedNotifier!,
                                          //         builder: (
                                          //           context,
                                          //           speed,
                                          //           child,
                                          //         ) {
                                          //           return Text(
                                          //             ' $speed',
                                          //             style:
                                          //                 AppTheme.mediumTextStyle(
                                          //                   color:
                                          //                       Colors
                                          //                           .blueAccent,
                                          //                 ),
                                          //           );
                                          //         },
                                          //       ),
                                          //     ),
                                        ],
                                      ),
                                  const Space(10),
                                  Gif(
                                    fps: _fps,
                                    autostart: Autostart.loop,
                                    placeholder: (context) => Container(),
                                    image: AssetImage(widget.gifPath),
                                    width: 100,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SelectableText(
                                error,
                                style: AppTheme.mediumTextStyle(
                                  color: kPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: ButtonPrimary(
                                      onPressed: () {
                                        NavigationUtils.pop(context);
                                      },
                                      text: 'OK',
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: ButtonTertiary(
                                      onPressed: () {
                                        NavigationUtils.pop(context);
                                      },
                                      text: 'reportIssue'.tr(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            AnimatedTextKit(
                              repeatForever: true,
                              animatedTexts: [
                                TyperAnimatedText(
                                  widget.loadingText,
                                  textStyle: AppTheme.mediumTextStyle(
                                    color: kBlackColor,
                                  ),
                                ),
                              ],
                            ),
                            const Space(10),
                            Gif(
                              fps: _fps,
                              autostart: Autostart.loop,
                              placeholder: (context) => Container(),
                              image: AssetImage(widget.gifPath),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
