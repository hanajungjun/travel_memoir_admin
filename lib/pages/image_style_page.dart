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

  // =====================================================
  // ✏️ 추가 / 수정
  // =====================================================
  Future<void> _openEditor({ImageStyleModel? style}) async {
    final titleCtrl = TextEditingController(text: style?.title ?? '');
    final promptCtrl = TextEditingController(text: style?.prompt ?? '');
    final orderCtrl =
        TextEditingController(text: style?.sortOrder.toString() ?? '');

    String? thumbnailUrl = style?.thumbnailUrl;
    Uint8List? pickedImageBytes;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(style == null ? '스타일 추가' : '스타일 수정'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '스타일 이름'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '정렬 순서'),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('썸네일',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    child: pickedImageBytes != null
                        ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                        : (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                            ? Image.network(thumbnailUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.image,
                                size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('썸네일 선택'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final file =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setState(() => pickedImageBytes = bytes);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: promptCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: '이미지 프롬프트',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
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
      ),
    );

    if (saved != true) return;

    // ✅ 썸네일을 새로 골랐을 때만 업로드
    if (pickedImageBytes != null) {
      thumbnailUrl = await ImageStyleService.uploadThumbnail(
        imageBytes: pickedImageBytes!,
      );
    }

    if (style == null) {
      await ImageStyleService.add(
        title: titleCtrl.text,
        prompt: promptCtrl.text,
        thumbnailUrl: thumbnailUrl,
      );
    } else {
      await ImageStyleService.update(
        style.copyWith(
          title: titleCtrl.text,
          prompt: promptCtrl.text,
          thumbnailUrl: thumbnailUrl,
          sortOrder: int.tryParse(orderCtrl.text) ?? style.sortOrder,
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
            child: const Text('취소'),
          ),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      itemCount: _styles.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final style = _styles[i];
        return ListTile(
          leading: style.thumbnailUrl != null && style.thumbnailUrl!.isNotEmpty
              ? Image.network(style.thumbnailUrl!,
                  width: 48, height: 48, fit: BoxFit.cover)
              : const Icon(Icons.image),
          title: Text(style.title),
          subtitle: Text('정렬: ${style.sortOrder}\n${style.prompt}',
              maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: style.isEnabled,
                onChanged: (v) => _toggle(style, v),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openEditor(style: style),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(style),
              ),
            ],
          ),
        );
      },
    );
  }
}
