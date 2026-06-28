import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_music/core/services/audio/audio_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const justAudioChannel = MethodChannel('com.ryanheise.just_audio.methods');
  const audioServiceChannel = MethodChannel('com.ryanheise.audioservice.methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(justAudioChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'create') {
        return {'id': 'mock-player-id'};
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioServiceChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(justAudioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioServiceChannel, null);
  });

  group('MyAudioHandler Tests', () {
    test('should initialize and broadcast idle state', () async {
      final handler = MyAudioHandler();

      expect(handler, isNotNull);
      expect(handler.playbackState.value.playing, isFalse);
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
      expect(handler.mediaItem.value, isNull);
    });

    test('should update mediaItem when playMediaItem is called', () async {
      final handler = MyAudioHandler();

      const testItem = MediaItem(
        id: 'content://media/external/audio/media/1',
        album: 'Test Album',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: Duration(minutes: 3),
      );

      // Call playMediaItem which updates mediaItem stream
      await handler.playMediaItem(testItem);

      expect(handler.mediaItem.value, equals(testItem));
    });
  });
}
