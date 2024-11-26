// lib/screens/settings/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/providers/settings_provider.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('알림 설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _showResetConfirmation,
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          if (!settings.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: AppConstants.defaultPadding,
            children: [
              _buildGeneralSection(settings),
              const SizedBox(height: AppConstants.spacing * 2),
              _buildAlertTypesSection(settings),
              const SizedBox(height: AppConstants.spacing * 2),
              _buildScheduleSection(settings),
              const SizedBox(height: AppConstants.spacing * 2),
              _buildThresholdsSection(settings),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '설정 초기화',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '모든 알림 설정을 기본값으로 초기화하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await Provider.of<SettingsProvider>(context, listen: false)
          .resetToDefaults();
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, '설정이 초기화되었습니다');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, '설정 초기화 실패: ${e.toString()}');
    }
  }

  Widget _buildGeneralSection(SettingsProvider settings) {
    return _buildSection(
      title: '일반',
      children: [
        SwitchListTile(
          title: const Text('푸시 알림'),
          subtitle: const Text('실시간 알림을 받습니다'),
          value: settings.pushNotificationsEnabled,
          onChanged: (value) => settings.setPushNotifications(value),
        ),
        SwitchListTile(
          title: const Text('이메일 알림'),
          subtitle: const Text('중요 알림을 이메일로 받습니다'),
          value: settings.emailNotificationsEnabled,
          onChanged: (value) => settings.setEmailNotifications(value),
        ),
        SwitchListTile(
          title: const Text('소리'),
          subtitle: const Text('알림 소리를 사용합니다'),
          value: settings.soundEnabled,
          onChanged: (value) => settings.setSound(value),
        ),
        SwitchListTile(
          title: const Text('진동'),
          subtitle: const Text('알림 진동을 사용합니다'),
          value: settings.vibrationEnabled,
          onChanged: (value) => settings.setVibration(value),
        ),
      ],
    );
  }

  Widget _buildAlertTypesSection(SettingsProvider settings) {
    final categories = settings.notificationCategories;

    return _buildSection(
      title: '알림 종류',
      children: [
        CheckboxListTile(
          title: const Text('정보'),
          subtitle: const Text('시스템 정보 알림'),
          value: categories.contains('info'),
          onChanged: (value) {
            if (value == true) {
              settings.setNotificationCategories([...categories, 'info']);
            } else {
              settings.setNotificationCategories(
                categories.where((c) => c != 'info').toList(),
              );
            }
          },
        ),
        CheckboxListTile(
          title: const Text('경고'),
          subtitle: const Text('경고 수준의 알림'),
          value: categories.contains('warning'),
          onChanged: (value) {
            if (value == true) {
              settings.setNotificationCategories([...categories, 'warning']);
            } else {
              settings.setNotificationCategories(
                categories.where((c) => c != 'warning').toList(),
              );
            }
          },
        ),
        CheckboxListTile(
          title: const Text('오류'),
          subtitle: const Text('오류 발생 알림'),
          value: categories.contains('error'),
          onChanged: (value) {
            if (value == true) {
              settings.setNotificationCategories([...categories, 'error']);
            } else {
              settings.setNotificationCategories(
                categories.where((c) => c != 'error').toList(),
              );
            }
          },
        ),
        CheckboxListTile(
          title: const Text('심각'),
          subtitle: const Text('긴급 대응이 필요한 알림'),
          value: categories.contains('critical'),
          onChanged: (value) {
            if (value == true) {
              settings.setNotificationCategories([...categories, 'critical']);
            } else {
              settings.setNotificationCategories(
                categories.where((c) => c != 'critical').toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection(SettingsProvider settings) {
    return _buildSection(
      title: '알림 스케줄',
      children: [
        SwitchListTile(
          title: const Text('방해 금지 모드'),
          value: settings.doNotDisturbEnabled,
          onChanged: (value) => settings.setDoNotDisturbEnabled(value),
        ),
        if (settings.doNotDisturbEnabled)
          ListTile(
            title: const Text('방해 금지 시간'),
            subtitle: Text(
                '${settings.doNotDisturbStart} - ${settings.doNotDisturbEnd}'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showDoNotDisturbPicker(settings),
          ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('주말 알림'),
          subtitle: const Text('주말에도 알림을 받습니다'),
          value: settings.weekendNotificationsEnabled,
          onChanged: (value) => settings.setWeekendNotifications(value),
        ),
      ],
    );
  }

  // DoNotDisturb 시간 선택 개선
  Future<void> _showDoNotDisturbPicker(SettingsProvider settings) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(settings.doNotDisturbStart),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              hourMinuteColor: Colors.grey.withOpacity(0.2),
              dialBackgroundColor: Colors.grey.withOpacity(0.1),
              dayPeriodColor: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (startTime != null && mounted) {
      final TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: _parseTimeOfDay(settings.doNotDisturbEnd),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color(0xFF1E1E1E),
                hourMinuteColor: Colors.grey.withOpacity(0.2),
                dialBackgroundColor: Colors.grey.withOpacity(0.1),
                dayPeriodColor: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: child!,
          );
        },
      );

      if (endTime != null && mounted) {
        settings.setDoNotDisturbTime(
          '${startTime.format(context)} - ${endTime.format(context)}',
        );
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1].split(' ')[0]),
    );
  }

  Widget _buildThresholdsSection(SettingsProvider settings) {
    return _buildSection(
      title: '알림 임계값',
      children: [
        _buildThresholdSlider(
          label: 'CPU 사용률',
          value: settings.cpuWarningThreshold,
          onChanged: (value) => settings.setCpuWarningThreshold(value),
        ),
        const Divider(height: 1),
        _buildThresholdSlider(
          label: '메모리 사용률',
          value: settings.memoryWarningThreshold,
          onChanged: (value) => settings.setMemoryWarningThreshold(value),
        ),
        const Divider(height: 1),
        _buildThresholdSlider(
          label: '디스크 사용률',
          value: settings.diskWarningThreshold,
          onChanged: (value) => settings.setDiskWarningThreshold(value),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: AppConstants.spacing),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing,
        vertical: AppConstants.spacing / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              Text('${value.round()}%',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Slider(
            value: value,
            min: 50,
            max: 95,
            divisions: 45,
            label: '${value.round()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
