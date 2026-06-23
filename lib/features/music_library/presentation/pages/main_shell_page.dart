import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_page.dart';
import 'songs_page.dart';
import 'artists_page.dart';
import 'albums_page.dart';
import 'folders_page.dart';
import 'playlists_page.dart';
import 'favorites_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../player/presentation/bloc/player_cubit.dart';
import '../../../player/presentation/bloc/player_state.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../player/presentation/pages/now_playing_page.dart';
import '../../../../core/widgets/glowing_background.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  String _currentTab = 'Home';

  Widget _getPage(String tabName) {
    switch (tabName) {
      case 'Home':
        return const HomePage();
      case 'Songs':
        return const SongsPage();
      case 'Artists':
        return const ArtistsPage();
      case 'Albums':
        return const AlbumsPage();
      case 'Folders':
        return const FoldersPage();
      case 'Playlists':
        return const PlaylistsPage();
      case 'Favorites':
        return const FavoritesPage();
      case 'Settings':
        return const SettingsPage();
      default:
        return const HomePage();
    }
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName) {
      case 'Home':
        return Icons.home_rounded;
      case 'Songs':
        return Icons.music_note_rounded;
      case 'Artists':
        return Icons.person_rounded;
      case 'Albums':
        return Icons.album_rounded;
      case 'Folders':
        return Icons.folder_rounded;
      case 'Playlists':
        return Icons.queue_music_rounded;
      case 'Favorites':
        return Icons.favorite_rounded;
      case 'Settings':
        return Icons.settings_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final tabs = settingsState.visibleTabs;
        
        // Safety check if current tab was hidden
        if (!tabs.contains(_currentTab)) {
          _currentTab = tabs.first;
        }

        final currentIdx = tabs.indexOf(_currentTab);

        // Sidebar Widget (NavigationDrawer or custom Column)
        Widget buildSidebar() {
          return Container(
            width: 250,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.8),
              border: Border(
                right: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Text(
                      'Aura Sound',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tabs.length,
                      itemBuilder: (context, index) {
                        final tab = tabs[index];
                        final isSelected = tab == _currentTab;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getTabIcon(tab),
                              color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                            ),
                            title: Text(
                              tab,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _currentTab = tab;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          drawer: isTablet ? null : Drawer(
            child: buildSidebar(),
          ),
          body: GlowingBackground(
            child: Row(
              children: [
                if (isTablet) buildSidebar(),
                Expanded(
                  child: Stack(
                    children: [
                      // Render Screens preserving scroll/states via IndexedStack
                      IndexedStack(
                        index: currentIdx,
                        children: tabs.map((tab) => _getPage(tab)).toList(),
                      ),
                      
                      // Floating MiniPlayer capsule
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: isTablet ? 16 : 96,
                        child: BlocBuilder<PlayerCubit, PlayerState>(
                          builder: (context, playerState) {
                            if (playerState.currentTrack != null) {
                              return MiniPlayer(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => BlocProvider.value(
                                        value: context.read<PlayerCubit>(),
                                        child: const NowPlayingPage(),
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(0.0, 1.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeOutCubic;
                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Navigation Bar for Mobile Phones
          bottomNavigationBar: isTablet
              ? null
              : Container(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.7),
                    border: Border(
                      top: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: tabs.map((tab) {
                          final isSelected = tab == _currentTab;
                          if (isSelected) {
                            return GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getTabIcon(tab), color: colors.onSecondaryContainer, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      tab,
                                      style: TextStyle(
                                        color: colors.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentTab = tab;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getTabIcon(tab), color: colors.onSurfaceVariant, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  tab,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
