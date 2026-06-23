import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;

  SettingsCubit(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final themeStr = _prefs.getString('themeMode') ?? 'dark';
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => ThemeMode.dark,
    );

    final colorVal = _prefs.getInt('accentColor') ?? 0xFF7C4DFF;
    final accentColor = Color(colorVal);

    final viewPref = _prefs.getString('viewPreference') ?? 'list';
    final startupScreen = _prefs.getString('defaultStartupScreen') ?? 'Home';

    final tabOrder = _prefs.getStringList('tabOrder') ?? 
        const ['Songs', 'Artists', 'Folders', 'Playlists', 'Albums', 'Favorites'];

    final tabVisibilityMap = <String, bool>{};
    for (final tab in tabOrder) {
      // Default to true for Songs, Artists, Folders, Playlists, false for Albums, Favorites
      final defaultVal = (tab == 'Songs' || tab == 'Artists' || tab == 'Folders' || tab == 'Playlists');
      tabVisibilityMap[tab] = _prefs.getBool('tab_visible_$tab') ?? defaultVal;
    }

    final visibleTabs = ['Home'];
    for (final tab in tabOrder) {
      if (tabVisibilityMap[tab] == true) {
        visibleTabs.add(tab);
      }
    }
    visibleTabs.add('Settings');

    final appIcon = _prefs.getString('appIcon') ?? 'Default';

    emit(SettingsState(
      themeMode: themeMode,
      accentColor: accentColor,
      viewPreference: viewPref,
      defaultStartupScreen: startupScreen,
      visibleTabs: visibleTabs,
      allTabs: tabOrder,
      tabVisibility: tabVisibilityMap,
      appIcon: appIcon,
    ));
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _prefs.setString('themeMode', mode.name);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> updateAccentColor(Color color) async {
    await _prefs.setInt('accentColor', color.toARGB32());
    emit(state.copyWith(accentColor: color));
  }

  Future<void> updateViewPreference(String pref) async {
    await _prefs.setString('viewPreference', pref);
    emit(state.copyWith(viewPreference: pref));
  }

  Future<void> updateDefaultStartupScreen(String screen) async {
    await _prefs.setString('defaultStartupScreen', screen);
    emit(state.copyWith(defaultStartupScreen: screen));
  }

  Future<void> updateAppIcon(String iconKey) async {
    await _prefs.setString('appIcon', iconKey);
    try {
      if (await FlutterDynamicIconPlus.supportsAlternateIcons) {
        // 'Default' is represented by null to revert to the primary icon
        final String? alternateIconName = iconKey == 'Default' ? null : iconKey;
        await FlutterDynamicIconPlus.setAlternateIconName(iconName: alternateIconName);
      }
    } catch (e) {
      debugPrint("Failed to set alternate icon: $e");
    }
    emit(state.copyWith(appIcon: iconKey));
  }

  Future<void> toggleTabVisibility(String tab, bool visible) async {
    await _prefs.setBool('tab_visible_$tab', visible);
    final newVisibility = Map<String, bool>.from(state.tabVisibility)..[tab] = visible;
    _updateVisibleTabs(state.allTabs, newVisibility);
  }

  Future<void> reorderTabs(int oldIndex, int newIndex) async {
    final list = List<String>.from(state.allTabs);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await _prefs.setStringList('tabOrder', list);
    _updateVisibleTabs(list, state.tabVisibility);
  }

  void _updateVisibleTabs(List<String> allTabs, Map<String, bool> visibility) {
    final visibleTabs = ['Home'];
    for (final tab in allTabs) {
      if (visibility[tab] == true) {
        visibleTabs.add(tab);
      }
    }
    visibleTabs.add('Settings');

    emit(state.copyWith(
      allTabs: allTabs,
      tabVisibility: visibility,
      visibleTabs: visibleTabs,
    ));
  }
}
