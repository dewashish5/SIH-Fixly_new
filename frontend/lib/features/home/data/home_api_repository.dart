import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/models.dart';

class HomeBundle {
  const HomeBundle({
    required this.categories,
    required this.topServices,
  });

  final List<ServiceCategory> categories;
  final List<ServiceItem> topServices;
}

class HomeApiRepository {
  HomeApiRepository({ApiClient? client})
      : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<HomeBundle> fetchHome() async {
    final res = await _api.get('/api/home/home');
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Home failed');
    }
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return HomeBundle(
      categories: _mapCategoryList(data['categories']),
      topServices: _mapServiceList(data['topServices']),
    );
  }

  Future<Map<String, List<ServiceItem>>> fetchCategoriesMap() async {
    final res = await _api.get('/api/home/categories');
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Categories failed');
    }
    final raw = res['categories'];
    if (raw is! Map) return {};
    final out = <String, List<ServiceItem>>{};
    raw.forEach((key, value) {
      final list = value is List ? value : const [];
      out[key.toString()] = list
          .whereType<Map>()
          .map((e) => mapService(Map<String, dynamic>.from(e)))
          .toList();
    });
    return out;
  }

  Future<List<ServiceCategory>> fetchCategories() async {
    final map = await fetchCategoriesMap();
    if (map.isEmpty) return ServiceCategories.all;
    return map.keys.map(_categoryFromKey).toList();
  }

  Future<List<ServiceItem>> fetchAllServices() async {
    final map = await fetchCategoriesMap();
    return map.values.expand((e) => e).toList();
  }

  Future<ServiceItem> fetchService(String serviceId) async {
    final res = await _api.get('/api/home/services/$serviceId');
    if (res['success'] != true || res['service'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Service not found');
    }
    return mapService(Map<String, dynamic>.from(res['service'] as Map));
  }

  static ServiceItem mapService(Map<String, dynamic> json) {
    final included = json['whatsIncluded'];
    final desc = included is List && included.isNotEmpty
        ? included.map((e) => e.toString()).join(', ')
        : (json['estimatedTime']?.toString() ?? '');
    final price = (json['basePrice'] as num?)?.toDouble() ?? 0;
    return ServiceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      categoryId: (json['category'] ?? '').toString(),
      title: (json['title'] as String?) ?? 'Service',
      description: desc,
      priceFrom: price,
      rating: 4.5,
    );
  }

  static List<ServiceItem> _mapServiceList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => mapService(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<ServiceCategory> _mapCategoryList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          final id = (e['id'] ?? e['_id'] ?? e['name'] ?? '').toString();
          return _categoryFromKey(id.isEmpty ? 'other' : id);
        }
        return _categoryFromKey(e.toString());
      }).toList();
    }
    if (raw is Map) {
      return raw.keys.map((k) => _categoryFromKey(k.toString())).toList();
    }
    return ServiceCategories.all;
  }

  static ServiceCategory _categoryFromKey(String key) {
    final normalized = key.toLowerCase();
    for (final c in ServiceCategories.all) {
      if (c.id == normalized ||
          c.nameEn.toLowerCase().startsWith(normalized) ||
          normalized.contains(c.id) ||
          // backend typo "plumer"
          (normalized.startsWith('plum') && c.id == 'plumber')) {
        return c;
      }
    }
    return ServiceCategory(
      id: key,
      nameEn: _titleCase(key),
      nameHi: _titleCase(key),
      gradient: AppColors.primaryGradient,
      icon: Icons.handyman_rounded,
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
