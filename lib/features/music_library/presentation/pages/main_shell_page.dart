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
import '../../../../core/theme/glass_style.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/surface_card.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  /// Opens the shell's navigation drawer. Tab pages have their own Scaffold,
  /// so `Scaffold.of(context)` there finds a Scaffold without a drawer.
  static void openDrawer(BuildContext context) {
    context
        .findAncestorStateOfType<_MainShellPageState>()
        ?._scaffoldKey
        .currentState
        ?.openDrawer();
  }

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  String _currentTab = 'Home';
  bool _initialTabSet = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

        // Apply defaultStartupScreen once on first build
        if (!_initialTabSet) {
          final startup = settingsState.defaultStartupScreen;
          _currentTab = tabs.contains(startup) ? startup : tabs.first;
          _initialTabSet = true;
        }

        // Safety check if current tab was hidden
        if (!tabs.contains(_currentTab)) {
          _currentTab = tabs.first;
        }

        final currentIdx = tabs.indexOf(_currentTab);

        void selectTab(String tab) {
          setState(() {
            _currentTab = tab;
          });
        }

        final glass = GlassStyle.of(context);

        Widget buildSidebar({required bool inline}) {
          final drawer = NavigationDrawer(
            elevation: inline ? 0 : null,
            backgroundColor: glass.enabled ? glass.fill(colors) : null,
            selectedIndex: currentIdx,
            onDestinationSelected: (index) {
              selectTab(tabs[index]);
              if (!inline) {
                _scaffoldKey.currentState?.closeDrawer();
              }
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
                child: Text(
                  'Aura Sound',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
              ),
              for (final tab in tabs)
                NavigationDrawerDestination(
                  icon: Icon(_getTabIcon(tab)),
                  label: Text(tab),
                ),
            ],
          );
          // The slide-out drawer floats over content, so frost it with blur.
          if (inline || !glass.enabled) return drawer;
          return ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
              child: drawer,
            ),
          );
        }

        final bool hasOverflow = tabs.length > 5;
        final List<String> bottomBarTabs = hasOverflow
            ? [...tabs.take(4), 'More']
            : tabs;

        final bool isCurrentTabInBottomBar = bottomBarTabs.contains(_currentTab);

        return AuroraBackground(
          child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: buildSidebar(inline: false),
          body: Row(
            children: [
              if (isTablet)
                SizedBox(width: 280, child: buildSidebar(inline: true)),
              Expanded(
                child: Stack(
                  children: [
                    // Render Screens preserving scroll/states via IndexedStack
                    SizedBox.expand(
                      child: IndexedStack(
                        index: currentIdx,
                        children: tabs.map((tab) => _getPage(tab)).toList(),
                      ),
                    ),

                    // Floating MiniPlayer capsule
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: isTablet ? (MediaQuery.of(context).padding.bottom + 8) : 0,
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
          // Bottom Navigation Bar for Mobile Phones
          bottomNavigationBar: isTablet
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SurfaceCard(
                      blur: true,
                      color: glass.enabled ? null : colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(28),
                      child: NavigationBar(
                        height: 72,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        selectedIndex: isCurrentTabInBottomBar
                            ? bottomBarTabs.indexOf(_currentTab)
                            : bottomBarTabs.length - 1,
                        onDestinationSelected: (index) {
                          final tab = bottomBarTabs[index];
                          if (tab == 'More') {
                            _scaffoldKey.currentState?.openDrawer();
                          } else {
                            selectTab(tab);
                          }
                        },
                        destinations: [
                          for (final tab in bottomBarTabs)
                            NavigationDestination(
                              icon: Icon(tab == 'More' ? Icons.apps_rounded : _getTabIcon(tab)),
                              label: tab,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }
}
