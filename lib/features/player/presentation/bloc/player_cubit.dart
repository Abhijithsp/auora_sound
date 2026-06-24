import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import '../../../music_library/domain/entities/song.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/usecases/next_song.dart';
import '../../domain/usecases/pause_song.dart';
import '../../domain/usecases/play_song.dart';
import '../../domain/usecases/previous_song.dart';
import '../../../../core/services/audio/playback_history_tracker.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final PlaySong playSong;
  final PauseSong pauseSong;
  final NextSong nextSong;
  final PreviousSong previousSong;
  final PlayerRepository playerRepository;
  final PlaybackHistoryTracker historyTracker;

  StreamSubscription? _playbackStateSub;
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _queueSub;

  PlayerCubit({
    required this.playSong,
    required this.pauseSong,
    required this.nextSong,
    required this.previousSong,
    required this.playerRepository,
    required this.historyTracker,
  })  : super(const PlayerState()) {
    _subscribeToPlaybackStreams();
    _initVolume();
    _loadFavorites();
  }

  void _subscribeToPlaybackStreams() {
    _playbackStateSub = playerRepository.playbackState.listen((playbackState) {
      emit(state.copyWith(
        isPlaying: playbackState.playing,
        playbackState: playbackState,
        isShuffle: playbackState.shuffleMode == AudioServiceShuffleMode.all,
        repeatMode: playbackState.repeatMode,
      ));
    });

    _mediaItemSub = playerRepository.currentMediaItem.listen((item) {
      emit(state.copyWith(currentTrack: item));
      if (item != null) {
        historyTracker.addToRecentlyPlayed(item.id);
        historyTracker.incrementPlayCount(item.id);
      }
    });

    _queueSub = playerRepository.queue.listen((queue) {
      emit(state.copyWith(queue: queue));
    });
  }

  Future<void> _initVolume() async {
    try {
      final currentVol = await FlutterVolumeController.getVolume() ?? 0.7;
      final currentMute = await FlutterVolumeController.getMute() ?? false;
      emit(state.copyWith(volume: currentVol, isMuted: currentMute));

      FlutterVolumeController.addListener((val) {
        emit(state.copyWith(volume: val));
      });
    } catch (_) {}
  }

  void _loadFavorites() {
    final list = historyTracker.getFavorites();
    emit(state.copyWith(favorites: list));
  }

  Future<void> setVolume(double val) async {
    try {
      await FlutterVolumeController.setVolume(val);
      emit(state.copyWith(volume: val));
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    try {
      final newMute = !state.isMuted;
      await FlutterVolumeController.setMute(newMute);
      emit(state.copyWith(isMuted: newMute));
    } catch (_) {}
  }

  Future<void> toggleShuffle() async {
    final newShuffle = !state.isShuffle;
    await playerRepository.setShuffleMode(newShuffle);
    emit(state.copyWith(isShuffle: newShuffle));
  }

  Future<void> toggleRepeat() async {
    late AudioServiceRepeatMode nextMode;
    switch (state.repeatMode) {
      case AudioServiceRepeatMode.none:
        nextMode = AudioServiceRepeatMode.all;
        break;
      case AudioServiceRepeatMode.all:
        nextMode = AudioServiceRepeatMode.one;
        break;
      case AudioServiceRepeatMode.one:
        nextMode = AudioServiceRepeatMode.none;
        break;
      default:
        nextMode = AudioServiceRepeatMode.none;
    }
    await playerRepository.setRepeatMode(nextMode);
    emit(state.copyWith(repeatMode: nextMode));
  }

  Future<void> toggleFavorite(String songId) async {
    await historyTracker.toggleFavorite(songId);
    _loadFavorites();
  }

  Future<void> playSongItem(Song song, List<Song> playlist) =>
      playSong(song: song, playlist: playlist);

  Future<void> togglePlay() {
    if (state.isPlaying) {
      return pauseSong();
    } else {
      return playSong();
    }
  }

  Future<void> next() => nextSong();

  Future<void> previous() => previousSong();

  Future<void> seek(Duration position) => playerRepository.seek(position);

  Future<void> skipToQueueItem(int index) => playerRepository.skipToQueueItem(index);

  Future<void> removeFromQueue(String songId) async {
    final updatedQueue = List<MediaItem>.from(state.queue)..removeWhere((item) => item.id == songId);
    await playerRepository.updateQueue(updatedQueue);
    emit(state.copyWith(queue: updatedQueue));
  }

  @override
  Future<void> close() {
    try {
      FlutterVolumeController.removeListener();
    } catch (_) {}
    _playbackStateSub?.cancel();
    _mediaItemSub?.cancel();
    _queueSub?.cancel();
    return super.close();
  }
}
