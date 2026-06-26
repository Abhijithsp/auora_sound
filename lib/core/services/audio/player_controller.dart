import 'package:audio_service/audio_service.dart';

abstract class PlayerController {
  Stream<PlaybackState> get playbackState;
  Stream<MediaItem?> get currentMediaItem;
  Stream<List<MediaItem>> get queue;

  PlaybackState get currentPlaybackState;
  MediaItem? get currentMediaItemValue;
  List<MediaItem> get currentQueue;

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToQueueItem(int index);
  Future<void> loadPlaylist(List<MediaItem> items);
  Future<void> playMediaItem(MediaItem item);
  Future<void> setShuffleMode(bool enabled);
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode);
}

class PlayerControllerImpl implements PlayerController {
  final AudioHandler _audioHandler;

  PlayerControllerImpl(this._audioHandler);

  @override
  Stream<PlaybackState> get playbackState => _audioHandler.playbackState;

  @override
  Stream<MediaItem?> get currentMediaItem => _audioHandler.mediaItem;

  @override
  Stream<List<MediaItem>> get queue => _audioHandler.queue;

  @override
  PlaybackState get currentPlaybackState => _audioHandler.playbackState.value;

  @override
  MediaItem? get currentMediaItemValue => _audioHandler.mediaItem.value;

  @override
  List<MediaItem> get currentQueue => _audioHandler.queue.value;

  @override
  Future<void> play() => _audioHandler.play();

  @override
  Future<void> pause() => _audioHandler.pause();

  @override
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  @override
  Future<void> skipToNext() => _audioHandler.skipToNext();

  @override
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();

  @override
  Future<void> skipToQueueItem(int index) => _audioHandler.skipToQueueItem(index);

  @override
  Future<void> loadPlaylist(List<MediaItem> items) => _audioHandler.updateQueue(items);

  @override
  Future<void> playMediaItem(MediaItem item) => _audioHandler.playMediaItem(item);

  @override
  Future<void> setShuffleMode(bool enabled) => _audioHandler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _audioHandler.setRepeatMode(repeatMode);
}
