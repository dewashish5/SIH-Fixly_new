import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:transit_kit/transit_kit.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/constants/map_token_loader.dart';
import '../../../../core/location/location_service.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const wordmarkAsset = 'assets/splash_wordmark.png';
  static const _animDuration = Duration(milliseconds: 500);
  static const _minVisible = Duration(milliseconds: 1200);
  static const _maxWait = Duration(milliseconds: 2000);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    TransitRegistry.of(TransitType.fade);
    _controller = AnimationController(
      vsync: this,
      duration: SplashPage._animDuration,
    );
    final fadeFromZero = defaultTargetPlatform == TargetPlatform.android;
    _fade = Tween<double>(begin: fadeFromZero ? 0 : 1, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (!mounted) return;

    await precacheImage(
      const AssetImage(SplashPage.wordmarkAsset),
      context,
    );
    if (!mounted) return;

    FlutterNativeSplash.remove();
    _controller.forward();

    final maps = _initMaps();

    await Future.wait([
      Future<void>.delayed(SplashPage._minVisible),
      maps.timeout(SplashPage._maxWait, onTimeout: () {}),
    ]);

    if (mounted) {
      await LocationService.instance.ensureOnAppOpen(context);
    }

    if (!mounted) return;

    final cubit = context.read<AppSessionCubit>();
    // Wait for refresh-token → /me (started early from App bootstrap).
    await cubit.restoreSession();
    if (!mounted) return;

    final session = cubit.state;
    if (!session.languageSelected) {
      context.go(RouteNames.language);
      return;
    }
    if (session.status == AppSessionStatus.authenticated) {
      context.go(cubit.postAuthRoute());
      return;
    }
    context.go(RouteNames.login);
  }

  Future<void> _initMaps() async {
    try {
      await MapTokenLoader.configure();
      if (MapConstants.hasToken) {
        MapboxOptions.setAccessToken(MapConstants.accessToken);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final decodeWidth = (width * 0.86 * dpr).round().clamp(400, 1000);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  SplashPage.wordmarkAsset,
                  width: width * 0.82,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  cacheWidth: decodeWidth,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
