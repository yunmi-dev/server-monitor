// lib/screens/detail_settings_screen.dart
import 'package:flutter/material.dart';

class DetailSettingsScreen extends StatelessWidget {
  const DetailSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('알림 설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingGroup(
            '이메일 알림',
            [
              _buildSwitch('알림 활성화', true),
              _buildThresholdSetting('CPU 사용량 임계값', 80),
              _buildThresholdSetting('메모리 사용량 임계값', 90),
              _buildThresholdSetting('디스크 사용량 임계값', 90),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingGroup(
            '알림 설정',
            [
              _buildSwitch('다운타임 알림', true),
              _buildSwitch('에러 알림', true),
              _buildSwitch('경고 알림', true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingGroup(
            '모니터링 주기',
            [
              _buildDropdownSetting(
                '데이터 수집 주기',
                '1분',
                ['30초', '1분', '5분', '10분'],
              ),
              _buildDropdownSetting(
                '알림 확인 주기',
                '즉시',
                ['즉시', '1분', '5분', '10분'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingGroup(String title, List<Widget> children) {
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Update setting
            },
            activeColor: Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSetting(String label, int value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$value%',
            activeColor: Colors.pink,
            onChanged: (newValue) {
              // Update threshold
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              // Update setting
            },
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
