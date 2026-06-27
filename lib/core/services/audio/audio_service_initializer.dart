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
        // Keep notification alive – critical for Nothing Phone and other aggressive
        // battery OEMs. androidNotificationOngoing:true + androidStopForegroundOnPause:true
        // is the only valid combination that keeps the notification persistent.
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidShowNotificationBadge: true,
        // Small 96×96 monochrome icon – must be white on transparent
        androidNotificationIcon: 'drawable/ic_stat_music',
      ),
    );
  }
}
