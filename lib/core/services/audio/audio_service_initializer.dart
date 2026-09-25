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
            // audio_service asserts `!ongoing || stopForegroundOnPause`.
            // ongoing=true with stopForegroundOnPause=false throws an
            // AssertionError here, AudioService.init never completes, and the
            // app silently falls back to _NullAudioHandler (no MediaSession,
            // no notification). Keep the service in the foreground while
            // paused so Nothing OS / OEM task killers can't reap it; the
            // foreground-service notification is non-dismissable anyway.
            androidNotificationOngoing: false,
            androidStopForegroundOnPause: false,
            androidShowNotificationBadge: true,
            androidNotificationClickStartsActivity: true,
            androidNotificationIcon: 'drawable/ic_stat_music',
            // Downscale embedded album art before handing it to the
            // MediaSession to keep the notification bitmap small.
            artDownscaleWidth: 512,
            artDownscaleHeight: 512,
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


