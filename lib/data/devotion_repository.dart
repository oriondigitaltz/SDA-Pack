import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/devotion.dart';

const String _kAssetPath = 'assets/devotions/devotions.json';

const String _kReminderEnabledKey = 'reminder_enabled';
const String _kReminderHourKey = 'reminder_hour';
const String _kReminderMinuteKey = 'reminder_minute';
const String _kReminderDaysKey = 'reminder_days';
const String _kReadPrefix = 'read:';
const String _kFavPrefix = 'fav:';

class DevotionRepository {
  final Box<dynamic> _progressBox;

  /// Past studies: devotions fetched from the online feed, keyed
  /// `yyyy-MM-dd` → JSON string. Entries are never evicted.
  final Box<String> _cacheBox;
  Map<String, Devotion>? _devotions;

  DevotionRepository(this._progressBox, this._cacheBox);

  static Future<DevotionRepository> open() async {
    final box = await Hive.openBox<dynamic>('devotion_progress');
    final cache = await Hive.openBox<String>('devotion_cache');
    return DevotionRepository(box, cache);
  }

  Future<Map<String, Devotion>> _load() async {
    if (_devotions != null) return _devotions!;
    final raw = await rootBundle.loadString(_kAssetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _devotions = {
      for (final entry in decoded.entries)
        entry.key: Devotion.fromJson(entry.key, entry.value as Map<String, dynamic>),
    };
    return _devotions!;
  }

  static String monthDayKey(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String dateKey(DateTime date) =>
      '${date.year}-${monthDayKey(date)}';

  /// Cached (fetched) devotion first, then the bundled year-agnostic file.
  Future<Devotion?> forDate(DateTime date) async {
    final cached = cachedForDate(date);
    if (cached != null) return cached;
    final devotions = await _load();
    final devotion = devotions[monthDayKey(date)];
    if (devotion != null) return devotion;
    // Fallback: content file without a Feb 29 entry.
    if (date.month == 2 && date.day == 29) return devotions['02-28'];
    return null;
  }

  // --- Past studies (online feed cache) ---

  Devotion? cachedForDate(DateTime date) {
    final raw = _cacheBox.get(dateKey(date));
    if (raw == null) return null;
    return _decodeCached(dateKey(date), raw);
  }

  Devotion _decodeCached(String key, String raw) {
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return Devotion.fromJson(key.substring(5), decoded, date: key);
  }

  Future<void> cacheDevotion(String dateKey, Map<String, dynamic> json_) async {
    await _cacheBox.put(dateKey, json.encode(json_));
  }

  bool hasCached(DateTime date) => _cacheBox.containsKey(dateKey(date));

  /// All fetched devotions, newest first.
  List<Devotion> pastStudies({int? limit}) {
    final keys = _cacheBox.keys.cast<String>().toList()..sort((a, b) => b.compareTo(a));
    final selected = limit == null ? keys : keys.take(limit);
    return [
      for (final key in selected) _decodeCached(key, _cacheBox.get(key)!),
    ];
  }

  // --- Read tracking ---

  bool isRead(DateTime date) => _progressBox.get('$_kReadPrefix${dateKey(date)}') == true;

  Future<void> setRead(DateTime date, bool read) async {
    final key = '$_kReadPrefix${dateKey(date)}';
    if (read) {
      await _progressBox.put(key, true);
    } else {
      await _progressBox.delete(key);
    }
  }

  /// Consecutive read days ending today (or yesterday, if today is unread yet).
  int currentStreak(DateTime today) {
    var day = DateTime(today.year, today.month, today.day);
    if (!isRead(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (isRead(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Set<int> readDaysInMonth(int year, int month) {
    final days = <int>{};
    final lastDay = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= lastDay; d++) {
      if (isRead(DateTime(year, month, d))) days.add(d);
    }
    return days;
  }

  Set<int> cachedDaysInMonth(int year, int month) {
    final days = <int>{};
    final lastDay = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= lastDay; d++) {
      if (hasCached(DateTime(year, month, d))) days.add(d);
    }
    return days;
  }

  // --- Favorites ---

  bool isFavorite(String dateKey) => _progressBox.get('$_kFavPrefix$dateKey') == true;

  Future<void> setFavorite(String dateKey, bool favorite) async {
    final key = '$_kFavPrefix$dateKey';
    if (favorite) {
      await _progressBox.put(key, true);
    } else {
      await _progressBox.delete(key);
    }
  }

  Set<String> get favoriteDateKeys => {
        for (final key in _progressBox.keys.cast<String>())
          if (key.startsWith(_kFavPrefix)) key.substring(_kFavPrefix.length),
      };

  // --- Reminder settings ---

  bool get reminderEnabled => _progressBox.get(_kReminderEnabledKey) == true;
  int get reminderHour => _progressBox.get(_kReminderHourKey) as int? ?? 6;
  int get reminderMinute => _progressBox.get(_kReminderMinuteKey) as int? ?? 0;

  /// Selected weekdays (DateTime.monday..sunday = 1..7). Defaults to all.
  Set<int> get reminderDays {
    final stored = _progressBox.get(_kReminderDaysKey);
    if (stored is List) return stored.cast<int>().toSet();
    return {1, 2, 3, 4, 5, 6, 7};
  }

  Future<void> setReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required Set<int> days,
  }) async {
    await _progressBox.put(_kReminderEnabledKey, enabled);
    await _progressBox.put(_kReminderHourKey, hour);
    await _progressBox.put(_kReminderMinuteKey, minute);
    await _progressBox.put(_kReminderDaysKey, days.toList()..sort());
  }
}
