import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/locator/service_locator.dart';
import '../../../../core/services/audio/playback_history_tracker.dart';
import '../../domain/entities/song.dart';
import '../bloc/library_cubit.dart';
import '../bloc/library_state.dart';
import '../../../player/presentation/bloc/player_cubit.dart';
import '../../../player/presentation/bloc/player_state.dart';
import '../widgets/song_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final PlaybackHistoryTracker _tracker = getIt<PlaybackHistoryTracker>();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Generates a beautiful deterministic neon gradient based on the song title hash
  List<Color> _getDeterministicColors(String title) {
    final int hash = title.hashCode;
    final List<List<Color>> palettes = [
      [const Color(0xFF3E82F7), const Color(0xFFA7C8FF)],
      [const Color(0xFF8B5CF6), const Color(0xFFFF4B7D)],
      [const Color(0xFF00B4D8), const Color(0xFF90E0EF)],
      [const Color(0xFFFF4B7D), const Color(0xFFFF85A2)],
      [const Color(0xFF3E82F7), const Color(0xFFFF4B7D)],
    ];
    return palettes[hash.abs() % palettes.length];
  }

  Widget _buildArtworkPlaceholder(String title, double size) {
    final colors = _getDeterministicColors(title);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          title.substring(0, math.min(title.length, 1)).toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, libraryState) {
          if (libraryState.status == LibraryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSongs = libraryState.songs;

          final playerState = context.watch<PlayerCubit>().state;


          final favIds = playerState.favorites;
          final favorites = favIds
              .map(
                (id) => allSongs.firstWhere(
                  (s) => s.id == id || s.uri == id,
                  orElse: () => const Song(
                    id: '',
                    title: '',
                    artist: '',
                    album: '',
                    duration: Duration.zero,
                    uri: '',
                  ),
                ),
              )
              .where((s) => s.id.isNotEmpty)
              .toList();

          final playCounts = _tracker.getPlayCounts();
          final mostPlayed = List<Song>.from(allSongs)
            ..sort(
              (a, b) =>
                  (playCounts[b.id] ?? playCounts[b.uri] ?? 0)
                  .compareTo(playCounts[a.id] ?? playCounts[a.uri] ?? 0),
            );
          final filteredMostPlayed = mostPlayed
              .where((s) => (playCounts[s.id] ?? playCounts[s.uri] ?? 0) > 0)
              .toList();

          // Recently added (mocked as last 50 songs loaded)
          final recentlyAdded = allSongs.reversed.take(50).toList();

          // Filter songs if searching
          var searchedSongs = allSongs;
          if (_isSearching && _searchQuery.isNotEmpty) {
            searchedSongs = allSongs
                .where(
                  (s) =>
                      s.title.toLowerCase().contains(_searchQuery) ||
                      s.artist.toLowerCase().contains(_searchQuery) ||
                      s.album.toLowerCase().contains(_searchQuery),
                )
                .toList();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Bar with Profile & Search Toggle
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
                  'Aura Sound',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              if (_isSearching)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search tracks, artists, albums...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      style: TextStyle(color: colors.onSurface),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ),

              if (_isSearching && _searchQuery.isNotEmpty) ...[
                if (searchedSongs.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No matching songs found')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = searchedSongs[index];
                        return BlocBuilder<PlayerCubit, PlayerState>(
                          builder: (context, playerState) {
                            final currentTrack = playerState.currentTrack;
                            final isActive =
                                currentTrack != null &&
                                currentTrack.id == song.uri;
                            final isPlaying = isActive && playerState.isPlaying;

                            return SongTile(
                              song: song,
                              isActive: isActive,
                              isPlaying: isPlaying,
                              onTap: () {
                                context.read<PlayerCubit>().playSongItem(
                                  song,
                                  searchedSongs,
                                );
                              },
                            );
                          },
                        );
                      }, childCount: searchedSongs.length),
                    ),
                  ),
              ] else ...[
                // Favorites Section (Horizontal Scrollable)
                if (favorites.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildHorizontalSongList(
                      context: context,
                      title: 'Favorites',
                      songs: favorites,
                    ),
                  ),

                // Most Played Section (Horizontal Scrollable)
                if (filteredMostPlayed.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildHorizontalSongList(
                      context: context,
                      title: 'Most Played',
                      songs: filteredMostPlayed,
                      playCounts: playCounts,
                    ),
                  ),

                // Recently Added Section (Vertical List of 50)
                if (recentlyAdded.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text(
                        'Recently Added',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = recentlyAdded[index];
                        return BlocBuilder<PlayerCubit, PlayerState>(
                          builder: (context, playerState) {
                            final currentTrack = playerState.currentTrack;
                            final isActive =
                                currentTrack != null &&
                                currentTrack.id == song.uri;
                            final isPlaying = isActive && playerState.isPlaying;

                            return SongTile(
                              song: song,
                              isActive: isActive,
                              isPlaying: isPlaying,
                              onTap: () {
                                context.read<PlayerCubit>().playSongItem(
                                  song,
                                  recentlyAdded,
                                );
                              },
                            );
                          },
                        );
                      }, childCount: recentlyAdded.length),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSongList({
    required BuildContext context,
    required String title,
    required List<Song> songs,
    Map<String, int>? playCounts,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final count = playCounts != null ? (playCounts[song.id] ?? playCounts[song.uri] ?? 0) : null;

              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    context.read<PlayerCubit>().playSongItem(
                      song,
                      songs,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          _buildArtworkPlaceholder(song.title, 130),
                          if (count != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.primary.withValues(alpha: 0.5), width: 1),
                                ),
                                child: Text(
                                  '$count ${count == 1 ? 'play' : 'plays'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
