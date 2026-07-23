import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import '../../constants/audio_constants.dart';
import 'audio_handler.dart';

class AudioServiceInitializer {
  static Future<AudioHandler> init() async {
    // Configure the audio session for music playback (handles audio focus,
    // interruptions from calls, etc.)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    return await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: AudioConstants.notificationChannelId,
        androidNotificationChannelName: AudioConstants.notificationChannelName,
        // ongoing=false: lets Android treat this as a proper media notification
        // (required for Android 14+ media player panel on lock screen).
        // stopForegroundOnPause=false: keeps the service in foreground even
        // when paused, so lock screen controls remain visible.
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: true,
        androidNotificationClickStartsActivity: true,
      ),
    );
  }
}

