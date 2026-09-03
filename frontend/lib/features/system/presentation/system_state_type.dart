import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';

enum SystemStateType {
  noOrders,
  noWorkersNearby,
  noEarnings,
  noNotifications,
  noSearchResults,
  noInternet,
  gpsDenied,
  cameraDenied,
  otpFailed,
  paymentFailed,
  bookingFailed,
  kycFailed,
  serverError,
  sessionExpired,
  timeoutError,
  accountSuspended,
  bookingConfirmed,
  paymentSuccessful,
  kycSubmitted,
  profileUpdated,
  ratingSubmitted,
  complaintSubmitted,
}

extension SystemStateTypeX on SystemStateType {
  static SystemStateType? fromPath(String value) {
    try {
      return SystemStateType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }

  String localizedTitle(AppStrings l10n) {
    switch (this) {
      case SystemStateType.noOrders:
        return l10n.noOrdersYet;
      case SystemStateType.noWorkersNearby:
        return l10n.noWorkersNearby;
      case SystemStateType.noEarnings:
        return l10n.noEarningsYet;
      case SystemStateType.noNotifications:
        return l10n.noNotificationsTitle;
      case SystemStateType.noSearchResults:
        return l10n.noResultsFound;
      case SystemStateType.noInternet:
        return l10n.noInternet;
      case SystemStateType.gpsDenied:
        return l10n.locationDenied;
      case SystemStateType.cameraDenied:
        return l10n.cameraDenied;
      case SystemStateType.otpFailed:
        return l10n.otpFailed;
      case SystemStateType.paymentFailed:
        return l10n.paymentFailed;
      case SystemStateType.bookingFailed:
        return l10n.bookingFailed;
      case SystemStateType.kycFailed:
        return l10n.kycFailed;
      case SystemStateType.serverError:
        return l10n.serverError;
      case SystemStateType.sessionExpired:
        return l10n.sessionExpired;
      case SystemStateType.bookingConfirmed:
        return l10n.bookingConfirmed;
      case SystemStateType.paymentSuccessful:
        return l10n.paymentSuccessful;
      case SystemStateType.kycSubmitted:
        return l10n.kycSubmitted;
      case SystemStateType.profileUpdated:
        return l10n.profileUpdated;
      case SystemStateType.ratingSubmitted:
        return l10n.ratingSubmitted;
      case SystemStateType.complaintSubmitted:
        return l10n.complaintSubmitted;
      default:
        return title;
    }
  }

  String localizedAction(AppStrings l10n) {
    switch (this) {
      case SystemStateType.noOrders:
      case SystemStateType.noEarnings:
        return l10n.dashboard;
      case SystemStateType.noWorkersNearby:
        return l10n.serviceArea;
      case SystemStateType.noNotifications:
      case SystemStateType.ratingSubmitted:
        return l10n.navHome;
      case SystemStateType.noSearchResults:
        return l10n.categories;
      case SystemStateType.sessionExpired:
        return l10n.login;
      case SystemStateType.bookingConfirmed:
        return l10n.liveTracking;
      case SystemStateType.kycSubmitted:
        return l10n.kycStatus;
      case SystemStateType.profileUpdated:
        return l10n.profile;
      case SystemStateType.complaintSubmitted:
        return l10n.supportChat;
      case SystemStateType.noInternet:
      case SystemStateType.serverError:
      case SystemStateType.otpFailed:
      case SystemStateType.paymentFailed:
      case SystemStateType.bookingFailed:
      case SystemStateType.timeoutError:
        return l10n.t('Retry', 'पुनः प्रयास');
      case SystemStateType.gpsDenied:
      case SystemStateType.cameraDenied:
        return l10n.t('Open settings', 'सेटिंग्स खोलें');
      case SystemStateType.kycFailed:
        return l10n.t('Re-upload documents', 'दस्तावेज़ फिर अपलोड करें');
      case SystemStateType.accountSuspended:
        return l10n.support;
      case SystemStateType.paymentSuccessful:
        return l10n.t('View receipt', 'रसीद देखें');
    }
  }

  String get title {
    switch (this) {
      case SystemStateType.noOrders:
        return 'No orders yet';
      case SystemStateType.noWorkersNearby:
        return 'No workers nearby';
      case SystemStateType.noEarnings:
        return 'No earnings yet';
      case SystemStateType.noNotifications:
        return 'No notifications';
      case SystemStateType.noSearchResults:
        return 'No results found';
      case SystemStateType.noInternet:
        return 'No internet connection';
      case SystemStateType.gpsDenied:
        return 'Location access denied';
      case SystemStateType.cameraDenied:
        return 'Camera access denied';
      case SystemStateType.otpFailed:
        return 'OTP verification failed';
      case SystemStateType.paymentFailed:
        return 'Payment failed';
      case SystemStateType.bookingFailed:
        return 'Booking failed';
      case SystemStateType.kycFailed:
        return 'Verification failed';
      case SystemStateType.serverError:
        return 'Something went wrong';
      case SystemStateType.sessionExpired:
        return 'Session expired';
      case SystemStateType.timeoutError:
        return 'Request timed out';
      case SystemStateType.accountSuspended:
        return 'Account suspended';
      case SystemStateType.bookingConfirmed:
        return 'Booking confirmed';
      case SystemStateType.paymentSuccessful:
        return 'Payment successful';
      case SystemStateType.kycSubmitted:
        return 'Application submitted';
      case SystemStateType.profileUpdated:
        return 'Profile updated';
      case SystemStateType.ratingSubmitted:
        return 'Rating submitted';
      case SystemStateType.complaintSubmitted:
        return 'Complaint submitted';
    }
  }

  String get message {
    switch (this) {
      case SystemStateType.noOrders:
        return 'When customers book your services, orders will appear here.';
      case SystemStateType.noWorkersNearby:
        return 'Try expanding your service area or check back later.';
      case SystemStateType.noEarnings:
        return 'Complete jobs to start earning with the cooperative.';
      case SystemStateType.noNotifications:
        return 'You are all caught up. New alerts will show here.';
      case SystemStateType.noSearchResults:
        return 'Try a different keyword or browse categories.';
      case SystemStateType.noInternet:
        return 'Check your connection and try again.';
      case SystemStateType.gpsDenied:
        return 'Enable location to find nearby jobs and navigate.';
      case SystemStateType.cameraDenied:
        return 'Allow camera access for selfie and document verification.';
      case SystemStateType.otpFailed:
        return 'The OTP entered is incorrect. Please try again.';
      case SystemStateType.paymentFailed:
        return 'Your payment could not be processed. No amount was charged.';
      case SystemStateType.bookingFailed:
        return 'We could not complete your booking. Please retry.';
      case SystemStateType.kycFailed:
        return 'Your documents could not be verified. Re-upload and retry.';
      case SystemStateType.serverError:
        return 'Our servers are temporarily unavailable. Please try again.';
      case SystemStateType.sessionExpired:
        return 'Please log in again to continue.';
      case SystemStateType.timeoutError:
        return 'The request took too long. Check connection and retry.';
      case SystemStateType.accountSuspended:
        return 'Contact cooperative support to restore your account.';
      case SystemStateType.bookingConfirmed:
        return 'Your service booking has been confirmed.';
      case SystemStateType.paymentSuccessful:
        return 'Payment received. Receipt saved to your history.';
      case SystemStateType.kycSubmitted:
        return 'Documents submitted. Review usually takes 24–48 hours.';
      case SystemStateType.profileUpdated:
        return 'Your profile changes have been saved.';
      case SystemStateType.ratingSubmitted:
        return 'Thank you for your feedback.';
      case SystemStateType.complaintSubmitted:
        return 'Our support team will respond within 24 hours.';
    }
  }

  IconData get icon {
    switch (this) {
      case SystemStateType.noOrders:
      case SystemStateType.noEarnings:
      case SystemStateType.noNotifications:
      case SystemStateType.noSearchResults:
      case SystemStateType.noWorkersNearby:
        return Icons.inbox_outlined;
      case SystemStateType.noInternet:
      case SystemStateType.serverError:
        return Icons.cloud_off_outlined;
      case SystemStateType.gpsDenied:
        return Icons.location_off_outlined;
      case SystemStateType.cameraDenied:
        return Icons.no_photography_outlined;
      case SystemStateType.otpFailed:
      case SystemStateType.paymentFailed:
      case SystemStateType.bookingFailed:
      case SystemStateType.kycFailed:
      case SystemStateType.sessionExpired:
      case SystemStateType.timeoutError:
      case SystemStateType.accountSuspended:
        return Icons.error_outline;
      case SystemStateType.bookingConfirmed:
      case SystemStateType.paymentSuccessful:
      case SystemStateType.kycSubmitted:
      case SystemStateType.profileUpdated:
      case SystemStateType.ratingSubmitted:
      case SystemStateType.complaintSubmitted:
        return Icons.check_circle_outline;
    }
  }

  Color get accentColor {
    switch (this) {
      case SystemStateType.bookingConfirmed:
      case SystemStateType.paymentSuccessful:
      case SystemStateType.kycSubmitted:
      case SystemStateType.profileUpdated:
      case SystemStateType.ratingSubmitted:
      case SystemStateType.complaintSubmitted:
        return AppColors.success;
      case SystemStateType.noInternet:
      case SystemStateType.gpsDenied:
      case SystemStateType.cameraDenied:
      case SystemStateType.otpFailed:
      case SystemStateType.paymentFailed:
      case SystemStateType.bookingFailed:
      case SystemStateType.kycFailed:
      case SystemStateType.serverError:
      case SystemStateType.sessionExpired:
      case SystemStateType.timeoutError:
      case SystemStateType.accountSuspended:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String get primaryActionLabel {
    switch (this) {
      case SystemStateType.noOrders:
        return 'Go to dashboard';
      case SystemStateType.noWorkersNearby:
        return 'Expand service area';
      case SystemStateType.noEarnings:
        return 'View job feed';
      case SystemStateType.noNotifications:
        return 'Back to home';
      case SystemStateType.noSearchResults:
        return 'Browse categories';
      case SystemStateType.noInternet:
      case SystemStateType.serverError:
        return 'Retry';
      case SystemStateType.gpsDenied:
      case SystemStateType.cameraDenied:
        return 'Open settings';
      case SystemStateType.otpFailed:
        return 'Try again';
      case SystemStateType.paymentFailed:
      case SystemStateType.bookingFailed:
        return 'Retry payment';
      case SystemStateType.kycFailed:
        return 'Re-upload documents';
      case SystemStateType.sessionExpired:
        return 'Log in again';
      case SystemStateType.timeoutError:
        return 'Retry';
      case SystemStateType.accountSuspended:
        return 'Contact support';
      case SystemStateType.bookingConfirmed:
        return 'Track booking';
      case SystemStateType.paymentSuccessful:
        return 'View receipt';
      case SystemStateType.kycSubmitted:
        return 'Check status';
      case SystemStateType.profileUpdated:
        return 'View profile';
      case SystemStateType.ratingSubmitted:
        return 'Back to home';
      case SystemStateType.complaintSubmitted:
        return 'View tickets';
    }
  }

  bool get isSuccess {
    switch (this) {
      case SystemStateType.bookingConfirmed:
      case SystemStateType.paymentSuccessful:
      case SystemStateType.kycSubmitted:
      case SystemStateType.profileUpdated:
      case SystemStateType.ratingSubmitted:
      case SystemStateType.complaintSubmitted:
        return true;
      default:
        return false;
    }
  }
}
