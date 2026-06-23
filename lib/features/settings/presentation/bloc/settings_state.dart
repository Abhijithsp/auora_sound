import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Color accentColor;
  final String viewPreference;
  final String defaultStartupScreen;
  final List<String> visibleTabs;
  final List<String> allTabs;
  final Map<String, bool> tabVisibility;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accentColor = const Color(0xFF7C4DFF), // Default Sonic Purple
    this.viewPreference = 'list',
    this.defaultStartupScreen = 'Home',
    this.visibleTabs = const ['Home', 'Songs', 'Artists', 'Folders', 'Playlists', 'Settings'],
    this.allTabs = const ['Songs', 'Artists', 'Folders', 'Playlists', 'Albums', 'Favorites'],
    this.tabVisibility = const {
      'Songs': true,
      'Artists': true,
      'Folders': true,
      'Playlists': true,
      'Albums': false,
      'Favorites': false,
    },
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    String? viewPreference,
    String? defaultStartupScreen,
    List<String>? visibleTabs,
    List<String>? allTabs,
    Map<String, bool>? tabVisibility,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      viewPreference: viewPreference ?? this.viewPreference,
      defaultStartupScreen: defaultStartupScreen ?? this.defaultStartupScreen,
      visibleTabs: visibleTabs ?? this.visibleTabs,
      allTabs: allTabs ?? this.allTabs,
      tabVisibility: tabVisibility ?? this.tabVisibility,
    );
  }
}
