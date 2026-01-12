import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/image_style_model.dart';

class ImageStyleService {
  static final _client = Supabase.instance.client;
  static const _bucket = 'travel_images';

  static Future<List<ImageStyleModel>> fetchAll() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((e) => ImageStyleModel.fromMap(e)).toList();
  }

  static Future<List<ImageStyleModel>> fetchEnabled() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .eq('is_enabled', true)
        .order('sort_order', ascending: true);
    return (res as List).map((e) => ImageStyleModel.fromMap(e)).toList();
  }

  static Future<void> add(
      {required String title,
      required String titleEn,
      required String prompt}) async {
    final maxRes = await _client
        .from('ai_image_styles')
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextOrder = (maxRes?['sort_order'] as int? ?? 0) + 1;
    await _client.from('ai_image_styles').insert({
      'title': title,
      'title_en': titleEn,
      'prompt': prompt,
      'sort_order': nextOrder,
      'is_enabled': true,
    });
  }

  static Future<void> update(ImageStyleModel style) async {
    await _client.from('ai_image_styles').update({
      'title': style.title,
      'title_en': style.titleEn,
      'prompt': style.prompt,
      'thumbnail_url': style.thumbnailUrl, // ✨ 새로 생성된 URL이 여기 들어감
      'sort_order': style.sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', style.id);
  }

  static Future<void> setEnabled(String id, bool enabled) async {
    await _client.from('ai_image_styles').update({
      'is_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', id);
  }

  // 🔥 [핵심 수정] 썸네일 업로드 시 파일명을 유니크하게 변경
  static Future<String> uploadThumbnail({
    required String styleId,
    required Uint8List imageBytes,
    String? oldUrl, // 이전 파일을 지우기 위해 oldUrl을 받음
  }) async {
    // 1. 기존 파일이 있다면 스토리지에서 먼저 삭제 (용량 관리)
    if (oldUrl != null && oldUrl.isNotEmpty) {
      try {
        final oldPath = oldUrl.split('$_bucket/').last.split('?').first;
        await _client.storage.from(_bucket).remove([oldPath]);
      } catch (e) {
        debugPrint("기존 파일 삭제 실패 (무시 가능): $e");
      }
    }

    // 2. 새 파일명 생성 (styleId + 타임스탬프)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = 'system/style_thumbnails/${styleId}_$timestamp.png';

    // 3. 업로드
    await _client.storage.from(_bucket).uploadBinary(
          newPath,
          imageBytes,
          fileOptions:
              const FileOptions(contentType: 'image/png', upsert: true),
        );

    // 4. 새로운 공용 URL 반환
    return _client.storage.from(_bucket).getPublicUrl(newPath);
  }

  static Future<void> delete(ImageStyleModel style) async {
    if (style.thumbnailUrl != null && style.thumbnailUrl!.isNotEmpty) {
      final path = style.thumbnailUrl!.split('$_bucket/').last.split('?').first;
      await _client.storage.from(_bucket).remove([path]);
    }
    await _client.from('ai_image_styles').delete().eq('id', style.id);
  }
}
