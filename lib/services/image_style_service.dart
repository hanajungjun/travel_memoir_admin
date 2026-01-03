import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/image_style_model.dart';
import 'package:travel_memoir_admin/storage_paths.dart';

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
  // ➕ 스타일 추가 (썸네일은 나중에 업로드)
  // =====================================================
  static Future<void> add({
    required String title,
    required String prompt,
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
  // 🔄 사용 / 미사용 토글
  // =====================================================
  static Future<void> setEnabled(String id, bool enabled) async {
    await _client.from('ai_image_styles').update({
      'is_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // =====================================================
  // 🖼️ 썸네일 업로드 (🔥 storage_paths 기준)
  // system/style_thumbnails/{styleId}.png
  // =====================================================
  static Future<String> uploadThumbnail({
    required String styleId,
    required Uint8List imageBytes,
  }) async {
    final path = StoragePaths.styleThumbnail(styleId);

    await _client.storage.from(_bucket).uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: true, // 🔥 수정 시 덮어쓰기
            contentType: 'image/png',
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  // =====================================================
  // 🗑️ 스타일 + 썸네일 삭제 (🔥 URL 파싱 ❌)
  // =====================================================
  static Future<void> delete(ImageStyleModel style) async {
    // 썸네일 삭제
    if (style.thumbnailUrl != null && style.thumbnailUrl!.isNotEmpty) {
      final path = StoragePaths.styleThumbnail(style.id);
      await _client.storage.from(_bucket).remove([path]);
    }

    // DB 삭제
    await _client.from('ai_image_styles').delete().eq('id', style.id);
  }
}
