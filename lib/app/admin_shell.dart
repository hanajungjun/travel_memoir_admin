import 'package:flutter/material.dart';

import 'package:travel_memoir_admin/widgets/admin_scaffold.dart';

import 'package:travel_memoir_admin/features/dashboard/admin_dashboard_page.dart';
import 'package:travel_memoir_admin/features/prompt/prompt_page.dart';
import 'package:travel_memoir_admin/features/prompt/image_prompt_page.dart';
import 'package:travel_memoir_admin/features/style/style_page.dart';
import 'package:travel_memoir_admin/features/prompt/ai_cover_prompt_page.dart';
import 'package:travel_memoir_admin/features/prompt/ai_map_prompt_page.dart';
import 'package:travel_memoir_admin/features/button/button_config_page.dart';
import 'package:travel_memoir_admin/features/history/history_page.dart';
import 'package:travel_memoir_admin/features/settings/admin_settings_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    AdminDashboardPage(), // 0
    PromptPage(), // 1 AI 프롬프트
    ImagePromptPage(), // 2 AI 이미지 프롬프트
    StylePage(), // 3 스타일 프롬프트
    AiCoverPromptPage(), // 4 AI 커버 프롬프트
    AiMapPromptPage(), // 5 AI 지도 프롬프트
    ButtonConfigPage(), // 6 버튼 설정
    HistoryPage(), // 7 히스토리
    AdminSettingsPage(), // 8 설정
  ];

  final _titles = const [
    '대시보드',
    'AI 프롬프트',
    'AI 이미지 프롬프트',
    '스타일 프롬프트',
    'AI 커버 프롬프트',
    'AI 지도 프롬프트',
    '버튼 설정',
    '히스토리',
    '설정',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _titles[_index],
      body: _pages[_index],
      selectedIndex: _index,
      onMenuSelected: (i) {
        setState(() => _index = i);
      },
    );
  }
}
