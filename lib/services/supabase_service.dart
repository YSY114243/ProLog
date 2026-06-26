import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';
import '../models/challenge.dart';

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
  static const String _profilesTable = 'user_profiles';

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

  // ── CHALLENGES ────────────────────────────────────────────────────────────

  static const String _challengesTable = 'challenges';

  /// Fetches all `challenges` rows belonging to the current user, ordered by
  /// `date` descending (most recent first).
  Future<List<Challenge>> fetchChallenges() async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return [];

    final response = await _client
        .from(_challengesTable)
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Challenge.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a new [challenge] row into `challenges`.
  Future<void> insertChallenge(Challenge challenge) async {
    await _client.from(_challengesTable).insert(challenge.toJson());
  }

  /// Updates an existing [challenge] row identified by [challenge.id].
  Future<void> updateChallenge(Challenge challenge) async {
    await _client
        .from(_challengesTable)
        .update(challenge.toJson())
        .eq('id', challenge.id);
  }

  /// Permanently deletes the challenge with the given [id].
  Future<void> deleteChallenge(String id) async {
    await _client.from(_challengesTable).delete().eq('id', id);
  }

  // ── ROLE & SUPERVISOR ─────────────────────────────────────────────────────

  /// Fetches the user's role from `user_profiles`. Defaults to 'student'
  /// if the profile doesn't exist or an error occurs.
  Future<String> fetchUserRole() async {
    final userId = currentUserId;
    if (userId == null) return 'student';
    try {
      final response = await _client
          .from(_profilesTable)
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      if (response != null && response['role'] != null) {
        return response['role'] as String;
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
    return 'student';
  }

  /// Fetches all daily_logs with `approval_status = 'pending'` for students
  /// assigned to this supervisor.
  Future<List<DailyLog>> getPendingLogsForSupervisor() async {
    final supervisorId = currentUserId;
    if (supervisorId == null) return [];
    
    try {
      // Due to RLS, if the policy `Supervisors can view trainee logs` is active,
      // we can just query all pending logs and the DB filters them. Or explicitly join.
      // We will explicitly query pending logs. The RLS should filter to only their trainees.
      final response = await _client
          .from(_table)
          .select()
          .eq('approval_status', 'pending')
          .order('date', ascending: false);

      return (response as List<dynamic>)
          .map((row) => DailyLog.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending logs: $e');
      return [];
    }
  }

  /// Fetches a list of basic student details for trainees assigned to this supervisor.
  Future<List<Map<String, dynamic>>> getTraineesForSupervisor() async {
    final supervisorId = currentUserId;
    if (supervisorId == null) return [];
    
    try {
      final response = await _client
          .from(_profilesTable)
          .select('id, full_name, major, uni_name') // Assuming these columns or we fetch from auth?
          // Note: If user_metadata isn't in user_profiles, we might only get ID. 
          // Assuming user_profiles stores some basic info, or we rely on auth metadata if accessible.
          // For now, let's fetch 'id'. 
          .eq('supervisor_id', supervisorId);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching trainees: $e');
      return [];
    }
  }

  /// Updates the `approval_status` of a specific log.
  Future<void> updateLogApprovalStatus(String logId, String status) async {
    await _client
        .from(_table)
        .update({'approval_status': status})
        .eq('id', logId);
  }

  // ── IMAGE HOSTING ─────────────────────────────────────────────────────────

  /// Generates a random 6-character code, saves it to the student's profile, and returns it.
  Future<String> generateSupervisorInviteCode() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = _client.auth.currentSession?.user.id.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    // Just a quick random string generator. For more robustness use dart:math Random.
    final rand = List.generate(6, (i) => chars[(random + i * 7) % chars.length]).join();

    await _client.from(_profilesTable).upsert({
      'id': userId,
      'supervisor_invite_code': rand,
    }); // Using upsert in case the profile row doesn't exist yet for the student

    return rand;
  }

  /// Registers a new supervisor and links them to the student with the given invite code.
  Future<void> registerSupervisor(String email, String password, String name, String inviteCode) async {
    // 1. Verify the invite code exists FIRST (to avoid orphaned auth users if code is wrong)
    // Actually, RLS might prevent reading without being logged in. We'll sign up first, 
    // but standard practice is to rely on backend logic. Assuming the RLS allows reading via the invite code:
    
    // We sign up the user.
    final authRes = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    
    final newUserId = authRes.user?.id;
    if (newUserId == null) {
      throw Exception('Failed to create account.');
    }

    // Now query for the student using the invite code
    final studentRes = await _client
        .from(_profilesTable)
        .select()
        .eq('supervisor_invite_code', inviteCode)
        .maybeSingle();

    if (studentRes == null) {
      // If we could safely delete the auth user here, we would.
      throw Exception('Invalid Invite Code');
    }

    // Insert the supervisor profile
    await _client.from(_profilesTable).upsert({
      'id': newUserId,
      'full_name': name,
      'role': 'supervisor',
    });

    // Link student to supervisor & clear invite code
    await _client.from(_profilesTable).update({
      'supervisor_id': newUserId,
      'supervisor_invite_code': null,
    }).eq('id', studentRes['id']);
  }

  /// ImgBB free-tier API key.
  ///
  /// Get yours at https://api.imgbb.com/ (free account, no credit card).
  /// For production deployments set this via an environment variable /
  /// build-time secret rather than hardcoding it here.
  static const String _imgbbApiKey = 'c2366f68046d02673cab6f1885d708f1';

  /// Uploads [bytes] to ImgBB and returns the public HTTPS image URL, or
  /// `null` on failure.
  ///
  /// Uses a standard `multipart/form-data` POST — no local filesystem access
  /// is required, making this safe for serverless environments (Vercel, etc.).
  Future<String?> uploadImageToImgBB(Uint8List bytes) async {
    try {
      final base64Image = base64Encode(bytes);

      final uri = Uri.parse(
          'https://api.imgbb.com/1/upload?key=$_imgbbApiKey');

      final response = await http.post(
        uri,
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        return data?['url'] as String?;
      } else {
        debugPrint('ImgBB upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image to ImgBB: $e');
      return null;
    }
  }
}
