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

  Future<void> _openEditor({ImageStyleModel? style}) async {
    final titleCtrl = TextEditingController(text: style?.title ?? '');
    final titleEnCtrl = TextEditingController(text: style?.titleEn ?? '');
    final promptCtrl = TextEditingController(text: style?.prompt ?? '');
    final orderCtrl =
        TextEditingController(text: style?.sortOrder.toString() ?? '');

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
                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '정렬 순서'),
                  ),
                  const SizedBox(height: 16),
                  Text('썸네일', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    child: pickedImageBytes != null
                        ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                        : (style?.thumbnailUrl != null &&
                                style!.thumbnailUrl!.isNotEmpty)
                            ? Image.network(
                                // ✨ 캐시 방지를 위해 URL 뒤에 항상 타임스탬프를 붙여서 보여줌
                                '${style.thumbnailUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                                fit: BoxFit.cover,
                              )
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
                        setModalState(() => pickedImageBytes = bytes);
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
                child: const Text('취소')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('저장')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    // ============================
    // ✅ 신규 추가 로직
    // ============================
    if (style == null) {
      await ImageStyleService.add(
        title: titleCtrl.text,
        titleEn: titleEnCtrl.text,
        prompt: promptCtrl.text,
      );
      await _load();
      final newStyle = _styles.first;

      if (pickedImageBytes != null) {
        // 새 파일 업로드 (이름에 타임스탬프 포함됨)
        final url = await ImageStyleService.uploadThumbnail(
          styleId: newStyle.id,
          imageBytes: pickedImageBytes!,
        );

        await ImageStyleService.update(newStyle.copyWith(
          thumbnailUrl: url,
          sortOrder: int.tryParse(orderCtrl.text) ?? newStyle.sortOrder,
        ));
      }
    }
    // ============================
    // ✅ 기존 수정 로직
    // ============================
    else {
      String? thumbnailUrl = style.thumbnailUrl;

      if (pickedImageBytes != null) {
        // 🔥 [중요] 기존 URL(oldUrl)을 넘겨주어 이전 파일을 지우고 새 파일을 만듭니다.
        thumbnailUrl = await ImageStyleService.uploadThumbnail(
          styleId: style.id,
          imageBytes: pickedImageBytes!,
          oldUrl: style.thumbnailUrl, // 이전 주소 전달
        );
      }

      await ImageStyleService.update(style.copyWith(
        title: titleCtrl.text,
        titleEn: titleEnCtrl.text,
        prompt: promptCtrl.text,
        thumbnailUrl: thumbnailUrl, // 새 주소로 DB 업데이트
        sortOrder: int.tryParse(orderCtrl.text) ?? style.sortOrder,
      ));
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
        title: const Text('이미지 스타일 관리',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
          : ListView.separated(
              itemCount: _styles.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final style = _styles[i];
                return ListTile(
                  leading: style.thumbnailUrl != null &&
                          style.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          // ✨ 리스트에서도 캐시를 방지하기 위해 쿼리 파라미터 추가
                          '${style.thumbnailUrl}?v=${DateTime.now().millisecondsSinceEpoch}',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          key: ValueKey(style.thumbnailUrl), // 위젯 강제 빌드
                        )
                      : const Icon(Icons.image),
                  title: Text('${style.title} (${style.titleEn})'),
                  subtitle: Text('정렬: ${style.sortOrder}\n${style.prompt}',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                          value: style.isEnabled,
                          onChanged: (v) => _toggle(style, v)),
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openEditor(style: style)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(style)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
