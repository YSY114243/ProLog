import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentService {
  DocumentService._();
  static final instance = DocumentService._();
  
  final _client = Supabase.instance.client;

  /// Prompts the user to pick a PDF and uploads it to Supabase Storage.
  /// Then inserts a tracking record into submitted_documents.
  Future<bool> uploadDocument({
    required String studentId,
    required String formType,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      final fileBytes = file.bytes;
      if (fileBytes == null) return false;

      final extension = file.extension ?? 'pdf';
      final fileName = '${studentId}_${formType}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '$studentId/$fileName';

      // Upload to Supabase Storage
      await _client.storage.from('training_docs').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
      );

      // Get public URL
      final publicUrl = _client.storage.from('training_docs').getPublicUrl(path);

      // Insert record
      final uploaderId = _client.auth.currentUser!.id;
      await _client.from('submitted_documents').insert({
        'student_id': studentId,
        'uploaded_by': uploaderId,
        'form_type': formType,
        'file_url': publicUrl,
      });

      return true;
    } catch (e) {
      debugPrint('Document upload error: $e');
      return false;
    }
  }

  /// Fetches all submitted documents for a specific student
  Future<List<Map<String, dynamic>>> fetchSubmittedForms(String studentId) async {
    try {
      final response = await _client
          .from('submitted_documents')
          .select('*')
          .eq('student_id', studentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch documents error: $e');
      return [];
    }
  }
}
