import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom-sheet update gate shown from splash.
///
/// - [isMandatory] true → no Later, cannot dismiss, Update opens store but sheet stays.
/// - [isMandatory] false → Later continues this launch; next cold start shows again.
abstract final class AppUpdateSheet {
  /// `true` = splash may continue. `false` = blocked (force update).
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String updateUrl,
    required bool isMandatory,
    String? currentVersion,
    String? latestVersion,
  }) async {
    final scheme = Theme.of(context).colorScheme;

    if (isMandatory) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return PopScope(
            canPop: false,
            child: _UpdateSheetBody(
              scheme: scheme,
              title: title,
              message: message,
              updateUrl: updateUrl,
              isMandatory: true,
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              onLater: null,
              onUpdated: () async {
                await _openStore(updateUrl);
                // Keep sheet open — user cannot proceed without new install.
              },
            ),
          );
        },
      );
      return false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return PopScope(
          canPop: true,
          child: _UpdateSheetBody(
            scheme: scheme,
            title: title,
            message: message,
            updateUrl: updateUrl,
            isMandatory: false,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            onLater: () => Navigator.of(ctx).pop(true),
            onUpdated: () async {
              await _openStore(updateUrl);
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
          ),
        );
      },
    );
    // Dismiss / Later / Update → continue this session only.
    return result ?? true;
  }

  static Future<void> _openStore(String updateUrl) async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _UpdateSheetBody extends StatelessWidget {
  const _UpdateSheetBody({
    required this.scheme,
    required this.title,
    required this.message,
    required this.updateUrl,
    required this.isMandatory,
    required this.onUpdated,
    this.onLater,
    this.currentVersion,
    this.latestVersion,
  });

  final ColorScheme scheme;
  final String title;
  final String message;
  final String updateUrl;
  final bool isMandatory;
  final Future<void> Function() onUpdated;
  final VoidCallback? onLater;
  final String? currentVersion;
  final String? latestVersion;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.system_update_rounded,
                size: 44,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if ((currentVersion?.isNotEmpty ?? false) ||
                  (latestVersion?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 10),
                Text(
                  [
                    if (currentVersion != null && currentVersion!.isNotEmpty)
                      'Current: v$currentVersion',
                    if (latestVersion != null && latestVersion!.isNotEmpty)
                      'Latest: v$latestVersion',
                  ].join('  ·  '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              if (isMandatory) ...[
                const SizedBox(height: 12),
                Text(
                  'This update is required to continue using Fixly.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => onUpdated(),
                child: const Text('Update'),
              ),
              if (!isMandatory && onLater != null) ...[
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  onPressed: onLater,
                  child: const Text('Later'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias used by older call sites / tests.
typedef AppUpdateDialog = AppUpdateSheet;
