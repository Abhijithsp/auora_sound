import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  /// True only after an explicit [stop]. audio_service tears down the
  /// MediaSession and notification whenever the state becomes `idle`, so we
  /// only let `idle` through when the stop was intentional.
  bool _stopRequested = false;

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // ── 1. Sync current source and queue to mediaItem ───────────────────────
    // We listen to sequenceStateStream to track the currently active track
    // and its metadata. Each AudioSource is loaded with its corresponding MediaItem
    // as the tag. This resolves potential race conditions of combineLatest2.
    _player.sequenceStateStream.listen((sequenceState) {
      final currentSource = sequenceState.currentSource;
      if (currentSource != null) {
        final tag = currentSource.tag as MediaItem?;
        if (tag != null) {
          // Prefer the queue's copy: it may carry a corrected duration.
          final index = sequenceState.currentIndex;
          final q = queue.value;
          final item = index != null && index < q.length && q[index].id == tag.id
              ? q[index]
              : tag;
          mediaItem.add(item);
        }
      }
      _broadcastState();
    });

    // MediaStore durations can be missing (0). Use the decoder's duration so
    // the notification / lock screen seek bar has a correct range.
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (duration == null || item == null || item.duration == duration) {
        return;
      }
      final index = _player.currentIndex;
      if (index == null || index >= queue.value.length) return;
      if (queue.value[index].id != item.id) return;
      final updated = item.copyWith(duration: duration);
      final newQueue = List<MediaItem>.from(queue.value)..[index] = updated;
      queue.add(newQueue);
      mediaItem.add(updated);
    });

    // ── 2. Forward player state changes to audio_service ───────────────────
    // A track that fails to load drops just_audio to idle. Report it instead
    // of letting it go unhandled; _broadcastState keeps the session alive.
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object e, StackTrace st) {
        debugPrint('Player error: $e');
        Sentry.captureException(e, stackTrace: st);
        _broadcastState();
      },
    );
    _player.playerStateStream.listen((_) => _broadcastState());
    _player.shuffleModeEnabledStream.listen((_) => _broadcastState());
    _player.loopModeStream.listen((_) => _broadcastState());

    // Auto-advance on completion
    _player.processingStateStream.listen((state) {
      _broadcastState();
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });

    _broadcastState();
  }

  /// Broadcasts the player state to audio_service to keep the OS notification in sync.
  void _broadcastState() {
    final playing = _player.playing;
    // Unintended idle (load error, source swap) with a queue loaded is
    // reported as ready so the notification and lock screen controls survive.
    final unintendedIdle = _player.processingState == ProcessingState.idle &&
        !_stopRequested &&
        queue.value.isNotEmpty;
    final processingState = {
      ProcessingState.idle: unintendedIdle
          ? AudioProcessingState.ready
          : AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState] ??
        AudioProcessingState.idle;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
        MediaAction.fastForward,
        MediaAction.rewind,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode] ??
          AudioServiceRepeatMode.none,
    ));
  }

  Uri _parseUri(String uriStr) {
    if (uriStr.startsWith('http://') ||
        uriStr.startsWith('https://') ||
        uriStr.startsWith('content://') ||
        uriStr.startsWith('file://')) {
      return Uri.parse(uriStr);
    }
    return Uri.file(uriStr);
  }

  /// Attaches album artwork for MediaStore tracks that have no explicit art.
  ///
  /// audio_service loads `content://` art natively; with `loadThumbnailUri`
  /// set it uses ContentResolver.loadThumbnail (Android 10+), which extracts
  /// the embedded album art from the audio file itself. Any failure there just
  /// yields no artwork — it never affects playback.
  MediaItem _withArtwork(MediaItem item) {
    if (item.artUri != null || !item.id.startsWith('content://')) return item;
    return item.copyWith(
      artUri: Uri.parse(item.id),
      extras: {...?item.extras, 'loadThumbnailUri': item.id},
    );
  }

  /// Loads the playlist into the player.
  Future<void> loadPlaylist(List<MediaItem> rawItems) async {
    final items = rawItems.map(_withArtwork).toList();
    final sources = items
        .map((item) => AudioSource.uri(_parseUri(item.id), tag: item))
        .toList();

    // Update queue first so the combined stream can emit the correct mediaItem
    // as soon as just_audio resolves the index.
    _stopRequested = false;
    queue.add(items);

    // setAudioSources is the modern API in just_audio 0.10+
    await _player.setAudioSources(sources);
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) => loadPlaylist(queue);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    // skipToQueueItem publishes the queue's copy of this item (which carries
    // artwork), so don't push the raw item first — that would briefly
    // replace the notification metadata with an art-less version.
    final index = queue.value.indexWhere((q) => q.id == mediaItem.id);
    if (index != -1) {
      await skipToQueueItem(index);
    } else {
      final updated = List<MediaItem>.from(queue.value)..add(mediaItem);
      await loadPlaylist(updated);
      await skipToQueueItem(updated.length - 1);
    }
    await play();
  }

  // ── Passthrough controls ──────────────────────────────────────────────────

  @override
  Future<void> play() {
    _stopRequested = false;
    return _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (queue.value.isNotEmpty) {
      await skipToQueueItem(0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
        if (_player.playing) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.value.length) {
      mediaItem.add(queue.value[index]);
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final mode = {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[repeatMode]!;
    await _player.setLoopMode(mode);
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    await _player.stop();
    await super.stop();
  }
}
