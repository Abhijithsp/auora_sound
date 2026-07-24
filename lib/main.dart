import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/locator/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_presets.dart';
import 'core/utils/sentry_bloc_observer.dart';
import 'features/music_library/presentation/bloc/library_cubit.dart';
import 'features/player/presentation/bloc/player_cubit.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'features/music_library/presentation/pages/main_shell_page.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw the first frame immediately so Android dismisses the native splash
  // cleanly instead of showing a black screen during async initialization.
  runApp(const _LoadingApp());

  // Set up BloC observer for Sentry error reporting
  Bloc.observer = SentryBlocObserver();

  // Initialize DI service locator (audio handler, permissions, cubits, settings)
  await setupServiceLocator();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://9f91786329458c1f2943456d9dda8563@o4511659427364864.ingest.de.sentry.io/4511659438506064';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    // runApp here replaces _LoadingApp with the real app.
    appRunner: () => runApp(SentryWidget(child: const MyApp())),
  );
  // TODO: Remove this line after sending the first sample event to sentry.
  await Sentry.captureException(StateError('This is a sample exception.'));
}

/// Minimal dark scaffold shown immediately so Flutter draws its first frame
/// before the async init completes. Matches the default dark background color.
class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0F0F11),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (context) => getIt<SettingsCubit>(),
        ),
        BlocProvider<LibraryCubit>(
          create: (context) => getIt<LibraryCubit>(),
        ),
        BlocProvider<PlayerCubit>(
          create: (context) => getIt<PlayerCubit>(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final preset = AppThemePresets.getByName(settingsState.themePresetName);
          return MaterialApp(
            title: 'Aura Sound',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              SentryNavigatorObserver(),
            ],
            theme: AppTheme.generateTheme(preset, false),
            darkTheme: AppTheme.generateTheme(preset, true),
            themeMode: settingsState.themeMode,
            home: const MainShellPage(),
          );
        },
      ),
    );
  }
}

