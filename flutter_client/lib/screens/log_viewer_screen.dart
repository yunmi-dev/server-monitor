// lib/screens/log_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/widgets/logs/log_filter_chip.dart';
import 'package:flutter_client/widgets/logs/log_entry_card.dart';

// lib/screens/log_viewer_screen.dart
class LogViewerScreen extends StatelessWidget {
  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Log Viewer'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Text('Filter'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Logs'),
              ),
            ],
            onSelected: (value) {
              // Handle menu actions
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLogFilters(),
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterButton(
                  label: 'Error',
                  color: Colors.red,
                  selected: true,
                ),
                SizedBox(width: 8),
                _FilterButton(
                  label: 'Warning',
                  color: Colors.orange,
                  selected: true,
                ),
                SizedBox(width: 8),
                _FilterButton(
                  label: 'Info',
                  color: Colors.blue,
                  selected: true,
                ),
                SizedBox(width: 8),
                _FilterButton(
                  label: 'Debug',
                  color: Colors.grey,
                  selected: false,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SearchBar(
            hintText: 'Search logs...',
            leading: Icon(Icons.search),
            trailing: [Icon(Icons.tune)],
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (context, index) {
        return _LogItem(
          timestamp: DateTime.now().subtract(Duration(minutes: index)),
          level: _getRandomLogLevel(),
          message: 'Sample log message ${index + 1}',
          source: 'Server ${(index % 4) + 1}',
        );
      },
    );
  }

  String _getRandomLogLevel() {
    const levels = ['ERROR', 'WARNING', 'INFO'];
    return levels[DateTime.now().microsecond % levels.length];
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;

  const _FilterButton({
    required this.label,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        // Update filter
      },
      backgroundColor: Colors.transparent,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey,
      ),
      side: BorderSide(
        color: selected ? color : Colors.grey,
      ),
      showCheckmark: false,
    );
  }
}

class _LogItem extends StatelessWidget {
  final DateTime timestamp;
  final String level;
  final String message;
  final String source;

  const _LogItem({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getLevelIcon(),
              const SizedBox(width: 8),
              Text(
                level,
                style: TextStyle(
                  color: _getLevelColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            source,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getLevelIcon() {
    IconData icon;
    switch (level) {
      case 'ERROR':
        icon = Icons.error_outline;
        break;
      case 'WARNING':
        icon = Icons.warning_amber_outlined;
        break;
      default:
        icon = Icons.info_outline;
    }
    return Icon(icon, color: _getLevelColor(), size: 16);
  }

  Color _getLevelColor() {
    switch (level) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatTimestamp() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

// lib/screens/detail_settings_screen.dart
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
