import 'package:flutter/material.dart';
import '../models/image_style_model.dart';
import '../services/image_style_service.dart';

class ImageStylePage extends StatefulWidget {
  const ImageStylePage({super.key});

  @override
  State<ImageStylePage> createState() => _ImageStylePageState();
}

class _ImageStylePageState extends State<ImageStylePage> {
  List<ImageStyleModel> _styles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _styles = await ImageStyleService.fetchAll();
    setState(() => _loading = false);
  }

  Future<void> _openEditor({ImageStyleModel? style}) async {
    final titleCtrl = TextEditingController(text: style?.title ?? '');
    final promptCtrl = TextEditingController(text: style?.prompt ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(style == null ? '스타일 추가' : '스타일 수정'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '스타일 이름'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptCtrl,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '이미지 프롬프트',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    if (style == null) {
      await ImageStyleService.add(
        title: titleCtrl.text,
        prompt: promptCtrl.text,
      );
    } else {
      await ImageStyleService.update(
        style.copyWith(
          title: titleCtrl.text,
          prompt: promptCtrl.text,
        ),
      );
    }

    await _load();
  }

  Future<void> _toggle(ImageStyleModel style, bool enabled) async {
    await ImageStyleService.setEnabled(style.id, enabled);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI 이미지 스타일',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('새 스타일'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _styles.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final style = _styles[i];
              return ListTile(
                leading: Checkbox(
                  value: style.isEnabled,
                  onChanged: (v) => _toggle(style, v!),
                ),
                title: Text(style.title),
                subtitle: Text(
                  style.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openEditor(style: style),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
