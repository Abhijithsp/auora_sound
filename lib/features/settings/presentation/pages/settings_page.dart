import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final List<Map<String, dynamic>> accentColors = [
      {'name': 'Lavender', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Fluid Blue', 'color': const Color(0xFF3E82F7)},
      {'name': 'Aura Pink', 'color': const Color(0xFFFF4B7D)},
      {'name': 'Emerald', 'color': const Color(0xFF00C853)},
      {'name': 'Amber', 'color': const Color(0xFFFFAB00)},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final settingsCubit = context.read<SettingsCubit>();

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
                  'Settings',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(color: colors.onSurface),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader(context, 'App Customization'),

                  // Theme Mode Selector
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      borderOpacity: 0.08,
                      backgroundOpacity: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.dark_mode_rounded, color: colors.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Theme Mode', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Choose light, dark, or system default theme', style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SegmentedButton<ThemeMode>(
                                  segments: const [
                                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                                  ],
                                  selected: {state.themeMode},
                                  onSelectionChanged: (selected) {
                                    settingsCubit.updateThemeMode(selected.first);
                                  },
                                  style: SegmentedButton.styleFrom(
                                    selectedBackgroundColor: colors.primaryContainer,
                                    selectedForegroundColor: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Accent Color Selector
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      borderOpacity: 0.08,
                      backgroundOpacity: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_rounded, color: colors.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Accent Color', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Select your primary signature accent color', style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: accentColors.length,
                              itemBuilder: (context, index) {
                                final colorItem = accentColors[index];
                                final Color col = colorItem['color'] as Color;
                                final isSelected = state.accentColor.toARGB32() == col.toARGB32();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: GestureDetector(
                                    onTap: () => settingsCubit.updateAccentColor(col),
                                    child: CircleAvatar(
                                      backgroundColor: col,
                                      radius: 20,
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Layout & Startup Settings
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      borderOpacity: 0.08,
                      backgroundOpacity: 0.04,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.grid_view_rounded, color: colors.primary),
                            title: const Text('View Preference', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Set grid or list view for music lists'),
                            trailing: Switch(
                              value: state.viewPreference == 'grid',
                              onChanged: (val) {
                                settingsCubit.updateViewPreference(val ? 'grid' : 'list');
                              },
                              activeThumbColor: colors.primary,
                            ),
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.start_rounded, color: colors.primary),
                            title: const Text('Startup Screen', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Set the default screen when app opens'),
                            trailing: DropdownButton<String>(
                              value: state.defaultStartupScreen,
                              dropdownColor: colors.surfaceContainerHigh,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 'Home', child: Text('Home')),
                                DropdownMenuItem(value: 'Songs', child: Text('Songs')),
                                DropdownMenuItem(value: 'Artists', child: Text('Artists')),
                                DropdownMenuItem(value: 'Folders', child: Text('Folders')),
                                DropdownMenuItem(value: 'Playlists', child: Text('Playlists')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  settingsCubit.updateDefaultStartupScreen(val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildSectionHeader(context, 'Tab Management'),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: Text(
                      'Drag the icons to reorder navigation tabs or toggle the switches to show/hide them.',
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: GlassmorphicContainer(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      borderOpacity: 0.08,
                      backgroundOpacity: 0.04,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.allTabs.length,
                        itemBuilder: (context, index) {
                          final tabName = state.allTabs[index];
                          final isVisible = state.tabVisibility[tabName] ?? false;

                          IconData tabIcon = Icons.music_note_rounded;
                          if (tabName == 'Songs') tabIcon = Icons.music_note_rounded;
                          if (tabName == 'Artists') tabIcon = Icons.person_rounded;
                          if (tabName == 'Folders') tabIcon = Icons.folder_rounded;
                          if (tabName == 'Playlists') tabIcon = Icons.queue_music_rounded;
                          if (tabName == 'Albums') tabIcon = Icons.album_rounded;
                          if (tabName == 'Favorites') tabIcon = Icons.favorite_rounded;

                          return ListTile(
                            key: ValueKey(tabName),
                            leading: Icon(Icons.drag_indicator_rounded, color: colors.onSurfaceVariant),
                            title: Row(
                              children: [
                                Icon(tabIcon, color: colors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(tabName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            trailing: Switch(
                              value: isVisible,
                              onChanged: (val) {
                                settingsCubit.toggleTabVisibility(tabName, val);
                              },
                              activeThumbColor: colors.primary,
                            ),
                          );
                        },
                        onReorderItem: (oldIdx, newIdx) {
                          settingsCubit.reorderTabs(oldIdx, newIdx);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 140),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
