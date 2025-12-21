import 'package:flutter/material.dart';
import 'package:travel_memoir_admin/models/prompt_model.dart';

class PromptAddSheet extends StatefulWidget {
  final void Function(PromptModel) onSubmit;
  final PromptModel? initialPrompt; // ✅ 수정용

  const PromptAddSheet({
    super.key,
    required this.onSubmit,
    this.initialPrompt,
  });

  @override
  State<PromptAddSheet> createState() => _PromptAddSheetState();
}

class _PromptAddSheetState extends State<PromptAddSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialPrompt?.title ?? '');
    _contentController =
        TextEditingController(text: widget.initialPrompt?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      return;
    }

    final prompt = PromptModel(
      id: widget.initialPrompt?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isActive: true, // ✅ 수정해도 활성화
    );

    widget.onSubmit(prompt);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialPrompt != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? '프롬프트 수정' : '프롬프트 추가',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '프롬프트 제목',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '프롬프트 내용',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(isEdit ? '수정 저장' : '저장'),
            ),
          ),
        ],
      ),
    );
  }
}
