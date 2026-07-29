import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/music_library/data/datasources/local_song_datasource.dart';
import '../../../features/music_library/data/repositories/song_repository_impl.dart';
import '../../../features/music_library/domain/repositories/song_repository.dart';
import '../../../features/music_library/domain/usecases/get_all_songs.dart';
import '../../../features/music_library/presentation/bloc/library_cubit.dart';

import '../../../features/player/data/repositories/player_repository_impl.dart';
import '../../../features/player/domain/repositories/player_repository.dart';
import '../../../features/player/domain/usecases/next_song.dart';
import '../../../features/player/domain/usecases/pause_song.dart';
import '../../../features/player/domain/usecases/play_song.dart';
import '../../../features/player/domain/usecases/previous_song.dart';
import '../../../features/player/presentation/bloc/player_cubit.dart';

import '../../../features/settings/presentation/bloc/settings_cubit.dart';

import '../audio/audio_service_initializer.dart';
import '../audio/player_controller.dart';
import '../audio/playback_history_tracker.dart';
import '../permissions/permission_service.dart';

final getIt = GetIt.instance;

/// No-op AudioHandler used when AudioService.init() fails on first launch.
/// Lets the app load the music library without crashing; playback is
/// unavailable until the user restarts the app.
class _NullAudioHandler extends BaseAudioHandler {}

Future<void> setupServiceLocator() async {
  // ── 1. Core dependencies (always succeed) ─────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<PlaybackHistoryTracker>(
    () => PlaybackHistoryTracker(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<OnAudioQuery>(() => OnAudioQuery());
  getIt.registerLazySingleton<PermissionService>(() => PermissionServiceImpl());

  // ── 2. Music library feature (always succeeds, no AudioService needed) ────
  getIt.registerLazySingleton<LocalSongDatasource>(
    () => LocalSongDatasourceImpl(getIt<OnAudioQuery>()),
  );
  getIt.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(getIt<LocalSongDatasource>()),
  );
  getIt.registerLazySingleton<GetAllSongs>(
    () => GetAllSongs(getIt<SongRepository>()),
  );
  getIt.registerFactory<LibraryCubit>(
    () => LibraryCubit(
      getAllSongs: getIt<GetAllSongs>(),
      permissionService: getIt<PermissionService>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(getIt<SharedPreferences>()),
  );

  // ── 3. AudioService + player (may fail on first launch; falls back safely) ─
  AudioHandler audioHandler;
  try {
    audioHandler = await AudioServiceInitializer.init();
  } catch (e) {
    debugPrint('AudioService.init() failed, using null handler: $e');
    audioHandler = _NullAudioHandler();
  }
  getIt.registerSingleton<AudioHandler>(audioHandler);

  getIt.registerLazySingleton<PlayerController>(
    () => PlayerControllerImpl(getIt<AudioHandler>()),
  );
  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(getIt<PlayerController>()),
  );
  getIt.registerLazySingleton<PlaySong>(() => PlaySong(getIt<PlayerRepository>()));
  getIt.registerLazySingleton<PauseSong>(() => PauseSong(getIt<PlayerRepository>()));
  getIt.registerLazySingleton<NextSong>(() => NextSong(getIt<PlayerRepository>()));
  getIt.registerLazySingleton<PreviousSong>(() => PreviousSong(getIt<PlayerRepository>()));

  getIt.registerFactory<PlayerCubit>(
    () => PlayerCubit(
      playSong: getIt<PlaySong>(),
      pauseSong: getIt<PauseSong>(),
      nextSong: getIt<NextSong>(),
      previousSong: getIt<PreviousSong>(),
      playerRepository: getIt<PlayerRepository>(),
      historyTracker: getIt<PlaybackHistoryTracker>(),
    ),
  );
}
