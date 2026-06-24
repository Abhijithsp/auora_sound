import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/glowing_background.dart';
import '../../domain/entities/song.dart';
import '../bloc/library_cubit.dart';
import '../bloc/library_state.dart';
import '../widgets/song_tile.dart';
import '../../../player/presentation/bloc/player_cubit.dart';
import '../../../player/presentation/bloc/player_state.dart';

class PlaylistDetailPage extends StatelessWidget {
  final String playlistName;

  const PlaylistDetailPage({
    super.key,
    required this.playlistName,
  });

  List<Color> _getDeterministicColors(String title) {
    final int hash = title.hashCode;
    final List<List<Color>> palettes = [
      [const Color(0xFFFF8E53), const Color(0xFFFF007F)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFF7F00FF), const Color(0xFFFF007F)],
      [const Color(0xFF3E82F7), const Color(0xFFA7C8FF)],
    ];
    final index = hash.abs() % palettes.length;
    return palettes[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final headerGradient = _getDeterministicColors(playlistName);

    return Scaffold(
      body: GlowingBackground(
        child: BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, libraryState) {
            final allSongs = libraryState.songs;
            final songUris = libraryState.playlists[playlistName] ?? [];

            // Resolve URIs to Songs
            final playlistSongs = songUris
                .map((uri) => allSongs.firstWhere(
                      (s) => s.uri == uri || s.id == uri,
                      orElse: () => const Song(
                        id: '',
                        title: '',
                        artist: '',
                        album: '',
                        duration: Duration.zero,
                        uri: '',
                      ),
                    ))
                .where((s) => s.id.isNotEmpty)
                .toList();

            return BlocBuilder<PlayerCubit, PlayerState>(
              builder: (context, playerState) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header Sliver
                    SliverAppBar(
                      expandedHeight: 220.0,
                      pinned: true,
                      backgroundColor: const Color(0xFF0A0A12).withValues(alpha: 0.2),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          playlistName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2))],
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: headerGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: const Center(
                              child: Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white70,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Control Buttons: Play & Shuffle
                    if (playlistSongs.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<PlayerCubit>().playSongItem(
                                          playlistSongs.first,
                                          playlistSongs,
                                        );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final shuffled = List<Song>.from(playlistSongs)..shuffle();
                                    context.read<PlayerCubit>().playSongItem(
                                          shuffled.first,
                                          shuffled,
                                        );
                                  },
                                  icon: const Icon(Icons.shuffle_rounded),
                                  label: const Text('Shuffle'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Song List
                    if (playlistSongs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.queue_music_rounded,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'This playlist is empty',
                                  style: textTheme.titleMedium?.copyWith(color: Colors.white54),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add songs to this playlist from your library or folders options menu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white30, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = playlistSongs[index];
                              final currentTrack = playerState.currentTrack;
                              final isActive = currentTrack != null && currentTrack.id == song.uri;
                              final isPlaying = isActive && playerState.isPlaying;

                              return SongTile(
                                song: song,
                                isActive: isActive,
                                isPlaying: isPlaying,
                                playlistName: playlistName,
                                onTap: () {
                                  // Play song restricting the queue only to songs in this playlist
                                  context.read<PlayerCubit>().playSongItem(
                                        song,
                                        playlistSongs,
                                      );
                                },
                              );
                            },
                            childCount: playlistSongs.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
