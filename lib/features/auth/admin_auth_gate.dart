import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:travel_memoir_admin/features/auth/admin_login_page.dart';
import 'package:travel_memoir_admin/layout/admin_layout.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        // 🔐 로그인 안됨 → 로그인 페이지
        if (user == null) {
          return const AdminLoginPage();
        }

        // 🔓 로그인 됨 → 관리자 레이아웃
        return const AdminLayout();
      },
    );
  }
}
