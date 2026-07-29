import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../../constants/audio_constants.dart';
import 'audio_handler.dart';

class AudioServiceInitializer {
  static Future<AudioHandler> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Retry up to 3 times: the Activity binding may not be ready on the
    // exact postFrameCallback tick when Sentry or the engine is still warming up.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await AudioService.init(
          builder: () => MyAudioHandler(),
          config: AudioServiceConfig(
            androidNotificationChannelId: AudioConstants.notificationChannelId,
            androidNotificationChannelName: AudioConstants.notificationChannelName,
            androidNotificationChannelDescription: 'Background audio playback',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: false,
            androidShowNotificationBadge: true,
            androidNotificationClickStartsActivity: true,
            androidNotificationIcon: 'drawable/ic_stat_music',
          ),
        );
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('AudioService.init attempt $attempt failed: $e — retrying...');
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    throw StateError('AudioService.init failed after $maxAttempts attempts');
  }
}


