import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';

/// Singleton service that owns all Supabase interactions for InternLog.
///
/// Usage:
/// ```dart
/// // In main():
/// await SupabaseService.initialize();
///
/// // Anywhere else:
/// final logs = await SupabaseService.instance.fetchLogs();
/// await SupabaseService.instance.insertLog(myLog);
/// ```
class SupabaseService {
  SupabaseService._();

  /// The single shared instance.
  static final SupabaseService instance = SupabaseService._();

  // ── Supabase project credentials ──────────────────────────────────────────
  static const String _supabaseUrl = 'https://eqxbrbaiwvkmjspyvkin.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxeGJyYmFpd3ZrbWpzcHl2a2luIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NzA0MTAsImV4cCI6MjA5NzE0NjQxMH0'
      '.oWYHzmjpqiLWA3HoPcomlzCGGISAFbuP6tBX-_ov3qU';

  static const String _table = 'daily_logs';

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Initialises the Supabase client. **Must** be called in [main] before
  /// [runApp], after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: _anonKey, // will become publishableKey in next major version
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  SupabaseClient get _client => Supabase.instance.client;

  /// Returns the UID of the currently signed-in user, or `null` if not
  /// authenticated.
  String? get currentUserId => _client.auth.currentUser?.id;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all `daily_logs` rows belonging to the current user, ordered by
  /// `date` descending (most recent first).
  ///
  /// Returns an empty list if no user is signed in.
  ///
  /// Throws a [PostgrestException] on database / RLS errors.
  Future<List<DailyLog>> fetchLogs() async {
    final userId = currentUserId;

    // Guard: no authenticated user → return empty list without hitting DB.
    if (userId == null || userId.isEmpty) return [];

    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List<dynamic>)
        .map((row) => DailyLog.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Inserts a new [log] row into `daily_logs`.
  ///
  /// The `id` column is omitted from the payload — Supabase assigns a UUID via
  /// `gen_random_uuid()`. The [log.userId] must match the signed-in user's UID
  /// for the RLS policy to allow the write.
  ///
  /// Throws a [PostgrestException] on database / RLS errors.
  Future<void> insertLog(DailyLog log) async {
    await _client.from(_table).insert(log.toJson());
  }

  /// Updates an existing [log] row identified by [log.id].
  ///
  /// Only the mutable fields are sent (date, task_type, description,
  /// issues_found, image_url).  The [log.id] must be a valid UUID.
  ///
  /// Throws a [PostgrestException] on database / RLS errors.
  Future<void> updateLog(DailyLog log) async {
    await _client
        .from(_table)
        .update(log.toJson())
        .eq('id', log.id);
  }

  /// Permanently deletes the row with the given [id] from `daily_logs`.
  ///
  /// Throws a [PostgrestException] on database / RLS errors.
  Future<void> deleteLog(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Returns the number of logs that contain an uploaded image for the current user.
  Future<int> getImageUploadCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;
    
    final res = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .not('image_url', 'is', null);
    
    return (res as List).length;
  }

  // ── STORAGE ───────────────────────────────────────────────────────────────

  /// Uploads an image to the 'log_images' bucket and returns its public URL.
  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    if (currentUserId == null) return null;
    try {
      final path = '$currentUserId/$fileName';
      await _client.storage.from('log_images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from('log_images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
