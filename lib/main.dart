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

  // Set up BloC observer for Sentry error reporting
  Bloc.observer = SentryBlocObserver();

  // Init Sentry SDK without appRunner so we call runApp exactly once below.
  // This avoids the double-runApp black frame on startup.
  await SentryFlutter.init((options) {
    options.dsn =
        'https://9f91786329458c1f2943456d9dda8563@o4511659427364864.ingest.de.sentry.io/4511659438506064';
    options.sendDefaultPii = true;
    options.enableLogs = true;
    options.tracesSampleRate = 1.0;
    // ignore: experimental_member_use
    options.profilesSampleRate = 1.0;
    options.replay.sessionSampleRate = 0.1;
    options.replay.onErrorSampleRate = 1.0;
  });

  // Single runApp call — _AppLoader shows a dark screen immediately and
  // runs setupServiceLocator in initState, then transitions to MyApp.
  runApp(SentryWidget(child: const _AppLoader()));
}

/// Shows a dark loading screen while the service locator initialises,
/// then replaces itself with MyApp — all within a single widget tree rebuild.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await setupServiceLocator();
    // TODO: Remove this line after sending the first sample event to sentry.
    await Sentry.captureException(StateError('This is a sample exception.'));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Color(0xFF0F0F11)),
      );
    }
    return const MyApp();
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
          final preset =
              AppThemePresets.getByName(settingsState.themePresetName);
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
