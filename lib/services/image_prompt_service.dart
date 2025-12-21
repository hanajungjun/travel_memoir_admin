import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/image_prompt_model.dart';

class ImagePromptService {
  static final _client = Supabase.instance.client;

  // 📥 전체 이미지 프롬프트
  static Future<List<ImagePromptModel>> fetchAll() async {
    final res = await _client
        .from('ai_image_prompts')
        .select()
        .order('created_at', ascending: false);

    return (res as List).map((e) => ImagePromptModel.fromMap(e)).toList();
  }

  // ➕ 추가
  static Future<void> add({
    required String title,
    required String content,
  }) async {
    final res = await _client
        .from('ai_image_prompts')
        .insert({
          'title': title,
          'content': content,
          'is_active': false,
        })
        .select()
        .single();

    await setActive(res['id']);
  }

  // ✏️ 수정
  static Future<void> update(ImagePromptModel prompt) async {
    await _client.from('ai_image_prompts').update({
      'title': prompt.title,
      'content': prompt.content,
    }).eq('id', prompt.id);

    await setActive(prompt.id);
  }

  // 🔄 활성화
  static Future<void> setActive(String id) async {
    await _client.rpc(
      'set_active_image_prompt',
      params: {'target_id': id},
    );
  }
}
