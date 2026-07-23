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
        androidNotificationChannelDescription: 'Background audio playback',
        // ongoing=false: lets Android treat this as a proper media notification
        // (required for Android 14+ media player panel on lock screen).
        // stopForegroundOnPause=false: keeps the service in foreground even
        // when paused, so lock screen controls remain visible.
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidShowNotificationBadge: true,
        androidNotificationClickStartsActivity: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  }
}

