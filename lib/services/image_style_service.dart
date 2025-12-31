import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/image_style_model.dart';

class ImageStyleService {
  static final _client = Supabase.instance.client;
  static const _bucket = 'travel_images';

  // =====================================================
  // 🔹 Admin: 전체 스타일 (최신 생성순)
  // =====================================================
  static Future<List<ImageStyleModel>> fetchAll() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .order('created_at', ascending: false);

    return (res as List).map((e) => ImageStyleModel.fromMap(e)).toList();
  }

  // =====================================================
  // 🔹 App: 사용 중 스타일만 (정렬 순서 기준)
  // =====================================================
  static Future<List<ImageStyleModel>> fetchEnabled() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .eq('is_enabled', true)
        .order('sort_order', ascending: true);

    return (res as List).map((e) => ImageStyleModel.fromMap(e)).toList();
  }

  // =====================================================
  // ➕ 스타일 추가
  // =====================================================
  static Future<void> add({
    required String title,
    required String prompt,
    String? thumbnailUrl,
  }) async {
    final maxRes = await _client
        .from('ai_image_styles')
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();

    final nextOrder = (maxRes?['sort_order'] as int? ?? 0) + 1;

    await _client.from('ai_image_styles').insert({
      'title': title,
      'prompt': prompt,
      'thumbnail_url': thumbnailUrl,
      'sort_order': nextOrder,
      'is_enabled': true,
    });
  }

  // =====================================================
  // ✏️ 스타일 수정
  // =====================================================
  static Future<void> update(ImageStyleModel style) async {
    await _client.from('ai_image_styles').update({
      'title': style.title,
      'prompt': style.prompt,
      'thumbnail_url': style.thumbnailUrl,
      'sort_order': style.sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', style.id);
  }

  // =====================================================
  // 🔄 사용/미사용 토글
  // =====================================================
  static Future<void> setEnabled(String id, bool enabled) async {
    await _client.from('ai_image_styles').update({
      'is_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // =====================================================
  // 🖼️ 썸네일 업로드 (style_thumbnails/timestamp.png)
  // =====================================================
  static Future<String> uploadThumbnail({
    required Uint8List imageBytes,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final path = 'style_thumbnails/$fileName';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: false,
            contentType: 'image/png',
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  // =====================================================
  // 🗑️ 스타일 + 썸네일 삭제
  // =====================================================
  static Future<void> delete(ImageStyleModel style) async {
    if (style.thumbnailUrl != null && style.thumbnailUrl!.isNotEmpty) {
      final uri = Uri.parse(style.thumbnailUrl!);
      final path = uri.path.split('/object/public/$_bucket/').last;
      await _client.storage.from(_bucket).remove([path]);
    }

    await _client.from('ai_image_styles').delete().eq('id', style.id);
  }
}
