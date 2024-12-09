// lib/screens/monitoring/server_monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/time_range.dart'; // TimeRange enum import
import 'package:flutter_client/widgets/charts/animated_progress_ring.dart';
import 'package:flutter_client/widgets/monitoring/line_chart_card.dart';
import 'package:flutter_client/services/websocket_service.dart';

class ServerMonitoringScreen extends StatefulWidget {
  const ServerMonitoringScreen({super.key});

  @override
  State<ServerMonitoringScreen> createState() => _ServerMonitoringScreenState();
}

class _ServerMonitoringScreenState extends State<ServerMonitoringScreen> {
  TimeRange _selectedTimeRange = TimeRange.hour; // 기본값 1시간

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsService = WebSocketService.instance;
      if (!wsService.isConnected) {
        wsService.connect();
      }
      context.read<ServerProvider>().loadServers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        if (provider.servers.isEmpty) {
          return const Center(child: Text('등록된 서버가 없습니다'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 시간 범위 선택 드롭다운
                  DropdownButton<TimeRange>(
                    value: _selectedTimeRange,
                    items: TimeRange.values.map((range) {
                      return DropdownMenuItem(
                        value: range,
                        child: Text(range.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTimeRange = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.refreshAll(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final server in provider.servers) ...[
                      _ServerMonitoringCard(
                        server: server,
                        timeRange: _selectedTimeRange,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServerMonitoringCard extends StatelessWidget {
  final Server server;
  final TimeRange timeRange;

  const _ServerMonitoringCard({
    required this.server,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  server.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _StatusIndicator(status: server.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AnimatedProgressRing(
                  progress: server.resources.cpu,
                  label: 'CPU',
                  color: Colors.blue,
                  icon: Icons.memory,
                ),
                AnimatedProgressRing(
                  progress: server.resources.memory,
                  label: 'Memory',
                  color: Colors.green,
                  icon: Icons.sd_storage,
                ),
                AnimatedProgressRing(
                  progress: server.resources.disk,
                  label: 'Disk',
                  color: Colors.orange,
                  icon: Icons.storage,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: LineChartCard(
                    title: 'CPU Usage',
                    stream: context.read<ServerProvider>().watchCpuMetrics(
                          server.id,
                          timeRange,
                        ),
                    color: Colors.blue,
                    formatLabel: (value) => '${value.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LineChartCard(
                    title: 'Memory Usage',
                    stream: context.read<ServerProvider>().watchMemoryMetrics(
                          server.id,
                          timeRange,
                        ),
                    color: Colors.green,
                    formatLabel: (value) => '${value.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LineChartCard(
                    title: 'Disk Usage',
                    stream: context.read<ServerProvider>().watchDiskMetrics(
                          server.id,
                          timeRange,
                        ),
                    color: Colors.orange,
                    formatLabel: (value) => '${value.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final ServerStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
