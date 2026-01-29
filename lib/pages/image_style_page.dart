import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _styles.removeAt(oldIndex);
      _styles.insert(newIndex, item);
    });

    try {
      await ImageStyleService.updateOrder(_styles);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('순서 저장 실패: $e')),
      );
    }
  }

  Future<void> _openEditor({ImageStyleModel? style}) async {
    final titleCtrl = TextEditingController(text: style?.title ?? '');
    final titleEnCtrl = TextEditingController(text: style?.titleEn ?? '');
    final promptCtrl = TextEditingController(text: style?.prompt ?? '');
    final orderCtrl =
        TextEditingController(text: style?.sortOrder.toString() ?? '');

    bool isPremium = style?.isPremium ?? false;
    Uint8List? pickedImageBytes;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(style == null ? '스타일 추가' : '스타일 수정'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '스타일 이름 (한글)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleEnCtrl,
                    decoration: const InputDecoration(labelText: '스타일 이름 (영어)'),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('프리미엄 전용 스타일'),
                    value: isPremium,
                    onChanged: (v) =>
                        setModalState(() => isPremium = v ?? false),
                  ),
                  const SizedBox(height: 16),
                  Text('썸네일', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: pickedImageBytes != null
                          ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                          : (style?.thumbnailUrl != null &&
                                  style!.thumbnailUrl!.isNotEmpty)
                              ? Image.network(
                                  '${style.thumbnailUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image,
                                  size: 50, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('썸네일 선택'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final file =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setModalState(() => pickedImageBytes = bytes);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: promptCtrl,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: '이미지 프롬프트',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('저장')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    if (style == null) {
      await ImageStyleService.add(
        title: titleCtrl.text,
        titleEn: titleEnCtrl.text,
        prompt: promptCtrl.text,
        isPremium: isPremium,
      );
    } else {
      String? thumbnailUrl = style.thumbnailUrl;
      if (pickedImageBytes != null) {
        thumbnailUrl = await ImageStyleService.uploadThumbnail(
          styleId: style.id,
          imageBytes: pickedImageBytes!,
          oldUrl: style.thumbnailUrl,
        );
      }
      await ImageStyleService.update(
        style.copyWith(
          title: titleCtrl.text,
          titleEn: titleEnCtrl.text,
          prompt: promptCtrl.text,
          thumbnailUrl: thumbnailUrl,
          sortOrder: int.tryParse(orderCtrl.text) ?? style.sortOrder,
          isPremium: isPremium,
        ),
      );
    }
    await _load();
  }

  Future<void> _toggle(ImageStyleModel style, bool enabled) async {
    await ImageStyleService.setEnabled(style.id, enabled);
    await _load();
  }

  Future<void> _confirmDelete(ImageStyleModel style) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('스타일 삭제'),
        content: const Text('이 스타일을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ImageStyleService.delete(style);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 스타일 관리 (정렬 최적화)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('스타일 추가'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              itemCount: _styles.length,
              onReorder: _onReorder,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, i) {
                final style = _styles[i];
                return Column(
                  key: ValueKey(style.id),
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_indicator, color: Colors.grey),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: style.thumbnailUrl != null &&
                                    style.thumbnailUrl!.isNotEmpty
                                ? Image.network(
                                    '${style.thumbnailUrl}?v=${DateTime.now().millisecondsSinceEpoch}',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image,
                                        size: 28, color: Colors.grey),
                                  ),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${style.title} (${style.titleEn})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (style.isPremium)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.amber.shade300),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber, // 어두운 금색
                                ),
                              ),
                            ),
                        ],
                      ),
                      // 🗑 지저분했던 subtitle 삭제 완료!
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: style.isEnabled,
                            onChanged: (v) => _toggle(style, v),
                            activeColor: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon:
                                const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => _openEditor(style: style),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _confirmDelete(style),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 80),
                  ],
                );
              },
            ),
    );
  }
}
