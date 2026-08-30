import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app/app.dart';
import 'core/constants/map_constants.dart';
import 'core/constants/map_token_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MapTokenLoader.configure();
  if (MapConstants.hasToken) {
    MapboxOptions.setAccessToken(MapConstants.accessToken);
  }
  runApp(App());
}
