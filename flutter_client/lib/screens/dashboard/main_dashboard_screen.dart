// lib/screens/dashboard/main_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/models/server_metrics.dart';
import 'package:flutter_client/widgets/dashboard/server_status_card.dart';
import 'package:flutter_client/widgets/charts/animated_progress_ring.dart';
import 'package:flutter_client/models/alert.dart';
import 'package:flutter_client/theme/color_extensions.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 서버 메트릭스 더미 데이터
  final List<ServerMetrics> _serverMetrics = [
    ServerMetrics(
      serverId: '1',
      serverName: 'Production DB',
      cpuUsage: 65.0,
      memoryUsage: 82.0,
      diskUsage: 45.0,
      networkUsage: 28.0,
      processCount: 128,
      timestamp: DateTime.now(),
    ),
    ServerMetrics(
      serverId: '2',
      serverName: 'Web Server',
      cpuUsage: 45.0,
      memoryUsage: 72.0,
      diskUsage: 38.0,
      networkUsage: 42.0,
      processCount: 86,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text('대시보드'),
            floating: true,
            pinned: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '개요'),
                Tab(text: '성능'),
                Tab(text: '자원'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildPerformanceTab(),
            _buildResourcesTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 서버 추가 기능 구현
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  final List<Alert> _alerts = [
    Alert(
      id: '1',
      title: 'CPU 사용률 높음',
      message: 'Server 1의 CPU 사용률이 90%를 초과했습니다.',
      severity: AlertSeverity.warning,
      serverId: '1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      serverName: 'Production DB',
    ),
    Alert(
      id: '2',
      title: '메모리 부족',
      message: 'Server 2의 가용 메모리가 10% 미만입니다.',
      severity: AlertSeverity.error,
      serverId: '2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      serverName: 'Web Server',
    ),
    Alert(
      id: '3',
      title: '디스크 공간 부족',
      message: 'Server 1의 디스크 공간이 95%를 초과했습니다.',
      severity: AlertSeverity.critical,
      serverId: '1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      serverName: 'Production DB',
    ),
  ];

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildQuickStats(),
        const SizedBox(height: 16),
        _buildServerList(),
        const SizedBox(height: 16),
        _buildRecentAlerts(),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시스템 개요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: AnimatedProgressRing(
                    progress: 0.65,
                    label: 'CPU 사용률',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.memory,
                  ),
                ),
                Expanded(
                  child: AnimatedProgressRing(
                    progress: 0.82,
                    label: '메모리 사용률',
                    color: Theme.of(context).colorScheme.secondary,
                    icon: Icons.storage,
                  ),
                ),
                Expanded(
                  child: AnimatedProgressRing(
                    progress: 0.45,
                    label: '디스크 사용률',
                    color: Theme.of(context).colorScheme.tertiary,
                    icon: Icons.disc_full,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '서버 상태',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () {
                // 서버 목록 페이지로 이동
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _serverMetrics.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return ServerStatusCard(
              metrics: _serverMetrics[index],
              onTap: () {
                // 서버 상세 페이지로 이동
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '최근 알림',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    // 알림 전체보기 페이지로 이동
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('전체보기'),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alerts.length,
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return ListTile(
                leading: Icon(
                  alert.severity.icon,
                  color: alert.severity.color,
                ),
                title: Text(alert.title),
                subtitle: Text(alert.serverName ?? '알 수 없는 서버'),
                trailing: Text(
                  '${DateTime.now().difference(alert.timestamp).inMinutes}분 전',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  // 알림 상세 보기
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPerformanceChart(),
        const SizedBox(height: 16),
        _buildPerformanceMetrics(),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CPU 사용률 추이',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white12),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(24, (index) {
                        return FlSpot(index.toDouble(),
                            50 + 30 * (index % 3 - 1) + 10 * (index % 2));
                      }),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '성능 지표',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMetricTile(
              '평균 응답 시간',
              '245ms',
              Icons.timer,
              Theme.of(context).colorScheme.primary,
            ),
            _buildMetricTile(
              '초당 요청 수',
              '1,234',
              Icons.show_chart,
              Theme.of(context).colorScheme.secondary,
            ),
            _buildMetricTile(
              '활성 사용자',
              '3,456',
              Icons.people,
              Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResourceUsageCard('CPU 사용률', 0.65),
        const SizedBox(height: 16),
        _buildResourceUsageCard('메모리 사용률', 0.82),
        const SizedBox(height: 16),
        _buildResourceUsageCard('디스크 사용률', 0.45),
        const SizedBox(height: 16),
        _buildResourceUsageCard('네트워크 사용률', 0.28),
      ],
    );
  }

  Widget _buildResourceUsageCard(String title, double value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 20,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  value > 0.8
                      ? Theme.of(context).colorScheme.error
                      : value > 0.6
                          ? Theme.of(context).colorScheme.warningColor
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
