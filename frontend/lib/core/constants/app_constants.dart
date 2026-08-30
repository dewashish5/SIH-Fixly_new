import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

abstract final class AppConstants {
  static const appName = 'Fixly';
  static const mockOtp = '123456';
  static const mockDelayMs = 200;
  static const onboardingTotalSteps = 3;
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
      gradient: AppColors.primaryGradient,
      icon: Icons.bolt_rounded,
    ),
    ServiceCategory(
      id: 'plumber',
      nameEn: 'Plumber',
      nameHi: 'प्लंबर',
      gradient: [AppColors.primaryDark, AppColors.primary],
      icon: Icons.plumbing_rounded,
    ),
    ServiceCategory(
      id: 'carpenter',
      nameEn: 'Carpenter',
      nameHi: 'बढ़ई',
      gradient: [AppColors.primary600, AppColors.primary300],
      icon: Icons.carpenter_rounded,
    ),
    ServiceCategory(
      id: 'painter',
      nameEn: 'Painter',
      nameHi: 'पेंटर',
      gradient: [AppColors.primary, AppColors.primary200],
      icon: Icons.format_paint_rounded,
    ),
    ServiceCategory(
      id: 'gardener',
      nameEn: 'Gardener',
      nameHi: 'माली',
      gradient: [AppColors.primaryDark, AppColors.primary400],
      icon: Icons.yard_rounded,
    ),
    ServiceCategory(
      id: 'domestic_helper',
      nameEn: 'Domestic Helper',
      nameHi: 'घरेलू सहायक',
      gradient: [AppColors.primary800, AppColors.primary],
      icon: Icons.home_work_rounded,
    ),
    ServiceCategory(
      id: 'caregiving',
      nameEn: 'Caregiving',
      nameHi: 'देखभाल',
      gradient: [AppColors.primary600, AppColors.primary300],
      icon: Icons.favorite_rounded,
    ),
    ServiceCategory(
      id: 'driver',
      nameEn: 'Driver',
      nameHi: 'ड्राइवर',
      gradient: [AppColors.primaryDark, AppColors.primary300],
      icon: Icons.directions_car_rounded,
    ),
    ServiceCategory(
      id: 'technician',
      nameEn: 'Technician',
      nameHi: 'तकनीशियन',
      gradient: [AppColors.primary800, AppColors.primary400],
      icon: Icons.build_circle_rounded,
    ),
    ServiceCategory(
      id: 'cleaning',
      nameEn: 'Cleaning',
      nameHi: 'सफाई',
      gradient: [AppColors.primary, AppColors.primary100],
      icon: Icons.cleaning_services_rounded,
    ),
  ];
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.gradient,
    required this.icon,
  });

  final String id;
  final String nameEn;
  final String nameHi;
  final List<Color> gradient;
  final IconData icon;

  String nameFor(String locale) => locale == 'hi' ? nameHi : nameEn;
}
