import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ButtonConfigPage extends StatefulWidget {
  const ButtonConfigPage({super.key});

  @override
  State<ButtonConfigPage> createState() => _ButtonConfigPageState();
}

class _ButtonConfigPageState extends State<ButtonConfigPage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // ============================
  // Push
  // ============================
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tokenController = TextEditingController();

  String _targetType = 'topic';
  String _selectedTopic = 'all_users';
  bool _isSendingPush = false;

  // ============================
  // Passport Country
  // ============================
  final _codeController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _nameKoController = TextEditingController();

  XFile? _stickerImage; // 🔥 핵심: File ❌ → XFile ✅
  bool _isRegisteringCountry = false;

  // ============================
  // Utils
  // ============================
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프롬프트가 클립보드에 복사되었습니다!')),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ============================
  // Push Logic
  // ============================
  Future<void> _sendPushNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      _showErrorSnackBar('제목과 내용을 입력해주세요.');
      return;
    }

    setState(() => _isSendingPush = true);

    try {
      final response = await _supabase.functions.invoke(
        'send-push',
        body: {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'targetType': _targetType,
          'targetValue':
              _targetType == 'topic' ? _selectedTopic : _tokenController.text,
        },
      );

      if (response.status == 200 || response.status == 201) {
        _showSuccessDialog('전송 완료', '푸시 알림이 성공적으로 전송되었습니다.');
      } else {
        throw 'push failed';
      }
    } catch (e) {
      _showErrorSnackBar('푸시 에러: $e');
    } finally {
      if (mounted) setState(() => _isSendingPush = false);
    }
  }

  // ============================
  // Country Logic
  // ============================
  Future<void> _pickStickerImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _stickerImage = picked);
    }
  }

  Future<void> _registerCountry() async {
    final code = _codeController.text.trim().toUpperCase();
    final en = _nameEnController.text.trim();
    final ko = _nameKoController.text.trim();

    if (code.isEmpty || en.isEmpty || ko.isEmpty || _stickerImage == null) {
      _showErrorSnackBar('모든 정보와 이미지를 입력해주세요.');
      return;
    }

    setState(() => _isRegisteringCountry = true);

    try {
      // ✅ Web / Mobile 공통: XFile → bytes → uploadBinary
      final bytes = await _stickerImage!.readAsBytes();

      await _supabase.storage.from('stickers').uploadBinary(
            '$code.png',
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      await _supabase.from('passport_countries').insert({
        'code': code,
        'name_en': en,
        'name_ko': ko,
        'is_active': true,
      });

      _showSuccessDialog('등록 완료', "'$ko' 국가가 시스템에 추가되었습니다.");
      _clearCountryFields();
    } catch (e) {
      _showErrorSnackBar('등록 실패: $e');
    } finally {
      if (mounted) setState(() => _isRegisteringCountry = false);
    }
  }

  void _clearCountryFields() {
    _codeController.clear();
    _nameEnController.clear();
    _nameKoController.clear();
    setState(() => _stickerImage = null);
  }

  // ============================
  // UI
  // ============================
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
          Expanded(flex: 1, child: _buildPassportAdminSection()),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(flex: 1, child: _buildPromptTemplateSection()),
        ],
      ),
    );
  }

  // ============================
  // Sections
  // ============================
  Widget _buildPushSection() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.campaign, '푸시 알림 관리', Colors.blueAccent),
            const SizedBox(height: 35),
            _buildLabel('발송 방식'),
            Row(
              children: [
                _buildSelectButton(
                  '그룹(토픽)',
                  _targetType == 'topic',
                  () => setState(() => _targetType = 'topic'),
                ),
                const SizedBox(width: 10),
                _buildSelectButton(
                  '개별(토큰)',
                  _targetType == 'token',
                  () => setState(() => _targetType = 'token'),
                ),
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
            ] else ...[
              _buildLabel('FCM 토큰 입력'),
              TextField(
                controller: _tokenController,
                decoration: _inputDecoration('상대방의 FCM 토큰 입력'),
              ),
            ],
            const SizedBox(height: 35),
            const Divider(),
            const SizedBox(height: 35),
            _buildLabel('알림 제목'),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('제목 입력'),
            ),
            const SizedBox(height: 25),
            _buildLabel('알림 본문'),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: _inputDecoration('본문 내용 입력'),
            ),
            const SizedBox(height: 45),
            _buildActionButton(
              '푸시 알림 즉시 전송',
              Colors.blueAccent,
              _isSendingPush,
              _sendPushNotification,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportAdminSection() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.map_outlined, '여권 국가 관리', Colors.teal),
            const SizedBox(height: 35),
            _buildLabel('도장 이미지 (PNG)'),
            GestureDetector(
              onTap: _pickStickerImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _stickerImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          _stickerImage!.path, // blob url
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search,
                              size: 40, color: Colors.grey),
                          Text('클릭하여 이미지 선택'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 25),
            _buildLabel('국가 코드 (ISO)'),
            TextField(
              controller: _codeController,
              decoration: _inputDecoration('예: KR, JP, US'),
            ),
            const SizedBox(height: 20),
            _buildLabel('영어 국가명'),
            TextField(
              controller: _nameEnController,
              decoration: _inputDecoration('예: Korea, Japan'),
            ),
            const SizedBox(height: 20),
            _buildLabel('한국어 국가명'),
            TextField(
              controller: _nameKoController,
              decoration: _inputDecoration('예: 대한민국, 일본'),
            ),
            const SizedBox(height: 45),
            _buildActionButton(
              '시스템에 국가 등록',
              Colors.teal,
              _isRegisteringCountry,
              _registerCountry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptTemplateSection() {
    final templates = [
      {
        'title': '1. 클래식 원형 (빨강)',
        'color': Colors.red,
        'prompt':
            'A photorealistic close-up of a circular red ink passport stamp. The ink texture looks like it\'s bleeding into paper grain with slight smudges. The stamp features the bold text "COUNTRY - IMMIGRATION" around the top arch. In the center, there is a stylized silhouette icon of the most famous landmark representing COUNTRY, chosen by the AI, with "ENTRY" below it. No other text or dates. The edges are imperfect and look authentic, isolated on transparent background, PNG with alpha channel, no paper texture in background, clean edges.'
      },
      {
        'title': '2. 모던 사각형 (파랑)',
        'color': Colors.blue,
        'prompt':
            'A realistic photograph of a rectangular blue ink passport entry stamp with rounded corners. The ink looks freshly inked but slightly faded in parts with a thick, realistic texture. It features a graphic icon of the most famous landmark representing COUNTRY, chosen by the AI, on the left, with bold text "COUNTRY" at the top right, and "ARRIVAL - VISITOR" below the text. No dates or airport codes, isolated on transparent background, PNG with alpha channel, no paper texture in background, clean edges.'
      },
      {
        'title': '3. 빈티지 타원형 (검정)',
        'color': Colors.black,
        'prompt':
            'A vintage-style oval black ink passport stamp. The ink appears old, cracked, and weathered. The stamp has an outer border with text "COUNTRY - BORDER CONTROL". The central section contains a detailed icon of the most famous landmark representing COUNTRY, chosen by the AI, and the word "ADMITTED". No numerical dates or locations, isolated on transparent background, PNG with alpha channel, no paper texture in background, clean edges.'
      },
      {
        'title': '4. 유니크 육각형 (초록)',
        'color': Colors.green,
        'prompt':
            'A close-up of a hexagonal green ink passport stamp. The ink is slightly translucent in areas with a rough, organic ink texture. The top section reads "COUNTRY", the middle section features a prominent icon of the most famous landmark representing COUNTRY, chosen by the AI, and the bottom section reads "IMMIGRATION - ENTRY". No specific dates or airport information. The stamp edges are rough and look hand-pressed, isolated on transparent background, PNG with alpha channel, no paper texture in background, clean edges.'
      },
    ];

    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              Icons.auto_fix_high,
              '도장 프롬프트 템플릿',
              Colors.purple,
            ),
            const SizedBox(height: 30),
            ...templates.map(
              (t) => _buildTemplateCard(
                t['title'] as String,
                t['prompt'] as String,
                t['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // Components
  // ============================
  Widget _buildTemplateCard(String title, String prompt, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyToClipboard(prompt),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prompt,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(18),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

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
              color: isSelected ? Colors.blueAccent : const Color(0xFFE5E7EB),
            ),
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
    final isSelected = _selectedTopic == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTopic = value),
      selectedColor: Colors.blueAccent.withOpacity(0.1),
      checkmarkColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blueAccent : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
