import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_memoir_admin/models/prompt_model.dart';

class PromptService {
  static final _client = Supabase.instance.client;

  // 📥 전체 프롬프트
  static Future<List<PromptModel>> fetchPrompts() async {
    final res = await _client
        .from('ai_prompts')
        .select()
        .order('created_at', ascending: false);

    return (res as List).map((e) => PromptModel.fromMap(e)).toList();
  }

  // ➕ 추가 + 즉시 활성화
  static Future<void> addPrompt(PromptModel prompt) async {
    final inserted = await _client
        .from('ai_prompts')
        .insert({
          'title': prompt.title,
          'content': prompt.content,
          'is_active': false,
        })
        .select()
        .single();

    await setActive(inserted['id']);
  }

  // ✏️ 수정 + 즉시 활성화
  static Future<void> updatePrompt(PromptModel prompt) async {
    await _client.from('ai_prompts').update({
      'title': prompt.title,
      'content': prompt.content,
    }).eq('id', prompt.id);

    await setActive(prompt.id);
  }

  // 🔄 활성 토글 (🔥 유일한 활성 제어 지점)
  static Future<void> setActive(String id) async {
    await _client.rpc(
      'set_active_prompt',
      params: {'target_id': id},
    );
  }
}
