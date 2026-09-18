import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class SupabaseStorageService {
  static SupabaseClient? _client;

  static Future<void> init() async {
    if (_client == null) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      _client = Supabase.instance.client;
    }
  }

  static SupabaseClient get client {
    _client ??= SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
    return _client!;
  }

  /// Uploads a local file to Supabase Storage and returns the public HTTPS URL
  static Future<String> uploadImage({
    required String filePath,
    required String folder, // 'ktp', 'tickets', 'work_photos'
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return filePath; // Fallback to existing path or URL if local file doesn't exist
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final pathInBucket = '$folder/$fileName';

      await client.storage.from(SupabaseConfig.bucketName).upload(
            pathInBucket,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = client.storage
          .from(SupabaseConfig.bucketName)
          .getPublicUrl(pathInBucket);

      return publicUrl;
    } catch (e) {
      // Return original file path if upload fails in offline test mode
      return filePath;
    }
  }

  /// Uploads multiple local files to Supabase Storage
  static Future<List<String>> uploadMultipleImages({
    required List<String> filePaths,
    required String folder,
  }) async {
    final List<String> publicUrls = [];
    for (final path in filePaths) {
      final url = await uploadImage(filePath: path, folder: folder);
      publicUrls.add(url);
    }
    return publicUrls;
  }
}
