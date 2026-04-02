import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/categories/models/category_model.dart';

class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get('/api/v1/enums/categories');
    final items = response['items'];

    if (items is List) {
      return items
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}