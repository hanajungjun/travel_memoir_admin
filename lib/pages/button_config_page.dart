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

  String _targetType = 'topic';
  String _selectedTopic = 'all_users';
  bool _isSending = false;

  Future<void> _sendPushNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    setState(() => _isSending = true);

    try {
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

      if (response.status == 200 || response.status == 201) {
        _showSuccessDialog();
      } else {
        throw '발송 실패 (Status: ${response.status})';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('에러: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('전송 완료'),
          ],
        ),
        content: const Text('푸시 알림이 성공적으로 전송되었습니다.\n입력하신 내용은 그대로 유지됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 1, child: _buildPushSection()),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(
              flex: 1,
              child:
                  _buildReservedSection("예비 영역 1", Icons.analytics_outlined)),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(
              flex: 1,
              child: _buildReservedSection("예비 영역 2", Icons.settings_outlined)),
        ],
      ),
    );
  }

  Widget _buildPushSection() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign, color: Colors.blueAccent, size: 30),
                SizedBox(width: 12),
                Text('푸시 알림 관리',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 35),
            _buildLabel('발송 방식'),
            Row(
              children: [
                _buildSelectButton('그룹(토픽)', _targetType == 'topic',
                    () => setState(() => _targetType = 'topic')),
                const SizedBox(width: 10),
                _buildSelectButton('개별(토큰)', _targetType == 'token',
                    () => setState(() => _targetType = 'token')),
              ],
            ),
            const SizedBox(height: 20),
            if (_targetType == 'topic') ...[
              _buildLabel('대상 토픽 선택'),
              Wrap(
                spacing: 10,
                children: [
                  _buildTopicChip('전체 공지', 'all_users'),
                  _buildTopicChip('마케팅 정보', 'marketing'),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '마케팅은 수신 동의한 사용자에게만 전달됩니다.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildLabel('FCM 토큰 입력'),
              TextField(
                  controller: _tokenController,
                  decoration: _inputDecoration('상대방의 FCM 토큰을 붙여넣으세요')),
            ],
            const SizedBox(height: 35),
            const Divider(thickness: 1),
            const SizedBox(height: 35),
            _buildLabel('알림 제목'),
            TextField(
                controller: _titleController,
                decoration: _inputDecoration('사용자에게 노출될 제목')),
            const SizedBox(height: 25),
            _buildLabel('알림 본문'),
            TextField(
                controller: _bodyController,
                maxLines: 6,
                decoration: _inputDecoration('상세 본문 내용을 입력하세요')),
            const SizedBox(height: 45),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendPushNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('푸시 알림 즉시 전송',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservedSection(String title, IconData icon) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('데이터 준비 중...',
                style: TextStyle(fontSize: 15, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF374151))),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        // ✅ 에러가 났던 부분을 수정했습니다. (BorderSide 추가)
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        contentPadding: const EdgeInsets.all(18),
      );

  Widget _buildSelectButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isSelected ? Colors.blueAccent : const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal)),
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
      onSelected: (_) => setState(() => _selectedTopic = value),
      selectedColor: Colors.blueAccent.withOpacity(0.1),
      checkmarkColor: Colors.blueAccent,
      labelStyle: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
