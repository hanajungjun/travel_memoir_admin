import 'package:flutter/material.dart';

// ✅ 절대경로 import (이게 핵심)
import 'package:travel_memoir_admin/models/image_prompt_model.dart';
import 'package:travel_memoir_admin/services/image_prompt_service.dart';

class ImagePromptPage extends StatefulWidget {
  const ImagePromptPage({super.key});

  @override
  State<ImagePromptPage> createState() => _ImagePromptPageState();
}

class _ImagePromptPageState extends State<ImagePromptPage> {
  List<ImagePromptModel> prompts = [];
  ImagePromptModel? selected;

  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    prompts = await ImagePromptService.fetchAll();
    setState(() {});
  }

  void _newPrompt() {
    selected = null;
    titleCtrl.text = '기본 이미지 프롬프트';
    contentCtrl.text = '''
A flat illustration inspired by a travel diary.

Style:
- Soft pastel colors
- Clean background
- Calm and warm mood
- Illustration, not realistic photo

Rules:
- No text
- No letters
- No captions
- No logos
''';
    setState(() {});
  }

  void _select(ImagePromptModel p) {
    selected = p;
    titleCtrl.text = p.title;
    contentCtrl.text = p.content;
    setState(() {});
  }

  Future<void> _save() async {
    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
      return;
    }

    if (selected == null) {
      await ImagePromptService.add(
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
      );
    } else {
      await ImagePromptService.update(
        ImagePromptModel(
          id: selected!.id,
          title: titleCtrl.text.trim(),
          content: contentCtrl.text.trim(),
          isActive: true,
        ),
      );
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // =====================
        // 📌 좌측 리스트
        // =====================
        SizedBox(
          width: 260,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  onPressed: _newPrompt,
                  icon: const Icon(Icons.add),
                  label: const Text('새 이미지 프롬프트'),
                ),
              ),
              Expanded(
                child: ListView(
                  children: prompts.map((p) {
                    return ListTile(
                      title: Text(p.title),
                      trailing: p.isActive
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => _select(p),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // =====================
        // ✏️ 우측 에디터
        // =====================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: contentCtrl,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      labelText: '이미지 프롬프트 내용',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('저장 및 활성화'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
