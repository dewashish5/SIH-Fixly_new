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
    this.banners = const [],
  });

  final List<ServiceCategory> categories;
  final List<ServiceItem> topServices;
  final List<CouponBanner> banners;
}

class HomeApiRepository {
  HomeApiRepository({ApiClient? client})
      : _api = client ?? ApiServices.client;

  final ApiClient _api;

  static const List<CouponBanner> defaultBanners = [
    CouponBanner(
      id: 'ban_1',
      title: 'Flat 50% Off First Booking',
      code: 'FIXLY50',
      discount: '50% OFF',
      description: 'Get 50% discount up to ₹150 on your first home service',
      gradientColors: ['#1E3A8A', '#3B82F6'],
    ),
    CouponBanner(
      id: 'ban_2',
      title: 'AC & Appliance Mega Saver',
      code: 'COOL20',
      discount: '20% OFF',
      description: 'Save up to ₹250 on all AC & appliance repair bookings',
      gradientColors: ['#047857', '#10B981'],
    ),
    CouponBanner(
      id: 'ban_3',
      title: 'Super Weekend Special',
      code: 'WEEKEND100',
      discount: '₹100 FLAT',
      description: 'Flat ₹100 instant cash discount on electrician & plumber orders',
      gradientColors: ['#7C2D12', '#EA580C'],
    ),
  ];

  Future<List<CouponBanner>> fetchBanners() async {
    try {
      final res = await _api.get(ApiEndpoints.banners);
      if (res['success'] == true && res['banners'] is List) {
        final list = (res['banners'] as List)
            .whereType<Map>()
            .map((e) => CouponBanner.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return defaultBanners;
  }

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

    List<CouponBanner> banners = defaultBanners;
    if (data['banners'] is List && (data['banners'] as List).isNotEmpty) {
      banners = (data['banners'] as List)
          .whereType<Map>()
          .map((e) => CouponBanner.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      try {
        banners = await fetchBanners();
      } catch (_) {
        banners = defaultBanners;
      }
    }

    return HomeBundle(
      categories: categories,
      topServices: topServices,
      banners: banners,
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
