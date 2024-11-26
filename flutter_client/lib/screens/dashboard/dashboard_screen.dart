// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
//import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServerCategories(),
          const SizedBox(height: 24),
          _buildUsageSection(),
          const SizedBox(height: 24),
          _buildServerList(),
        ],
      ),
    );
  }

  Widget _buildServerCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryItem(
          'Total Servers',
          '14',
          [12, 13, 14, 14, 14],
          Colors.white,
        ),
        const SizedBox(height: 12),
        _buildCategoryItem(
          'At-Risk Servers',
          '2',
          [1, 2, 2, 2, 2],
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildCategoryItem(
          'Safe Servers',
          '9',
          [7, 8, 9, 9, 9],
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    String label,
    String count,
    List<int> trend,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.expand_more,
              color: Colors.grey,
            ),
            onPressed: () {
              // Toggle category details
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildUsageIndicator(
                'CPU 사용량',
                0.20,
                Colors.pink,
              ),
              _buildUsageIndicator(
                '메모리 사용량',
                0.81,
                Colors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageIndicator(String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 10,
              ),
              Center(
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildServerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Server List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildServerListItem('Server 1', true),
        _buildServerListItem('Server 2', false),
        _buildServerListItem('Server 3', true),
        _buildServerListItem('Server 4', true),
      ],
    );
  }

  Widget _buildServerListItem(String name, bool isOnline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.expand_more,
              color: Colors.grey,
            ),
            onPressed: () {
              // Show server details
            },
          ),
        ],
      ),
    );
  }
}

// lib/screens/settings_screen.dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            '로그',
            [
              _buildSettingItem(
                '로그 보관 기간',
                '7일',
                icon: Icons.history,
              ),
              _buildSettingItem(
                '네트워크 로그',
                true,
                icon: Icons.wifi,
              ),
              _buildSettingItem(
                '시스템 로그',
                true,
                icon: Icons.computer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            '알림',
            [
              _buildSettingItem(
                '이메일 알림',
                true,
                icon: Icons.email,
              ),
              _buildSettingItem(
                '푸시 알림',
                false,
                icon: Icons.notifications,
              ),
              _buildSettingItem(
                '알림 주기',
                '실시간',
                icon: Icons.timer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            '보안',
            [
              _buildSettingItem(
                '데이터 암호화',
                true,
                icon: Icons.security,
              ),
              _buildSettingItem(
                '2단계 인증',
                false,
                icon: Icons.verified_user,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            '기타',
            [
              _buildSettingItem(
                '언어',
                '한국어',
                icon: Icons.language,
              ),
              _buildSettingItem(
                '테마',
                '다크',
                icon: Icons.dark_mode,
              ),
              _buildSettingItem(
                '서버 주소',
                'localhost:8080',
                icon: Icons.dns,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, dynamic value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (value is bool)
            Switch(
              value: value,
              onChanged: (newValue) {
                // Update setting
              },
              activeColor: Colors.pink,
            )
          else
            Row(
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
