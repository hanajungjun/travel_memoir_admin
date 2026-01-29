import 'package:flutter/material.dart';
import 'package:travel_memoir_admin/models/prompt_model.dart';
import 'package:travel_memoir_admin/widgets/prompt_card.dart';
import 'package:travel_memoir_admin/pages/prompt_add_sheet.dart';
import 'package:travel_memoir_admin/services/prompt_service.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AI 프롬프트 관리 (다국어 지원)',
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
          Expanded(
            child: ListView.separated(
              itemCount: _prompts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final prompt = _prompts[index];
                return PromptCard(
                  prompt: prompt,
                  onToggle: (_) async {
                    await PromptService.setActive(prompt.id);
                    await _load();
                  },
                  onEdit: () => _openEditSheet(prompt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 핵심 수정: showModalBottomSheet 대신 showDialog 사용
  void _openAddSheet() {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 클릭 시 닫힘 방지 (저장 버튼 유도)
      builder: (_) => PromptAddSheet(
        onSubmit: (prompt) async {
          await PromptService.addPrompt(prompt);
          await _load();
        },
      ),
    );
  }

  // 🔥 핵심 수정: showDialog로 변경하여 대형 팝업 구현
  void _openEditSheet(PromptModel prompt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PromptAddSheet(
        initialPrompt: prompt,
        onSubmit: (updated) async {
          await PromptService.updatePrompt(updated);
          await _load();
        },
      ),
    );
  }
}
