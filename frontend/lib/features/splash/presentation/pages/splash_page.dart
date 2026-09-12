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
import '../../../../core/network/app_version_api.dart';
import '../../../../core/permissions/app_permissions_service.dart';
import '../../../../core/utils/app_package_info.dart';
import '../../../../core/widgets/app_update_dialog.dart';
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

    // After splash branding: ask every runtime permission (customer + worker).
    if (mounted) {
      await AppPermissionsService.instance.requestAllAfterSplash(context);
    }

    if (!mounted) return;

    // Backend Redis/Mongo version gate — block navigate on force update.
    final canContinue = await _checkAppVersion();
    if (!mounted || !canContinue) return;

    final cubit = context.read<AppSessionCubit>();
    // Same restore started in App bootstrap — no second refresh-token /me.
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

  /// `true` = proceed. Network errors fail open (guide: continue on error).
  Future<bool> _checkAppVersion() async {
    try {
      final check = await AppVersionApi.check();
      if (!check.isUpdateAvailable) return true;
      if (!mounted) return false;
      return await AppUpdateSheet.show(
        context: context,
        title: check.updateTitle,
        message: check.updateMessage,
        updateUrl: check.updateUrl,
        isMandatory: check.forceUpdate,
        currentVersion: check.clientAppVersion.isNotEmpty
            ? check.clientAppVersion
            : AppPackageInfo.version,
        latestVersion: check.latestAppVersion,
      );
    } catch (_) {
      return true;
    }
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
