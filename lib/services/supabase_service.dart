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

  /// Fetches all trainees for the coordinator view.
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final res = await _client
        .from(_profilesTable)
        .select()
        .eq('role', 'student');
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Fetches the details of a specific supervisor.
  Future<Map<String, dynamic>?> getSupervisorProfile(String supervisorId) async {
    final res = await _client
        .from(_profilesTable)
        .select()
        .eq('id', supervisorId)
        .maybeSingle();
    return res;
  }

  /// Returns the current signed-in user's UID or `null` if none.
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

  /// Fetches the current user's profile.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final res = await _client
        .from(_profilesTable)
        .select()
        .eq('id', uid)
        .maybeSingle();
    return res;
  }

  /// Updates the current user's profile.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client
        .from(_profilesTable)
        .update(data)
        .eq('id', uid);
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

  /// Registers a new Company Supervisor using the student's invite code.
  Future<void> registerSupervisor(
    String email,
    String password,
    String name,
    String inviteCode,
  ) async {
    // 1. Securely verify the invite code via RPC (bypassing RLS for anonymous users)
    final isValidCode = await _client.rpc(
      'check_invite_code',
      params: {'p_code': inviteCode},
    ) as bool? ?? false;

    if (!isValidCode) {
      throw Exception('Invalid Student Invite Code. Please check the code and try again.');
    }

    // 2. Register the supervisor via Supabase Auth
    final authRes = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );

    final user = authRes.user;
    if (user == null) {
      throw Exception('Failed to create supervisor account.');
    }

    // 3. Upsert the new supervisor's profile to explicitly set their role
    await _client.from(_profilesTable).upsert({
      'id': user.id,
      'full_name': name,
      'role': 'supervisor',
    });

    // 4. Link the student to this supervisor and consume the invite code via RPC
    final response = await _client.rpc(
      'link_supervisor_to_student',
      params: {
        'p_invite_code': inviteCode,
        'p_supervisor_id': user.id,
      },
    );

    // The RPC should return a boolean
    final bool success = response as bool? ?? false;

    if (!success) {
      // Note: Client cannot delete Auth users without service role. User remains unlinked.
      throw Exception('Invalid Invite Code or linking failed.');
    }
  }

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


  // ── EVALUATIONS ───────────────────────────────────────────────────────────

  static const String _evaluationsTable = 'supervisor_evaluations';

  /// Submits the TA-FORM 03 supervisor evaluation.
  Future<void> submitSupervisorEvaluation(Map<String, dynamic> evaluationData) async {
    // 1. Insert the evaluation record
    await _client.from(_evaluationsTable).insert(evaluationData);

    // 2. Update the student's profile to reflect submission
    final studentId = evaluationData['student_id'] as String?;
    if (studentId != null) {
      await _client
          .from(_profilesTable)
          .update({'is_evaluation_submitted': true})
          .eq('id', studentId);
    }
  }

  /// Returns a list of student IDs that the current supervisor has evaluated.
  Future<List<String>> getEvaluatedStudentIds() async {
    final supervisorId = currentUserId;
    if (supervisorId == null) return [];

    final res = await _client
        .from(_evaluationsTable)
        .select('student_id')
        .eq('supervisor_id', supervisorId);

    return (res as List).map((row) => row['student_id'] as String).toList();
  }

  /// Fetches the evaluation for a specific student, if any.
  Future<Map<String, dynamic>?> getEvaluationForStudent(String studentId) async {
    final res = await _client
        .from(_evaluationsTable)
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    return res;
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
