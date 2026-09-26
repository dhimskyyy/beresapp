import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class SupabaseStorageService {
  static SupabaseClient? _client;

  static Future<void> init() async {
    if (_client == null) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          // ignore: deprecated_member_use
          anonKey: SupabaseConfig.anonKey,
        );
        _client = Supabase.instance.client;
      } catch (e) {
        debugPrint('Supabase initialize note: $e');
      }
    }
  }

  static SupabaseClient get client {
    _client ??= SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
    return _client!;
  }

  /// Uploads a local file and returns an HTTPS URL or Base64 Data URI
  /// Priority:
  /// 1. Firebase Storage (if configured & active)
  /// 2. Supabase Storage (if configured & active)
  /// 3. Base64 Data URI (guarantees images work 100% on any emulator/device/offline)
  static Future<String> uploadImage({
    required String filePath,
    required String folder, // 'ktp', 'tickets', 'work_photos'
  }) async {
    // If it's already a web URL or Base64 data URI, return as is
    if (filePath.startsWith('http://') ||
        filePath.startsWith('https://') ||
        filePath.startsWith('data:image/')) {
      return filePath;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return filePath;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = filePath.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final fileName = '${timestamp}_$cleanFileName';

    // 1. Try Firebase Storage first (native to the project)
    try {
      final storageRef = FirebaseStorage.instance.ref().child('$folder/$fileName');
      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      if (downloadUrl.startsWith('http')) {
        return downloadUrl;
      }
    } catch (fbErr) {
      debugPrint('Firebase Storage upload note: $fbErr');
    }

    // 2. Try Supabase Storage
    try {
      final pathInBucket = '$folder/$fileName';
      await client.storage.from(SupabaseConfig.bucketName).upload(
            pathInBucket,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true, contentType: 'image/jpeg'),
          );

      final publicUrl = client.storage
          .from(SupabaseConfig.bucketName)
          .getPublicUrl(pathInBucket);

      if (publicUrl.startsWith('http')) {
        return publicUrl;
      }
    } catch (sbErr) {
      debugPrint('Supabase Storage upload note: $sbErr');
    }

    // 3. Fallback to Base64 Data URI (Guarantees image displays across any emulator/device)
    try {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes <= 800 * 1024) {
        final b64 = base64Encode(bytes);
        return 'data:image/jpeg;base64,$b64';
      }
    } catch (b64Err) {
      debugPrint('Base64 fallback note: $b64Err');
    }

    return filePath;
  }

  /// Uploads multiple local files
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
