import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/image_style_model.dart';

class ImageStyleService {
  static final _client = Supabase.instance.client;

  // 🔹 Admin: 전체 스타일
  static Future<List<ImageStyleModel>> fetchAll() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .order('created_at', ascending: false);

    return (res as List).map((e) => ImageStyleModel.fromMap(e)).toList();
  }

  // 🔹 App: 사용 중 스타일만
  static Future<List<ImageStyleModel>> fetchEnabled() async {
    final res = await _client
        .from('ai_image_styles')
        .select()
        .eq('is_enabled', true)
        .order('created_at', ascending: false);

    return (res as List).map((e) => ImageStyleModel.fromMap(e)).toList();
  }

  // ➕ 추가
  static Future<void> add({
    required String title,
    required String prompt,
  }) async {
    await _client.from('ai_image_styles').insert({
      'title': title,
      'prompt': prompt,
      'is_enabled': true,
    });
  }

  // ✏️ 수정
  static Future<void> update(ImageStyleModel style) async {
    await _client.from('ai_image_styles').update({
      'title': style.title,
      'prompt': style.prompt,
    }).eq('id', style.id);
  }

  // 🔄 사용/미사용 토글
  static Future<void> setEnabled(String id, bool enabled) async {
    await _client
        .from('ai_image_styles')
        .update({'is_enabled': enabled}).eq('id', id);
  }
}
