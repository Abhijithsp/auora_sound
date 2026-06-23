import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/library_cubit.dart';
import '../bloc/library_state.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../../player/presentation/bloc/player_cubit.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

          final songs = libraryState.songs;
          var artists = songs.map((s) => s.artist).toSet().toList();

          if (_isSearching && _searchQuery.isNotEmpty) {
            artists = artists
                .where((artist) => artist.toLowerCase().contains(_searchQuery))
                .toList();
          }

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
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search artists...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                        ),
                        style: TextStyle(color: colors.onSurface),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                      )
                    : Text(
                        'Artists',
                        style: theme.appBarTheme.titleTextStyle?.copyWith(color: colors.onSurface),
                      ),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
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

              if (artists.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No artists found')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120, top: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artist = artists[index];
                        final artistSongs = songs.where((s) => s.artist == artist).toList();

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: GlassmorphicContainer(
                            borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderOpacity: 0.08,
                            backgroundOpacity: 0.04,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: colors.primary.withValues(alpha: 0.2),
                                radius: 24,
                                child: Icon(Icons.person_rounded, color: colors.primary),
                              ),
                              title: Text(
                                artist,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${artistSongs.length} tracks',
                                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                              onTap: () {
                                if (artistSongs.isNotEmpty) {
                                  context.read<PlayerCubit>().playSongItem(artistSongs.first, artistSongs);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      childCount: artists.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
