import 'package:audio_service/audio_service.dart';

class PlayerState {
  final bool isPlaying;
  final MediaItem? currentTrack;
  final PlaybackState? playbackState;
  final List<MediaItem> queue;
  final double volume;
  final bool isMuted;
  final bool isShuffle;
  final AudioServiceRepeatMode repeatMode;
  final List<String> favorites;

  const PlayerState({
    this.isPlaying = false,
    this.currentTrack,
    this.playbackState,
    this.queue = const [],
    this.volume = 1.0,
    this.isMuted = false,
    this.isShuffle = false,
    this.repeatMode = AudioServiceRepeatMode.none,
    this.favorites = const [],
  });

  PlayerState copyWith({
    bool? isPlaying,
    MediaItem? currentTrack,
    PlaybackState? playbackState,
    List<MediaItem>? queue,
    double? volume,
    bool? isMuted,
    bool? isShuffle,
    AudioServiceRepeatMode? repeatMode,
    List<String>? favorites,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      playbackState: playbackState ?? this.playbackState,
      queue: queue ?? this.queue,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      favorites: favorites ?? this.favorites,
    );
  }
}
