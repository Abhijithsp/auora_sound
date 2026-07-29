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
  // SentryFlutter.init with appRunner is the canonical setup pattern.
  // It calls WidgetsFlutterBinding.ensureInitialized() internally, avoiding
  // the double-init that happens when you call it manually before SentryFlutter.init.
  Bloc.observer = SentryBlocObserver();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://9f91786329458c1f2943456d9dda8563@o4511659427364864.ingest.de.sentry.io/4511659438506064';
      options.sendDefaultPii = true;
      options.enableLogs = true;
      options.tracesSampleRate = 1.0;
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;
      // Session replay encodes a video stream on startup which causes severe
      // frame drops (1500ms+ Davey frames). Disable until the app is stable.
      options.replay.sessionSampleRate = 0.0;
      options.replay.onErrorSampleRate = 0.0;
    },
    appRunner: () => runApp(SentryWidget(child: const _AppLoader())),
  );
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
    // Delay until after the first frame so the Android Activity is fully
    // window-attached before AudioService.init() makes platform channel calls.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      await setupServiceLocator();
    } catch (e, st) {
      // Log but don't block startup — the app can function without AudioService
      // (playback will be unavailable but the library is still browsable).
      debugPrint('setupServiceLocator failed: $e\n$st');
    }
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
