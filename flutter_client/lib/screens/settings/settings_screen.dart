import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/settings_provider.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/widgets/settings/language_selection_sheet.dart';
import 'package:flutter_client/widgets/settings/delete_account_dialog.dart';
import 'package:flutter_client/widgets/settings/settings_section.dart';
import 'package:flutter_client/widgets/settings/timezone_selection_sheet.dart';
import 'package:flutter_client/widgets/settings/data_retention_sheet.dart';
import 'package:flutter_client/utils/extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserSection(context),
                      const SizedBox(height: 24),
                      _buildGeneralSettings(context, settings),
                      const SizedBox(height: 24),
                      _buildNotificationSettings(context, settings),
                      const SizedBox(height: 24),
                      _buildAlertSettings(context, settings),
                      const SizedBox(height: 24),
                      _buildAdvancedSettings(context, settings),
                      const SizedBox(height: 24),
                      _buildDangerZone(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.pink,
                child: Text(
                  auth.user?.name.substring(0, 1) ?? 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      auth.user?.email ?? 'email@example.com',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  // Navigate to profile edit
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneralSettings(
      BuildContext context, SettingsProvider settings) {
    return SettingsSection(
      title: '일반',
      backgroundColor: const Color(0xFF1E1E1E),
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      children: [
        _buildSettingsTile(
          title: '테마',
          trailing: DropdownButton<ThemeMode>(
            dropdownColor: const Color(0xFF1E1E1E),
            value: settings.themeMode,
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                settings.setThemeMode(newMode);
              }
            },
            items: ThemeMode.values.map((mode) {
              return DropdownMenuItem(
                value: mode,
                child: Text(
                  mode.name.capitalize(),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ),
        _buildSettingsTile(
          title: '언어',
          subtitle: settings.language,
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E1E),
              builder: (context) => const LanguageSelectionSheet(),
            );
          },
        ),
        _buildSettingsTile(
          title: '타임존',
          subtitle: settings.timeZone,
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E1E),
              builder: (context) => const TimeZoneSelectionSheet(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings(
      BuildContext context, SettingsProvider settings) {
    return SettingsSection(
      title: '알림',
      backgroundColor: const Color(0xFF1E1E1E),
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      children: [
        _buildSwitchTile(
          title: '푸시 알림',
          subtitle: '푸시 알림 받기',
          value: settings.pushNotificationsEnabled,
          onChanged: settings.setPushNotifications,
        ),
        _buildSwitchTile(
          title: '이메일 알림',
          subtitle: '이메일 알림 받기',
          value: settings.emailNotificationsEnabled,
          onChanged: settings.setEmailNotifications,
        ),
        _buildSettingsTile(
          title: '알림 스케줄',
          subtitle: '방해 금지 시간 설정',
          onTap: () {
            Navigator.pushNamed(context, '/notification-schedule');
          },
        ),
      ],
    );
  }

  Widget _buildAlertSettings(BuildContext context, SettingsProvider settings) {
    return SettingsSection(
      title: '경고 임계값',
      backgroundColor: const Color(0xFF1E1E1E),
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      children: [
        _buildSliderTile(
          context: context,
          title: 'CPU 경고 임계값',
          value: settings.cpuWarningThreshold,
          min: 50,
          max: 90,
          onChanged: settings.setCpuWarningThreshold,
        ),
        _buildSliderTile(
          context: context,
          title: '메모리 경고 임계값',
          value: settings.memoryWarningThreshold,
          min: 50,
          max: 90,
          onChanged: settings.setMemoryWarningThreshold,
        ),
        _buildSliderTile(
          context: context,
          title: '디스크 경고 임계값',
          value: settings.diskWarningThreshold,
          min: 70,
          max: 95,
          onChanged: settings.setDiskWarningThreshold,
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings(
      BuildContext context, SettingsProvider settings) {
    return SettingsSection(
      title: '고급 설정',
      backgroundColor: const Color(0xFF1E1E1E),
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      children: [
        _buildSettingsTile(
          title: '데이터 보관',
          subtitle: '${settings.dataRetentionDays}일',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E1E),
              builder: (context) => const DataRetentionSheet(),
            );
          },
        ),
        _buildSettingsTile(
          title: 'API 설정',
          subtitle: 'API 엔드포인트 설정',
          onTap: () {
            Navigator.pushNamed(context, '/api-settings');
          },
        ),
        _buildSettingsTile(
          title: '데이터 내보내기',
          subtitle: '모니터링 데이터 내보내기',
          onTap: () {
            Navigator.pushNamed(context, '/export-data');
          },
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return SettingsSection(
      title: '위험 구역',
      backgroundColor: const Color(0xFF1E1E1E),
      titleStyle: const TextStyle(
        color: Colors.red,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      children: [
        _buildSettingsTile(
          title: '설정 초기화',
          titleStyle: const TextStyle(color: Colors.red),
          trailing: const Icon(Icons.warning, color: Colors.red),
          onTap: () => _showResetDialog(context),
        ),
        _buildSettingsTile(
          title: '계정 삭제',
          titleStyle: const TextStyle(color: Colors.red),
          trailing: const Icon(Icons.delete_forever, color: Colors.red),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const DeleteAccountDialog(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    TextStyle? titleStyle,
  }) {
    return ListTile(
      title: Text(
        title,
        style: titleStyle ?? const TextStyle(color: Colors.white),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pink,
      inactiveTrackColor: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        children: [
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) ~/ 5).toInt(),
            label: '${value.round()}%',
            onChanged: onChanged,
            activeColor: Colors.pink,
            inactiveColor: Colors.grey.withOpacity(0.3),
          ),
          Text(
            '${value.round()}%',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '설정 초기화',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '모든 설정을 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Implement reset
              Navigator.pop(context);
            },
            child: const Text(
              '초기화',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
