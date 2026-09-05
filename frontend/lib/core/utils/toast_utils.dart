import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static void showToast({
    required BuildContext context,
    required String message,
    ToastificationType type = ToastificationType.info,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      type: type,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    showToast(
      context: context,
      message: message,
      type: ToastificationType.success,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
  }) {
    showToast(
      context: context,
      message: message,
      type: ToastificationType.error,
    );
  }
}
