import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/page/page_list_response_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/domain/repositories/remote/page_repository.dart';

class PageRepositoryImpl implements PageRepository {
  /// Get list of pages

  /// Get list of pages with pagination
  @override
  Resource getPageList(String page) {
    return Resource(
      modelName: PageModel.modelName,
      url: 'pages/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return PageListResponseModel(json.decode(response.body));
      },
    );
  }
}
