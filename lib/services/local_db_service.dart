import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_log.dart';

class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  String _getLogsKey(String userId) => 'offline_logs_$userId';

  Future<List<DailyLog>> fetchLogs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getLogsKey(userId));
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DailyLog.fromJson(json as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLogsList(String userId, List<DailyLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_getLogsKey(userId), jsonEncode(jsonList));
  }

  Future<void> insertLog(DailyLog log) async {
    final logs = await fetchLogs(log.userId);
    // Overwrite if same ID exists to avoid duplicates
    logs.removeWhere((l) => l.id == log.id);
    logs.add(log);
    await _saveLogsList(log.userId, logs);
  }

  Future<void> updateLog(DailyLog log) async {
    final logs = await fetchLogs(log.userId);
    final index = logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      logs[index] = log;
      await _saveLogsList(log.userId, logs);
    }
  }

  Future<void> deleteLog(String id) async {
    // We need userId to find it. Since we only delete from current user's feed,
    // we can search through all keys or require userId.
    // For simplicity, we iterate over all keys starting with offline_logs_
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('offline_logs_'));
    
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final logs = jsonList.map((json) => DailyLog.fromJson(json as Map<String, dynamic>)).toList();
        final initialLength = logs.length;
        logs.removeWhere((l) => l.id == id);
        
        if (logs.length != initialLength) {
          await prefs.setString(key, jsonEncode(logs.map((l) => l.toJson()).toList()));
          break;
        }
      }
    }
  }

  Future<List<DailyLog>> fetchUnsyncedLogs(String userId) async {
    final logs = await fetchLogs(userId);
    return logs.where((l) => l.isSynced == false).toList();
  }

  Future<void> syncLogsWithSupabase(List<DailyLog> supabaseLogs, String userId) async {
    final localLogs = await fetchLogs(userId);
    
    // Map existing local logs by ID
    final Map<String, DailyLog> localMap = {for (var l in localLogs) l.id: l};

    for (final sLog in supabaseLogs) {
      final existing = localMap[sLog.id];
      // Only overwrite if it doesn't exist locally, or if the local version is fully synced.
      // Do not overwrite an unsynced local log (which might have offline edits/images).
      if (existing == null || existing.isSynced) {
        localMap[sLog.id] = sLog;
      }
    }

    await _saveLogsList(userId, localMap.values.toList());
  }
}
