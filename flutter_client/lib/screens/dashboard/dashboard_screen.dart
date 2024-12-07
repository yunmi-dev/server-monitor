// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/constants/route_paths.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/screens/alerts/alerts_screen.dart';
import 'package:flutter_client/screens/stats/stats_screen.dart';
import 'package:flutter_client/screens/server/servers_screen.dart';
import 'package:flutter_client/screens/settings/settings_screen.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isKeyboardVisible = false;
  final _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };

  final List<Widget> _screens = const [
    DashboardView(),
    StatsScreen(),
    ServersScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    KeyboardVisibilityController().onChange.listen((bool visible) {
      setState(() {
        _isKeyboardVisible = visible;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final navigator = _navigatorKeys[_selectedIndex]?.currentState;
        if (navigator == null) return;
        await navigator.maybePop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
            if (!_isKeyboardVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.grey[900],
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 60,
                      child: BottomNavigationBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        currentIndex: _selectedIndex,
                        selectedItemColor: const Color(0xFFEE477C),
                        unselectedItemColor: Colors.grey,
                        type: BottomNavigationBarType.fixed,
                        selectedFontSize: 11,
                        unselectedFontSize: 11,
                        iconSize: 24,
                        showUnselectedLabels: true,
                        onTap: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        items: const [
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.cottage_outlined),
                            ),
                            activeIcon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.cottage_rounded),
                            ),
                            label: '홈',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.show_chart),
                            ),
                            activeIcon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.show_chart),
                            ),
                            label: '통계',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.dns_outlined),
                            ),
                            activeIcon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.dns_rounded),
                            ),
                            label: '서버',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.notifications_outlined),
                            ),
                            activeIcon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.notifications_rounded),
                            ),
                            label: '알림',
                          ),
                          BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.segment),
                            ),
                            activeIcon: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Icon(Icons.segment_rounded),
                            ),
                            label: '메뉴',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: const Text('Dashboard'),
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<ServerProvider>().refreshAll();
                  },
                ),
              ],
            ),
          ];
        },
        body: Consumer<ServerProvider>(builder: (context, serverProvider, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildServerCategories(context, serverProvider),
                    const SizedBox(height: 24),
                    _buildUsageSection(serverProvider),
                    const SizedBox(height: 24),
                    _buildServerList(context, serverProvider),
                    // 하단에 여백 추가하여 BottomNavigationBar 가림 방지
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildServerCategories(BuildContext context, ServerProvider provider) {
    final totalServers = provider.servers.length;
    final atRiskServers = provider.servers.where((s) => s.hasWarnings).length;
    final safeServers = totalServers - atRiskServers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryItem(
          context,
          'Total Servers',
          totalServers.toString(),
          provider.serverTrends['total'] ?? [0, 0, 0, 0, 0],
          Colors.white,
        ),
        const SizedBox(height: 12),
        _buildCategoryItem(
          context,
          'At-Risk Servers',
          atRiskServers.toString(),
          provider.serverTrends['atRisk'] ?? [0, 0, 0, 0, 0],
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildCategoryItem(
          context,
          'Safe Servers',
          safeServers.toString(),
          provider.serverTrends['safe'] ?? [0, 0, 0, 0, 0],
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
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
      child: Column(
        children: [
          Row(
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
                onPressed: () => _showTrendDetails(context, label, trend),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: trend.length.toDouble() - 1,
                minY: 0,
                maxY: trend.reduce((a, b) => a > b ? a : b).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: color.withOpacity(0.5),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection(ServerProvider provider) {
    final avgCpuUsage = provider.getAverageCpuUsage();
    final avgMemoryUsage = provider.getAverageMemoryUsage();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Usage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => provider.refreshResourceUsage(),
                child: const Text('새로고침'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildUsageIndicator(
                'CPU 사용량',
                avgCpuUsage,
                _getUsageColor(avgCpuUsage),
              ),
              _buildUsageIndicator(
                '메모리 사용량',
                avgMemoryUsage,
                _getUsageColor(avgMemoryUsage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(double value) {
    if (value >= AppConstants.criticalThreshold) {
      return Colors.red;
    } else if (value >= AppConstants.warningThreshold) {
      return Colors.orange;
    }
    return Colors.pink;
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
                value: value / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 10,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getUsageStatus(value),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ],
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

  String _getUsageStatus(double value) {
    if (value >= AppConstants.criticalThreshold) {
      return '위험';
    } else if (value >= AppConstants.warningThreshold) {
      return '경고';
    }
    return '정상';
  }

  Widget _buildServerList(BuildContext context, ServerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Server List',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, RoutePaths.servers);
              },
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...provider.servers.take(4).map((server) => _buildServerListItem(
              context,
              server.name,
              server.isOnline,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RoutePaths.serverDetails,
                  arguments: {'server': server},
                );
              },
            )),
      ],
    );
  }

  Widget _buildServerListItem(
    BuildContext context,
    String name,
    bool isOnline, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showTrendDetails(BuildContext context, String title, List<int> trend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$title 트렌드',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 2,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt() + 1}일',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: trend.length.toDouble() - 1,
                  minY: 0,
                  maxY: trend.reduce((a, b) => a > b ? a : b).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trend.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.pink,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.pink.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
