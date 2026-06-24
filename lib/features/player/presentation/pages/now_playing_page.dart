import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/glowing_background.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../../../core/widgets/visualizer_widget.dart';
import '../bloc/player_cubit.dart';
import '../bloc/player_state.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/player_controls.dart';
import '../widgets/seek_bar.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final playerCubit = context.read<PlayerCubit>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.expand_more_rounded, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('More options'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GlowingBackground(
        child: BlocBuilder<PlayerCubit, PlayerState>(
          builder: (context, state) {
            final currentTrack = state.currentTrack;
            if (currentTrack == null) {
              return const Center(child: Text('No song playing'));
            }

            final duration = currentTrack.duration ?? Duration.zero;
            final size = MediaQuery.of(context).size.width * 0.72;
            final isFavorite = state.favorites.contains(currentTrack.id);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    Opacity(
                      opacity: state.isPlaying ? 0.8 : 0.3,
                      child: VisualizerWidget(
                        isPlaying: state.isPlaying,
                        barCount: 15,
                        height: 20,
                        width: 140,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: size * 0.9,
                              height: size * 0.9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary.withValues(alpha: 0.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(alpha: 0.2),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            ArtworkWidget(
                              track: currentTrack,
                              isPlaying: state.isPlaying,
                              size: size,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTrack.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentTrack.artist ?? 'Unknown Artist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            playerCubit.toggleFavorite(currentTrack.id);
                          },
                          child: GlassmorphicContainer(
                            height: 48,
                            width: 48,
                            borderRadius: BorderRadius.circular(16),
                            borderOpacity: 0.1,
                            backgroundOpacity: isFavorite ? 0.2 : 0.05,
                            padding: EdgeInsets.zero,
                            child: Center(
                              child: AnimatedScale(
                                scale: isFavorite ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFavorite ? colors.tertiary : colors.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    SeekBar(duration: duration),
                    
                    const SizedBox(height: 24),

                    const PlayerControls(iconSize: 32),
                    
                    const SizedBox(height: 24),

                    // Volume Slider Row
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            state.isMuted || state.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_down_rounded,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          onPressed: () => playerCubit.toggleMute(),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: theme.sliderTheme.copyWith(
                              activeTrackColor: colors.primary,
                              inactiveTrackColor: colors.outlineVariant.withValues(alpha: 0.3),
                              thumbColor: colors.primary,
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            ),
                            child: Slider(
                              value: state.volume.clamp(0.0, 1.0),
                              onChanged: (val) {
                                playerCubit.setVolume(val);
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            playerCubit.setVolume(1.0);
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildUtilityButton(
                            icon: Icons.playlist_play_rounded,
                            label: 'QUEUE',
                            onTap: () => _showQueueBottomSheet(context, state),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUtilityButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    final color = isActive 
        ? (activeColor ?? theme.colorScheme.primary) 
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context, PlayerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<PlayerCubit, PlayerState>(
              builder: (context, playerState) {
                final queue = playerState.queue;
                final current = playerState.currentTrack;

                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Playback Queue',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${queue.length} Songs',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 12, thickness: 0.5),
                      Expanded(
                        child: queue.isEmpty
                            ? const Center(
                                child: Text('Queue is empty'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: queue.length,
                                itemBuilder: (context, index) {
                                  final item = queue[index];
                                  final isActive = current != null && current.id == item.id;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          colors: isActive
                                              ? [colors.primary, colors.tertiary]
                                              : [colors.surfaceContainerHighest, colors.surfaceContainerHigh],
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isActive ? Icons.volume_up_rounded : Icons.music_note_rounded,
                                          color: isActive ? Colors.white : colors.onSurfaceVariant,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                        color: isActive ? colors.primary : colors.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.artist ?? 'Unknown Artist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: colors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'NOW PLAYING',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: colors.primary,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                          color: Colors.redAccent.withValues(alpha: 0.8),
                                          onPressed: () {
                                            context.read<PlayerCubit>().removeFromQueue(item.id);
                                            if (queue.length <= 1) {
                                              Navigator.pop(bottomSheetContext);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      context.read<PlayerCubit>().skipToQueueItem(index);
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
