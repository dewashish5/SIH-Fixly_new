import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme/app_colors.dart';
import '../constants/app_strings.dart';

/// App-themed location permission / settings prompts.
abstract final class LocationPermissionDialogs {
  static Future<bool> showRationale(BuildContext context) async {
    final l10n = context.l10n;
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
            l10n.locationEnableTitle,
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          content: Text(
            l10n.locationEnableBody,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.notNow,
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
              child: Text(l10n.allow),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  static Future<bool> showLocationServicesOff(BuildContext context) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.gps_off_rounded, color: scheme.primary, size: 36),
          title: Text(
            l10n.locationServicesOffTitle,
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          content: Text(
            l10n.locationServicesOffBody,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.notNow,
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
              child: Text(l10n.turnOnLocation),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  static Future<bool> showOpenSettings(BuildContext context) async {
    final l10n = context.l10n;
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
            l10n.locationPermissionBlockedTitle,
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          content: Text(
            l10n.locationPermissionBlockedBody,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.notNow,
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
              child: Text(l10n.openSettings),
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
