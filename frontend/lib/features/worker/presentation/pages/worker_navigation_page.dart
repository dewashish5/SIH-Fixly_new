import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/fixly_map_view.dart';

class WorkerNavigationPage extends StatelessWidget {
  const WorkerNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dest = MapConstants.current;
    final address =
        AppLocation.instance.addressLabel ?? 'Current customer location';
    return AppScaffold(
      title: l10n.navigation,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FixlyMapView(
                expand: true,
                borderRadius: BorderRadius.circular(20),
                center: dest,
                zoom: MapConstants.navigationZoom,
                routeEnd: dest,
                routeStart: MapConstants.workerApproachStart,
                routeProgress: 0.35,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              dest == null
                                  ? 'Waiting for GPS…'
                                  : 'Live route to customer',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: l10n.startNavigation,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.navigationStarted)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
