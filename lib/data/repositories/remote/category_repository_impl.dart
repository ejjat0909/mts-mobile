import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/category/category_list_response_model.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/services/remote_pagination_service.dart';
import 'package:mts/domain/repositories/remote/category_repository.dart';
import 'package:mts/providers/core/core_providers.dart';
import 'package:mts/providers/services/service_providers.dart';

/// ================================
/// Provider for Remote Repository
/// ================================
final categoryRemoteRepoProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    webService: ref.read(webServiceProvider),
    paginationService: ref.read(remotePaginationServiceProvider),
  );
});

/// Implementation of the Remote Category Repository
class CategoryRepositoryImpl implements CategoryRepository {
  final RemotePaginationService _paginationService;

  CategoryRepositoryImpl({
    required IWebService webService,
    required RemotePaginationService paginationService,
  }) : _paginationService = paginationService;

  /// Get list of categories with pagination
  ///
  /// This method returns a Resource object that can be used to fetch
  /// categories from the API with pagination.
  ///
  /// @param page The page number to fetch
  @override
  Resource getCategoryList(String page) {
    return Resource(
      modelName: CategoryModel.modelName,
      url: 'categories/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CategoryListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Fetch all categories from all pages
  ///
  /// This method handles pagination internally and returns all records.
  /// Follows Clean Architecture: repository layer owns data fetching logic.
  @override
  Future<List<CategoryModel>> fetchAllPaginated() async {
    return await _paginationService
        .fetchAllPaginated<CategoryModel, CategoryListResponseModel>(
          getPagedResource: (page) => getCategoryList(page),
          extractData: (response) => response.data,
          extractPaginator: (response) => response.paginator,
          extractMessage: (response) => response.message,
          checkSuccess: (response) => response.isSuccess,
          entityName: CategoryModel.modelName,
        );
  }
}
