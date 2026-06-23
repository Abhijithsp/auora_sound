import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/locator/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/music_library/presentation/bloc/library_cubit.dart';
import 'features/player/presentation/bloc/player_cubit.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'features/music_library/presentation/pages/main_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DI service locator (audio handler, permissions, cubits, settings)
  await setupServiceLocator();

  runApp(const MyApp());
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
          return MaterialApp(
            title: 'Octave Music Player',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.generateTheme(settingsState.accentColor, false),
            darkTheme: AppTheme.generateTheme(settingsState.accentColor, true),
            themeMode: settingsState.themeMode,
            home: const MainShellPage(),
          );
        },
      ),
    );
  }
}
