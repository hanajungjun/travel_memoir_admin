import 'package:flutter/material.dart';
import 'package:travel_memoir_admin/services/admin_dashboard_service.dart';
import 'package:travel_memoir_admin/pages/admin/admin_photo_list_page.dart';
import 'package:travel_memoir_admin/pages/admin/admin_active_user_chart_page.dart';
import 'package:travel_memoir_admin/pages/admin/admin_new_user_chart_page.dart';
import 'package:travel_memoir_admin/pages/admin/admin_premium_user_list_page.dart';
import 'package:travel_memoir_admin/pages/admin/admin_premium_expiring_page.dart';
import 'package:travel_memoir_admin/pages/admin/mini_sparkline.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminDashboardService _service = AdminDashboardService();

  late Future<int> _totalUserCountFuture;
  late Future<int> _yesterdayActiveUserCountFuture;
  late Future<int> _uploadedPhotoCountFuture;
  late Future<int> _activePremiumUserCountFuture;
  late Future<int> _premiumExpiringSoonCountFuture;
  late Future<List<int>> _premiumExpiringSparklineFuture;
  late Future<bool> _isReviewModeFuture;
  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

// 데이터 새로고침 함수
  void _refreshStats() {
    setState(() {
      _totalUserCountFuture = _service.getTotalUserCount();
      _yesterdayActiveUserCountFuture = _service.getYesterdayActiveUserCount();
      _uploadedPhotoCountFuture = _service.getUploadedPhotoCount();
      _activePremiumUserCountFuture = _service.getActivePremiumUserCount();
      _premiumExpiringSoonCountFuture = _service.getPremiumExpiringSoonCount();
      _premiumExpiringSparklineFuture = _service.getPremiumExpiringSparkline();
      _isReviewModeFuture = _service.getReviewMode(); // 👈 심사 모드 로드
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            children: [
              /// 👤 총 가입자 수
              FutureBuilder<int>(
                future: _totalUserCountFuture,
                builder: (context, snapshot) {
                  return StatCard(
                    title: '총 가입자 수',
                    subtitle: '누적 가입자',
                    value: snapshot.data?.toString() ?? '-',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminNewUserChartPage(),
                        ),
                      );
                    },
                  );
                },
              ),

              /// 🔑 어제 접속자 수
              FutureBuilder<int>(
                future: _yesterdayActiveUserCountFuture,
                builder: (context, snapshot) {
                  return StatCard(
                    title: '어제 접속자 수',
                    subtitle: '활동 기준 (updated_at)',
                    value: snapshot.data?.toString() ?? '-',
                    icon: Icons.login,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminActiveUserChartPage(),
                        ),
                      );
                    },
                  );
                },
              ),

              /// 🖼 업로드된 사진 수
              FutureBuilder<int>(
                future: _uploadedPhotoCountFuture,
                builder: (context, snapshot) {
                  return StatCard(
                    title: '업로드된 사진 수',
                    subtitle: '유저 업로드 기준',
                    value: snapshot.data?.toString() ?? '-',
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPhotoListPage(),
                        ),
                      );
                    },
                  );
                },
              ),

              /// 💎 현재 프리미엄 유저
              FutureBuilder<int>(
                future: _activePremiumUserCountFuture,
                builder: (context, snapshot) {
                  return StatCard(
                    title: '프리미엄 유저',
                    subtitle: '현재 활성',
                    value: snapshot.data?.toString() ?? '-',
                    icon: Icons.workspace_premium,
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPremiumUserListPage(),
                        ),
                      );
                    },
                  );
                },
              ),

              /// ⏰ 만료 예정 + 스파크라인
              FutureBuilder<List<int>>(
                future: _premiumExpiringSparklineFuture,
                builder: (context, sparkSnapshot) {
                  return FutureBuilder<int>(
                    future: _premiumExpiringSoonCountFuture,
                    builder: (context, countSnapshot) {
                      return StatCard(
                        title: '만료 예정',
                        subtitle: '7일 이내',
                        value: countSnapshot.data?.toString() ?? '-',
                        icon: Icons.timer,
                        color: Colors.redAccent,
                        trailing: sparkSnapshot.hasData
                            ? MiniSparkline(
                                values: sparkSnapshot.data!,
                                color: Colors.redAccent,
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPremiumExpiringPage(),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              /// 🍎 6. [신규] 애플 심사 모드 토글
              FutureBuilder<bool>(
                future: _isReviewModeFuture,
                builder: (context, snapshot) {
                  bool isOn = snapshot.data ?? false;
                  return StatCard(
                    title: '애플 심사 모드',
                    subtitle: isOn ? '심사 중 (ID/PW 노출)' : '일반 모드 (소셜 전용)',
                    value: isOn ? 'ON' : 'OFF',
                    icon: Icons.apple,
                    color: isOn ? Colors.orange : Colors.grey,
                    trailing: Switch(
                      value: isOn,
                      activeColor: Colors.orange,
                      onChanged: (val) async {
                        await _service.updateReviewMode(val);
                        _refreshStats(); // 상태 변경 후 즉시 새로고침
                      },
                    ),
                    onTap: () async {
                      await _service.updateReviewMode(!isOn);
                      _refreshStats();
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '관리자 안내',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '총 가입자 수는 users 테이블 기준 누적 값입니다.\n'
                  '어제 접속자 수는 updated_at 기준 활동 사용자 수입니다.\n'
                  '업로드된 사진 수는 travel_days.photo_urls 기준입니다.\n'
                  '프리미엄 유저는 is_premium = true 기준입니다.\n'
                  '만료 예정은 premium_until 기준 7일 이내 사용자입니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ====================== STAT CARD ====================== */
class StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 상단: 아이콘 + 값 + 스파크라인
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),

                /// 값
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// 스파크라인
                if (trailing != null) trailing!,
              ],
            ),

            const SizedBox(height: 10),

            /// 🔹 하단: title / subtitle (여기가 빠져 있었음)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
