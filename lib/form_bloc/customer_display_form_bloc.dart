import 'dart:async';

import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/validation_utils.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';

class CustomerDisplayFormBloc extends FormBloc<Map<String, dynamic>, String> {
  SlideshowModel? sdModel;
  final SlideshowNotifier slideshowNotifier;

  final title = TextFieldBloc(validators: [ValidationUtils.validateRequired]);

  final description = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final greeting = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final feedbackDescription = TextFieldBloc(
    validators: [ValidationUtils.validateRequired],
  );

  final promotionLink = TextFieldBloc(validators: []);

  CustomerDisplayFormBloc(this.sdModel, this.slideshowNotifier) {
    if (sdModel!.id != null) {
      title.updateInitialValue(sdModel!.title ?? '');
      description.updateInitialValue(sdModel!.description ?? '');
      greeting.updateInitialValue(sdModel!.greetings ?? '');
      feedbackDescription.updateInitialValue(
        sdModel!.feedbackDescription ?? '',
      );
      promotionLink.updateInitialValue(sdModel!.promotionlink ?? '');
    } else {
      prints("SEKARANG NIN ULL");
    }
    addFieldBlocs(
      fieldBlocs: [
        description,
        title,
        greeting,
        feedbackDescription,
        promotionLink,
      ],
    );
  }

  @override
  Future<void> onSubmitting() async {
    prints('onSubmitting CUSTOMER');
    OutletModel outletModel = ServiceLocator.get<OutletModel>();
    SlideshowModel sdm = await slideshowNotifier.getModelById(
      sdModel?.id ?? '',
    );

    try {
      SlideshowModel newSdModel =
          sdm.id != null
              ? sdm.copyWith(
                title: title.value,
                description: description.value,
                greetings: greeting.value,
                feedbackDescription: feedbackDescription.value,
                promotionlink: promotionLink.value,
                outletId: outletModel.id!,
              )
              : SlideshowModel(
                id: IdUtils.generateUUID(),
                title: title.value,
                description: description.value,
                greetings: greeting.value,
                feedbackDescription: feedbackDescription.value,
                promotionlink: promotionLink.value,
                outletId: outletModel.id!,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                images: [],
                downloadUrls: [],
              );

      bool isSuccess = await slideshowNotifier.insertBulk([newSdModel]);
      if (isSuccess) {
        emitSuccess(
          successResponse: {'message': 'Save successfull', 'data': newSdModel},
          canSubmitAgain: true,
        );

        title.updateValue(title.value);
        description.updateValue(description.value);
        greeting.updateValue(greeting.value);
        feedbackDescription.updateValue(feedbackDescription.value);
        promotionLink.updateValue(promotionLink.value);
      } else {
        emitFailure(failureResponse: 'Failure to save data');
      }
    } catch (e) {
      emitFailure(failureResponse: e.toString());
    }
  }
}
