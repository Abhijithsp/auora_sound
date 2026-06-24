import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/song.dart';
import '../bloc/library_cubit.dart';
import '../bloc/library_state.dart';
import '../../../player/presentation/bloc/player_cubit.dart';
import '../../../player/presentation/bloc/player_state.dart';
import '../widgets/song_tile.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, libraryState) {
          if (libraryState.status == LibraryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSongs = libraryState.songs;

          return BlocBuilder<PlayerCubit, PlayerState>(
            builder: (context, playerState) {
              final favIds = playerState.favorites;
              final favorites = favIds
                  .map((id) => allSongs.firstWhere((s) => s.id == id || s.uri == id, orElse: () => const Song(id: '', title: '', artist: '', album: '', duration: Duration.zero, uri: '')))
                  .where((s) => s.id.isNotEmpty)
                  .toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: false,
                    floating: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    leading: Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        );
                      },
                    ),
                    title: Text(
                      'Favorites',
                      style: theme.appBarTheme.titleTextStyle?.copyWith(color: colors.onSurface),
                    ),
                  ),
                  if (favorites.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No favorite tracks yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = favorites[index];
                            final currentTrack = playerState.currentTrack;
                            final isActive = currentTrack != null && currentTrack.id == song.uri;
                            final isPlaying = isActive && playerState.isPlaying;

                            return SongTile(
                              song: song,
                              isActive: isActive,
                              isPlaying: isPlaying,
                              onTap: () {
                                context.read<PlayerCubit>().playSongItem(song, favorites);
                              },
                            );
                          },
                          childCount: favorites.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
