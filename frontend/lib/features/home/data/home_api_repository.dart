import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
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

  Future<HomeBundle> fetchHome({bool forceNetwork = false}) async {
    final res = await _api.get(ApiEndpoints.home, forceNetwork: forceNetwork);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Home failed');
    }
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final topServices = _mapServiceList(data['topServices']);

    List<ServiceCategory> categories = const [];
    try {
      categories = await fetchCategories();
    } catch (_) {
      categories = _mapCategoryList(data['categories'], topServices);
    }

    return HomeBundle(
      categories: categories,
      topServices: topServices,
    );
  }

  Future<Map<String, List<ServiceItem>>> fetchCategoriesMap() async {
    final res = await _api.get(ApiEndpoints.categories);
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
    if (map.isEmpty) return const [];
    final list = <ServiceCategory>[];
    map.forEach((key, services) {
      String? imageUrl;
      for (final s in services) {
        if (s.imageUrl != null && s.imageUrl!.trim().isNotEmpty) {
          imageUrl = s.imageUrl;
          break;
        }
      }
      list.add(_categoryFromKey(key, imageUrl: imageUrl));
    });
    return list;
  }

  Future<List<ServiceItem>> fetchAllServices() async {
    final map = await fetchCategoriesMap();
    return map.values.expand((e) => e).toList();
  }

  Future<ServiceItem> fetchService(String serviceId) async {
    final res = await _api.get(ApiEndpoints.serviceById(serviceId));
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
      imageUrl: (json['image'] ?? json['imageUrl'])?.toString(),
      estimatedTime: json['estimatedTime']?.toString(),
      whatsIncluded: included is List
          ? included.map((e) => e.toString()).toList()
          : const [],
      isActive: json['isActive'] != false,
    );
  }

  static List<ServiceItem> _mapServiceList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => mapService(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<ServiceCategory> _mapCategoryList(
    dynamic raw, [
    List<ServiceItem> services = const [],
  ]) {
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          final id = (e['category'] ?? e['id'] ?? e['_id'] ?? e['name'] ?? '').toString();
          final img = (e['image'] ?? e['imageUrl'])?.toString();
          return _categoryFromKey(id.isEmpty ? 'other' : id, imageUrl: img);
        }
        final key = e.toString();
        String? imageUrl;
        for (final s in services) {
          if (s.categoryId.toLowerCase() == key.toLowerCase() &&
              s.imageUrl != null &&
              s.imageUrl!.isNotEmpty) {
            imageUrl = s.imageUrl;
            break;
          }
        }
        return _categoryFromKey(key, imageUrl: imageUrl);
      }).toList();
    }
    if (raw is Map) {
      return raw.keys.map((k) => _categoryFromKey(k.toString())).toList();
    }
    return const [];
  }

  static ServiceCategory _categoryFromKey(String key, {String? imageUrl}) {
    final normalized = key.toLowerCase().trim();
    for (final c in ServiceCategories.all) {
      if (c.id == normalized ||
          c.nameEn.toLowerCase() == normalized ||
          c.nameEn.toLowerCase().startsWith(normalized) ||
          normalized.contains(c.id) ||
          // backend typo "plumer"
          (normalized.startsWith('plum') && c.id == 'plumber')) {
        return ServiceCategory(
          id: c.id,
          nameEn: c.nameEn,
          nameHi: c.nameHi,
          gradient: c.gradient,
          icon: c.icon,
          imageUrl: imageUrl ?? c.imageUrl,
        );
      }
    }
    return ServiceCategory(
      id: key,
      nameEn: _titleCase(key),
      nameHi: _titleCase(key),
      gradient: AppColors.primaryGradient,
      icon: Icons.handyman_rounded,
      imageUrl: imageUrl,
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
