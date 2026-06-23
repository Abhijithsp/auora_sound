import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import '../bloc/player_cubit.dart';
import '../bloc/player_state.dart';

class PlayerControls extends StatelessWidget {
  final double iconSize;

  const PlayerControls({
    super.key,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final playerCubit = context.read<PlayerCubit>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        final isShuffle = state.isShuffle;
        final repeatMode = state.repeatMode;

        // Repeat button styling
        IconData repeatIcon = Icons.repeat_rounded;
        Color repeatColor = colors.onSurfaceVariant.withValues(alpha: 0.6);
        if (repeatMode == AudioServiceRepeatMode.one) {
          repeatIcon = Icons.repeat_one_rounded;
          repeatColor = colors.primary;
        } else if (repeatMode == AudioServiceRepeatMode.all || repeatMode == AudioServiceRepeatMode.group) {
          repeatIcon = Icons.repeat_rounded;
          repeatColor = colors.primary;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle Button
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                size: iconSize * 0.75,
                color: isShuffle ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              onPressed: () => playerCubit.toggleShuffle(),
            ),

            // Skip Previous Button
            IconButton(
              icon: Icon(
                Icons.skip_previous_rounded,
                size: iconSize * 1.1,
                color: colors.onSurface,
              ),
              onPressed: () => playerCubit.previous(),
            ),

            // Play / Pause Glass Orb Button
            GestureDetector(
              onTap: () => playerCubit.togglePlay(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.4),
                      blurRadius: state.isPlaying ? 20 : 12,
                      spreadRadius: state.isPlaying ? 2 : 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      key: ValueKey<bool>(state.isPlaying),
                      size: iconSize * 1.3,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Skip Next Button
            IconButton(
              icon: Icon(
                Icons.skip_next_rounded,
                size: iconSize * 1.1,
                color: colors.onSurface,
              ),
              onPressed: () => playerCubit.next(),
            ),

            // Repeat Button
            IconButton(
              icon: Icon(
                repeatIcon,
                size: iconSize * 0.75,
                color: repeatColor,
              ),
              onPressed: () => playerCubit.toggleRepeat(),
            ),
          ],
        );
      },
    );
  }
}
