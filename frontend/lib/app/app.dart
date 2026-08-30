import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/locale_scope.dart';
import '../features/auth/presentation/cubit/app_session_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppSessionCubit(),
      child: BlocBuilder<AppSessionCubit, AppSessionState>(
        builder: (context, session) {
          return MaterialApp.router(
            title: 'Fixly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
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
            builder: (context, child) => LocaleScope(
              locale: session.locale,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
