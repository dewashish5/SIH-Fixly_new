import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/locale_scope.dart';
import '../core/location/location_service.dart';
import '../features/auth/presentation/cubit/app_session_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final GoRouter _router = createAppRouter();
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasPaused = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      LocationService.instance.refreshCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = AppSessionCubit();
        cubit.restoreSession();
        return cubit;
      },
      child: BlocBuilder<AppSessionCubit, AppSessionState>(
        buildWhen: (prev, curr) =>
            prev.locale != curr.locale || prev.themeMode != curr.themeMode,
        builder: (context, session) {
          // LocaleScope ABOVE MaterialApp — wrapping navigator child
          // caused GlobalKey reservation crashes on locale rebuild.
          return LocaleScope(
            locale: session.locale,
            child: MaterialApp.router(
              title: 'Fixly',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: session.themeMode,
              locale: Locale(session.locale),
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
