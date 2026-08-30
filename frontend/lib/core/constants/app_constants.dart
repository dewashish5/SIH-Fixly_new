import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const appName = 'Fixly';
  static const mockOtp = '123456';
  static const mockDelayMs = 200;
  static const onboardingTotalSteps = 9;
  static const transitionDurationMs = 250;
}

abstract final class AppImages {
  static const demoSelfie =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&q=80';
}

abstract final class ServiceCategories {
  static const all = [
    ServiceCategory(
      id: 'electrician',
      nameEn: 'Electrician',
      nameHi: 'इलेक्ट्रीशियन',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/electrical.png',
      gradient: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      fallbackIcon: Icons.bolt_rounded,
    ),
    ServiceCategory(
      id: 'plumber',
      nameEn: 'Plumber',
      nameHi: 'प्लंबर',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/plumber.png',
      gradient: [Color(0xFF0891B2), Color(0xFF22D3EE)],
      fallbackIcon: Icons.plumbing_rounded,
    ),
    ServiceCategory(
      id: 'carpenter',
      nameEn: 'Carpenter',
      nameHi: 'बढ़ई',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/wood.png',
      gradient: [Color(0xFFB45309), Color(0xFFF59E0B)],
      fallbackIcon: Icons.carpenter_rounded,
    ),
    ServiceCategory(
      id: 'painter',
      nameEn: 'Painter',
      nameHi: 'पेंटर',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/paint-bucket.png',
      gradient: [Color(0xFFDB2777), Color(0xFFF472B6)],
      fallbackIcon: Icons.format_paint_rounded,
    ),
    ServiceCategory(
      id: 'gardener',
      nameEn: 'Gardener',
      nameHi: 'माली',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/flower-delivery.png',
      gradient: [Color(0xFF059669), Color(0xFF34D399)],
      fallbackIcon: Icons.yard_rounded,
    ),
    ServiceCategory(
      id: 'domestic_helper',
      nameEn: 'Domestic Helper',
      nameHi: 'घरेलू सहायक',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/home.png',
      gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      fallbackIcon: Icons.home_work_rounded,
    ),
    ServiceCategory(
      id: 'caregiving',
      nameEn: 'Caregiving',
      nameHi: 'देखभाल',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/heart-with-pulse.png',
      gradient: [Color(0xFFE11D48), Color(0xFFFB7185)],
      fallbackIcon: Icons.favorite_rounded,
    ),
    ServiceCategory(
      id: 'driver',
      nameEn: 'Driver',
      nameHi: 'ड्राइवर',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/car.png',
      gradient: [Color(0xFF4338CA), Color(0xFF818CF8)],
      fallbackIcon: Icons.directions_car_rounded,
    ),
    ServiceCategory(
      id: 'technician',
      nameEn: 'Technician',
      nameHi: 'तकनीशियन',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/maintenance.png',
      gradient: [Color(0xFF475569), Color(0xFF94A3B8)],
      fallbackIcon: Icons.build_circle_rounded,
    ),
    ServiceCategory(
      id: 'cleaning',
      nameEn: 'Cleaning',
      nameHi: 'सफाई',
      imageUrl: 'https://img.icons8.com/3d-fluency/94/broom.png',
      gradient: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
      fallbackIcon: Icons.cleaning_services_rounded,
    ),
  ];
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.imageUrl,
    required this.gradient,
    required this.fallbackIcon,
  });

  final String id;
  final String nameEn;
  final String nameHi;
  final String imageUrl;
  final List<Color> gradient;
  final IconData fallbackIcon;

  String nameFor(String locale) => locale == 'hi' ? nameHi : nameEn;
}
