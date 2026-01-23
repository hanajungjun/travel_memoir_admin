import 'package:flutter/material.dart';

import 'package:travel_memoir_admin/models/prompt_model.dart';
import 'package:travel_memoir_admin/widgets/prompt_card.dart';
import 'package:travel_memoir_admin/pages/prompt_add_sheet.dart';
import 'package:travel_memoir_admin/services/prompt_service.dart'; // 또는 prompt_service.dart

class PromptPage extends StatefulWidget {
  const PromptPage({super.key});

  @override
  State<PromptPage> createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  List<PromptModel> _prompts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await PromptService.fetchPrompts();
    if (!mounted) return;
    setState(() {
      _prompts = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          children: [
            const Text(
              'AI 프롬프트 관리(일기 요약 프롬프트)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add),
              label: const Text('프롬프트 추가'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 리스트
        Expanded(
          child: ListView.separated(
            itemCount: _prompts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final prompt = _prompts[index];
              return PromptCard(
                prompt: prompt,

                // 🔄 활성 토글
                onToggle: (_) async {
                  await PromptService.setActive(prompt.id);
                  await _load(); // 🔥 DB 기준 재동기화
                },

                // ✏️ 수정
                onEdit: () => _openEditSheet(prompt),
              );
            },
          ),
        ),
      ],
    );
  }

  // ➕ 추가
  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return PromptAddSheet(
          onSubmit: (prompt) async {
            await PromptService.addPrompt(prompt);
            await _load(); // 🔥 이것만
          },
        );
      },
    );
  }

  // ✏️ 수정
  void _openEditSheet(PromptModel prompt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return PromptAddSheet(
          initialPrompt: prompt,
          onSubmit: (updated) async {
            await PromptService.updatePrompt(updated);
            await _load(); // 🔥 이것만
          },
        );
      },
    );
  }
}
