import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/image_style_model.dart';

class ImageStyleService {
  static final _client = Supabase.instance.client;
  static const _bucket = 'travel_images';

  // ✅ 관리자 페이지를 위해 sort_order 순으로 가져오도록 수정
  static Future<List<ImageStyleModel>> fetchAll() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .order('sort_order', ascending: true); // 정렬 순서대로 로드
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

  // 🔥 신규 추가: 드래그 앤 드롭 후 순서 일괄 업데이트
  static Future<void> updateOrder(List<ImageStyleModel> styles) async {
    for (int i = 0; i < styles.length; i++) {
      await _client
          .from('ai_image_styles')
          .update({'sort_order': i}).eq('id', styles[i].id);
    }
  }

  static Future<void> add({
    required String title,
    required String titleEn,
    required String prompt,
    bool isPremium = false,
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
      'title_en': titleEn,
      'prompt': prompt,
      'sort_order': nextOrder,
      'is_enabled': true,
      'is_premium': isPremium,
    });
  }

  static Future<void> update(ImageStyleModel style) async {
    await _client.from('ai_image_styles').update({
      'title': style.title,
      'title_en': style.titleEn,
      'prompt': style.prompt,
      'thumbnail_url': style.thumbnailUrl,
      'sort_order': style.sortOrder,
      'is_enabled': style.isEnabled,
      'is_premium': style.isPremium,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', style.id);
  }

  static Future<void> setEnabled(String id, bool enabled) async {
    await _client.from('ai_image_styles').update({
      'is_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<String> uploadThumbnail({
    required String styleId,
    required Uint8List imageBytes,
    String? oldUrl,
  }) async {
    if (oldUrl != null && oldUrl.isNotEmpty) {
      try {
        final oldPath = oldUrl.split('$_bucket/').last.split('?').first;
        await _client.storage.from(_bucket).remove([oldPath]);
      } catch (e) {
        debugPrint("기존 파일 삭제 실패 (무시 가능): $e");
      }
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = 'system/style_thumbnails/${styleId}_$timestamp.png';

    await _client.storage.from(_bucket).uploadBinary(
          newPath,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );

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
