import 'package:flutter/material.dart';
import '../../../../core/widgets/glassmorphic_container.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final mockPlaylists = [
      {'title': 'Morning Focus', 'tag': 'Wake Up', 'gradient': [const Color(0xFFFF8E53), const Color(0xFFFF007F)]},
      {'title': 'Deep Bass', 'tag': 'Heavy Beat', 'gradient': [const Color(0xFF11998e), const Color(0xFF38ef7d)]},
      {'title': 'Chill Waves', 'tag': 'Ambient', 'gradient': [const Color(0xFF00c6ff), const Color(0xFF0072ff)]},
      {'title': 'Hyperactive', 'tag': 'Electronic', 'gradient': [const Color(0xFF7F00FF), const Color(0xFFFF007F)]},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
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
              'Playlists',
              style: theme.appBarTheme.titleTextStyle?.copyWith(color: colors.onSurface),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 120.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final playlist = mockPlaylists[index];
                  final title = playlist['title'] as String;
                  final tag = playlist['tag'] as String;
                  final grad = playlist['gradient'] as List<Color>;

                  return GestureDetector(
                    onTap: () {},
                    child: GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(20),
                      borderOpacity: 0.08,
                      backgroundOpacity: 0.04,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: grad,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 36),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            tag,
                            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: mockPlaylists.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
