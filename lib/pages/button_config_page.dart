import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ButtonConfigPage extends StatefulWidget {
  const ButtonConfigPage({super.key});

  @override
  State<ButtonConfigPage> createState() => _ButtonConfigPageState();
}

class _ButtonConfigPageState extends State<ButtonConfigPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tokenController = TextEditingController();

  String _targetType = 'topic'; // 'topic' 또는 'token'
  String _selectedTopic = 'all_users';
  bool _isSending = false;

  // 🚀 실제 푸시 발송 로직
  Future<void> _sendPushNotification() async {
    // 1. 입력 유효성 검사
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    if (_targetType == 'token' && _tokenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테스트할 기기의 FCM 토큰을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      debugPrint("📡 [Edge Function 호출] 대상: $_targetType / $_selectedTopic");

      // 2. Supabase Edge Function 호출
      final response = await Supabase.instance.client.functions.invoke(
        'send-push',
        body: {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'targetType': _targetType,
          'targetValue': _targetType == 'topic'
              ? _selectedTopic
              : _tokenController.text.trim(),
        },
      );

      debugPrint("✅ 응답 상태코드: ${response.status}");

      if (response.status == 200 || response.status == 201) {
        if (mounted) {
          _showSuccessDialog();
          _titleController.clear();
          _bodyController.clear();
          _tokenController.clear();
        }
      } else {
        throw '서버 응답 오류 (Status: ${response.status})';
      }
    } catch (e) {
      debugPrint("❌ 에러 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('발송 실패: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog() {
    String target = _targetType == 'topic'
        ? (_selectedTopic == 'all_users' ? '전체 공지' : '마케팅')
        : '특정 테스트 기기';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('전송 요청 완료'),
          ],
        ),
        content: Text('[$target] 대상으로 푸시 알림을 성공적으로 보냈습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, size: 32, color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Text(
                      '푸시 알림 관리자',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('발송 방식'),
                Row(
                  children: [
                    _buildSelectButton('토픽 발송', _targetType == 'topic',
                        () => setState(() => _targetType = 'topic')),
                    const SizedBox(width: 12),
                    _buildSelectButton('특정 토큰(테스트)', _targetType == 'token',
                        () => setState(() => _targetType = 'token')),
                  ],
                ),
                const SizedBox(height: 16),
                if (_targetType == 'topic') ...[
                  Row(
                    children: [
                      _buildTopicChip('전체 공지 (all_users)', 'all_users'),
                      const SizedBox(width: 8),
                      _buildTopicChip('마케팅 (marketing)', 'marketing'),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _tokenController,
                    decoration: _inputDecoration('FCM 토큰을 붙여넣으세요'),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _buildLabel('알림 제목'),
                TextField(
                  controller: _titleController,
                  decoration: _inputDecoration('사용자에게 보여질 제목'),
                ),
                const SizedBox(height: 20),
                _buildLabel('알림 본문'),
                TextField(
                  controller: _bodyController,
                  maxLines: 3,
                  decoration: _inputDecoration('상세 내용 입력'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendPushNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('푸시 알림 전송하기',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 도움 위젯들 ---
  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _buildSelectButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    isSelected ? Colors.blueAccent : const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChip(String label, String value) {
    bool isSelected = _selectedTopic == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedTopic = value),
      selectedColor: Colors.blueAccent.withOpacity(0.1),
      checkmarkColor: Colors.blueAccent,
      labelStyle:
          TextStyle(color: isSelected ? Colors.blueAccent : Colors.black87),
    );
  }
}
