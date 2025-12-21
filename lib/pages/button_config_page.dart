import 'package:flutter/material.dart';

class ButtonConfigPage extends StatelessWidget {
  const ButtonConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminEmptyPageTemplate(
      title: '버튼 설정',
      subtitle: '여기서 홈/작성/저장 등 버튼 라벨·노출 여부를 관리할 예정',
      icon: Icons.touch_app,
    );
  }
}

class _AdminEmptyPageTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AdminEmptyPageTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44),
              const SizedBox(height: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              const Text(
                '✅ 페이지 연결 완료',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
