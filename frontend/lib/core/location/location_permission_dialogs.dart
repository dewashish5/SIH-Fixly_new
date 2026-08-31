import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme/app_colors.dart';

/// App-themed location permission / settings prompts.
abstract final class LocationPermissionDialogs {
  static Future<bool> showRationale(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.location_on_rounded, color: scheme.primary, size: 36),
          title: Text(
            'Enable location',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          content: Text(
            'Fixly needs your current location to find nearby workers, '
            'set booking addresses, and show live maps.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Not now',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  static Future<bool> showOpenSettings(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(
            Icons.location_disabled_rounded,
            color: AppColors.error,
            size: 36,
          ),
          title: Text(
            'Location blocked',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          content: Text(
            'Location permission is off. Open Settings to enable it for Fixly.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await openAppSettings();
    }
    return result == true;
  }
}
