import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as query;
import 'package:audio_service/audio_service.dart';
import '../../domain/entities/song.dart';
import '../../../player/presentation/bloc/player_cubit.dart';
import '../../../player/presentation/bloc/player_state.dart';
import '../../../../core/widgets/glowing_background.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../../../core/widgets/visualizer_widget.dart';
import '../../../../core/services/locator/service_locator.dart';
import '../../../../core/services/audio/player_controller.dart';
import '../widgets/song_options_bottom_sheet.dart';
class FolderSongsPage extends StatefulWidget {
  final String folderName;
  final List<Song> songs;

  const FolderSongsPage({
    super.key,
    required this.folderName,
    required this.songs,
  });

  @override
  State<FolderSongsPage> createState() => _FolderSongsPageState();
}

class _FolderSongsPageState extends State<FolderSongsPage> {
  final Set<Song> _selectedSongs = {};
  bool _isMultiSelectMode = false;

  String _formatTotalDuration(List<Song> songs) {
    int totalMs = 0;
    for (final s in songs) {
      totalMs += s.duration.inMilliseconds;
    }
    final duration = Duration(milliseconds: totalMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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

  Widget _buildArtwork(BuildContext context, Song song, bool isActive, bool isPlaying, double size) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final songId = int.tryParse(song.id);

    Widget imageContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getDeterministicColors(song.title),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          song.title.substring(0, math.min(song.title.length, 1)).toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );

    if (songId != null) {
      imageContent = query.QueryArtworkWidget(
        id: songId,
        type: query.ArtworkType.AUDIO,
        keepOldArtwork: true,
        nullArtworkWidget: imageContent,
      );
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(child: imageContent),
            if (isActive)
              Container(
                color: colors.primary.withValues(alpha: 0.2),
                child: Center(
                  child: VisualizerWidget(
                    isPlaying: isPlaying,
                    barCount: 3,
                    height: size * 0.35,
                    width: size * 0.32,
                    color: colors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectSong(Song song) {
    setState(() {
      if (_selectedSongs.contains(song)) {
        _selectedSongs.remove(song);
        if (_selectedSongs.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedSongs.add(song);
        _isMultiSelectMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSongs.clear();
      _isMultiSelectMode = false;
    });
  }

  void _playSelected() {
    if (_selectedSongs.isNotEmpty) {
      final list = _selectedSongs.toList();
      context.read<PlayerCubit>().playSongItem(list.first, list);
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing ${list.length} selected songs')),
      );
    }
  }

  Future<void> _queueSelected() async {
    if (_selectedSongs.isNotEmpty) {
      final list = _selectedSongs.toList();
      final controller = getIt<PlayerController>();
      
      final items = list.map((s) => MediaItem(
        id: s.uri,
        album: s.album,
        title: s.title,
        artist: s.artist,
        duration: s.duration,
        artUri: s.artworkUri != null ? Uri.parse(s.artworkUri!) : null,
      )).toList();

      final currentQueue = List<MediaItem>.from(controller.currentQueue)..addAll(items);
      await controller.loadPlaylist(currentQueue);
      
      if (!mounted) return;
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${list.length} songs to queue')),
      );
    }
  }

  void _showAddPlaylistDialog() {
    if (_selectedSongs.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: const Text('Do you want to add the selected songs to your playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSelection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Songs added to playlist')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: GlowingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: Icon(_isMultiSelectMode ? Icons.close_rounded : Icons.arrow_back_rounded),
                  onPressed: () {
                    if (_isMultiSelectMode) {
                      _clearSelection();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text(
                  _isMultiSelectMode ? '${_selectedSongs.length} selected' : widget.folderName,
                  style: theme.appBarTheme.titleTextStyle?.copyWith(color: colors.onSurface),
                ),
                actions: [
                  if (_isMultiSelectMode) ...[
                    IconButton(
                      icon: const Icon(Icons.select_all_rounded),
                      onPressed: () {
                        setState(() {
                          if (_selectedSongs.length == widget.songs.length) {
                            _selectedSongs.clear();
                            _isMultiSelectMode = false;
                          } else {
                            _selectedSongs.addAll(widget.songs);
                          }
                        });
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.playlist_add_check_rounded),
                      onPressed: () {
                        setState(() {
                          _isMultiSelectMode = true;
                        });
                      },
                    ),
                  ],
                ],
              ),

              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        child: GlassmorphicContainer(
                          borderRadius: BorderRadius.circular(20),
                          borderOpacity: 0.1,
                          backgroundOpacity: 0.05,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.folder_rounded, color: colors.primary, size: 44),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.folderName,
                                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.songs.length} Tracks • ${_formatTotalDuration(widget.songs)}',
                                      style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (widget.songs.isNotEmpty) {
                                    context.read<PlayerCubit>().playSongItem(widget.songs.first, widget.songs);
                                  }
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.play_arrow_rounded, color: colors.onPrimary, size: 28),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.secondaryContainer,
                                  foregroundColor: colors.onSecondaryContainer,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: const Icon(Icons.shuffle_rounded),
                                label: const Text('Shuffle Play', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  if (widget.songs.isNotEmpty) {
                                    final list = List<Song>.from(widget.songs)..shuffle();
                                    context.read<PlayerCubit>().playSongItem(list.first, list);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 140, top: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = widget.songs[index];
                            final isSelected = _selectedSongs.contains(song);

                            return BlocBuilder<PlayerCubit, PlayerState>(
                              builder: (context, playerState) {
                                final currentTrack = playerState.currentTrack;
                                final isActive = currentTrack != null && currentTrack.id == song.uri;
                                final isPlaying = isActive && playerState.isPlaying;

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? colors.primary.withValues(alpha: 0.15)
                                        : (isActive ? colors.surfaceContainer : Colors.transparent),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected 
                                        ? Border.all(color: colors.primary.withValues(alpha: 0.4))
                                        : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isMultiSelectMode)
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (_) => _toggleSelectSong(song),
                                            activeColor: colors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        _buildArtwork(context, song, isActive, isPlaying, 48),
                                      ],
                                    ),
                                    title: Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        color: isActive ? colors.primary : colors.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatDuration(song.duration),
                                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!_isMultiSelectMode)
                                          IconButton(
                                            icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant),
                                            onPressed: () {
                                              SongOptionsBottomSheet.show(context, song);
                                            },
                                          ),
                                      ],
                                    ),
                                    onLongPress: () => _toggleSelectSong(song),
                                    onTap: () {
                                      if (_isMultiSelectMode) {
                                        _toggleSelectSong(song);
                                      } else {
                                        context.read<PlayerCubit>().playSongItem(song, widget.songs);
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          childCount: widget.songs.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isMultiSelectMode
          ? SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(Icons.play_arrow_rounded, color: colors.primary, size: 28),
                        onPressed: _playSelected,
                        tooltip: 'Play Selected',
                      ),
                      IconButton(
                        icon: Icon(Icons.queue_play_next_rounded, color: colors.primary, size: 26),
                        onPressed: _queueSelected,
                        tooltip: 'Add to Queue',
                      ),
                      IconButton(
                        icon: Icon(Icons.playlist_add_rounded, color: colors.primary, size: 28),
                        onPressed: _showAddPlaylistDialog,
                        tooltip: 'Add to Playlist',
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all_rounded, color: Colors.redAccent, size: 28),
                        onPressed: _clearSelection,
                        tooltip: 'Clear Selection',
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
