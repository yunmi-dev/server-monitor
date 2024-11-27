// lib/screens/server_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/time_range.dart';
import 'package:flutter_client/widgets/monitoring/resource_gauge.dart';
import 'package:flutter_client/widgets/monitoring/line_chart_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';

class ServerDetailsScreen extends StatefulWidget {
  final String serverId;
  final Server server;

  const ServerDetailsScreen({
    super.key,
    required this.serverId,
    required this.server,
  });

  @override
  State<ServerDetailsScreen> createState() => _ServerDetailsScreenState();
}

class _ServerDetailsScreenState extends State<ServerDetailsScreen> {
  final ValueNotifier<TimeRange> _timeRange = ValueNotifier(TimeRange.hour);
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Text(widget.server.name),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.server.status.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() => _isRefreshing = true);
                    await context
                        .read<ServerProvider>()
                        .refreshServerData(widget.serverId);
                    if (mounted) {
                      setState(() => _isRefreshing = false);
                    }
                  },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restart',
                child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('서버 재시작'),
                ),
              ),
              const PopupMenuItem(
                value: 'stop',
                child: ListTile(
                  leading: Icon(Icons.stop),
                  title: Text('서버 중지'),
                ),
              ),
              const PopupMenuItem(
                value: 'logs',
                child: ListTile(
                  leading: Icon(Icons.article),
                  title: Text('로그 보기'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('서버 설정'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<ServerProvider>().refreshServerData(widget.serverId),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServerInfo(),
                const SizedBox(height: 24),
                _buildResourceGauges(),
                const SizedBox(height: 24),
                _buildSystemInfo(), // 추가
                const SizedBox(height: 24),
                _buildTimeRangeSelector(),
                const SizedBox(height: 16),
                _buildMetricsCharts(),
                const SizedBox(height: 24),
                _buildNetworkMonitoring(), // 추가
                const SizedBox(height: 24),
                _buildProcessList(),
                const SizedBox(height: 24),
                _buildRecentLogs(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerInfo() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.computer, color: Colors.white70),
              title: const Text('서버 정보', style: TextStyle(color: Colors.white)),
              subtitle: Text(widget.server.type ?? '알 수 없음',
                  style: const TextStyle(color: Colors.white70)),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.white70),
              title: const Text('가동 시간', style: TextStyle(color: Colors.white)),
              subtitle: Text(widget.server.uptime,
                  style: const TextStyle(color: Colors.white70)),
            ),
            if (widget.server.host != null) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.dns, color: Colors.white70),
                title: const Text('호스트', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${widget.server.host}:${widget.server.port}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResourceGauges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ResourceGauge(
          title: 'CPU',
          value: widget.server.resources.cpuUsage,
          color: _getResourceColor(widget.server.resources.cpuUsage),
          icon: Icons.memory,
        ),
        ResourceGauge(
          title: '메모리',
          value: widget.server.resources.memoryUsage,
          color: _getResourceColor(widget.server.resources.memoryUsage),
          icon: Icons.storage,
        ),
        ResourceGauge(
          title: '디스크',
          value: widget.server.resources.diskUsage,
          color: _getResourceColor(widget.server.resources.diskUsage),
          icon: Icons.disc_full,
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ValueListenableBuilder<TimeRange>(
          valueListenable: _timeRange,
          builder: (context, timeRange, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: TimeRange.values.map((range) {
                return ChoiceChip(
                  label: Text(range.label),
                  selected: timeRange == range,
                  onSelected: (selected) {
                    if (selected) {
                      _timeRange.value = range;
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.black26,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsCharts() {
    return ValueListenableBuilder<TimeRange>(
      valueListenable: _timeRange,
      builder: (context, timeRange, _) {
        return Column(
          children: [
            LineChartCard(
              title: 'CPU 사용량',
              stream: context.read<ServerProvider>().watchCpuMetrics(
                    widget.serverId,
                    timeRange,
                  ),
              color: Colors.blue,
              formatLabel: (value) => '${value.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            LineChartCard(
              title: '메모리 사용량',
              stream: context.read<ServerProvider>().watchMemoryMetrics(
                    widget.serverId,
                    timeRange,
                  ),
              color: Colors.green,
              formatLabel: (value) => '${value.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            LineChartCard(
              title: '디스크 사용량',
              stream: context.read<ServerProvider>().watchDiskMetrics(
                    widget.serverId,
                    timeRange,
                  ),
              color: Colors.purple,
              formatLabel: (value) => '${value.toStringAsFixed(1)}%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildProcessList() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '실행 중인 프로세스',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/server/processes',
                      arguments: {'server': widget.server},
                    );
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.server.processes.take(5).length,
            itemBuilder: (context, index) {
              final process = widget.server.processes[index];
              return ListTile(
                title: Text(
                  process.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'PID: ${process.pid}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  'CPU: ${process.cpuUsage.toStringAsFixed(1)}%\nMEM: ${process.memoryUsage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 로그',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/logs',
                      arguments: {'serverId': widget.serverId},
                    );
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.server.recentLogs.take(5).length,
            itemBuilder: (context, index) {
              final log = widget.server.recentLogs[index];
              return ListTile(
                title: Text(
                  log.message,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${log.timestamp.toString()} - ${log.level}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getResourceColor(double value) {
    if (value >= 90) {
      return Colors.red;
    } else if (value >= 75) {
      return Colors.orange;
    } else if (value >= 60) {
      return Colors.yellow;
    }
    return Colors.green;
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'restart':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('서버 재시작'),
            content: const Text('정말 서버를 재시작하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('재시작'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          // Implement server restart
        }
        break;

      case 'stop':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('서버 중지'),
            content: const Text('정말 서버를 중지하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('중지'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          // Implement server stop
        }
        break;

      case 'logs':
        Navigator.pushNamed(
          context,
          '/logs',
          arguments: {'serverId': widget.serverId},
        );
        break;

      case 'settings':
        Navigator.pushNamed(
          context,
          '/server/settings',
          arguments: {'server': widget.server},
        );
        break;
    }
  }

// 네트워크 모니터링 섹션 추가
  Widget _buildNetworkMonitoring() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '네트워크 모니터링',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNetworkStatCard(
                    '수신',
                    Icons.download,
                    Colors.green,
                    '1.2 MB/s',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNetworkStatCard(
                    '송신',
                    Icons.upload,
                    Colors.blue,
                    '0.8 MB/s',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNetworkConnectionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatCard(
    String title,
    IconData icon,
    Color color,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkConnectionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '활성 연결',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.lan,
                color: Colors.white70,
              ),
              title: Text(
                '192.168.1.${100 + index}:8080',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'TCP - ESTABLISHED',
                style: TextStyle(
                  color: Colors.green.withOpacity(0.7),
                ),
              ),
              trailing: Text(
                '${(index + 1) * 50} KB/s',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          },
        ),
      ],
    );
  }

// 시스템 정보 상세보기 섹션 추가
  Widget _buildSystemInfo() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: ExpansionTile(
        title: const Text(
          '시스템 정보',
          style: TextStyle(color: Colors.white),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSystemInfoRow('운영체제', 'Ubuntu 22.04 LTS'),
                _buildSystemInfoRow('커널 버전', '5.15.0-56-generic'),
                _buildSystemInfoRow('프로세서', 'Intel Core i7-9700K @ 3.60GHz'),
                _buildSystemInfoRow('총 메모리', '32GB DDR4'),
                _buildSystemInfoRow('디스크', 'SSD 500GB (사용 가능: 350GB)'),
                _buildSystemInfoRow('네트워크 인터페이스', 'eth0, wlan0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
