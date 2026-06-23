import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackHistoryTracker {
  final SharedPreferences _prefs;

  PlaybackHistoryTracker(this._prefs);

  // Favorites
  List<String> getFavorites() {
    return _prefs.getStringList('favorites_list') ?? [];
  }

  Future<void> toggleFavorite(String songId) async {
    final list = getFavorites();
    if (list.contains(songId)) {
      list.remove(songId);
    } else {
      list.add(songId);
    }
    await _prefs.setStringList('favorites_list', list);
  }

  bool isFavorite(String songId) {
    return getFavorites().contains(songId);
  }

  // Recently Played
  List<String> getRecentlyPlayed() {
    return _prefs.getStringList('recently_played_list') ?? [];
  }

  Future<void> addToRecentlyPlayed(String songId) async {
    final list = getRecentlyPlayed();
    list.remove(songId); // Remove if exists to move to top
    list.insert(0, songId);
    if (list.length > 20) {
      list.removeLast();
    }
    await _prefs.setStringList('recently_played_list', list);
  }

  // Most Played
  Map<String, int> getPlayCounts() {
    final raw = _prefs.getString('play_counts_map') ?? '{}';
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> incrementPlayCount(String songId) async {
    final counts = getPlayCounts();
    counts[songId] = (counts[songId] ?? 0) + 1;
    await _prefs.setString('play_counts_map', json.encode(counts));
  }
}
