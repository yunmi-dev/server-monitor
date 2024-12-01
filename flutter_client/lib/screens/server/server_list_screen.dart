// lib/screens/server_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/widgets/server/server_list_item.dart';
import 'package:flutter_client/widgets/common/search_bar.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/constants/route_paths.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedFilters = [];
  List<Server> _filteredServers = [];
  int _selectedIndex = 2;
  bool _showBottomBar = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterServers(List<Server> servers, String query) {
    setState(() {
      _filteredServers = servers.where((server) {
        // 검색어로 필터링
        final nameMatch =
            server.name.toLowerCase().contains(query.toLowerCase());
        final hostMatch =
            server.host?.toLowerCase().contains(query.toLowerCase()) ?? false;
        final typeMatch =
            server.type?.toLowerCase().contains(query.toLowerCase()) ?? false;

        // 필터 적용
        bool matchesFilters = true;
        for (final filter in _selectedFilters) {
          switch (filter) {
            case 'Online':
              matchesFilters &= server.status == ServerStatus.online;
              break;
            case 'Offline':
              matchesFilters &= server.status == ServerStatus.offline;
              break;
            case 'Warning':
              matchesFilters &= server.status == ServerStatus.warning;
              break;
            case 'Critical':
              matchesFilters &= server.status == ServerStatus.critical;
              break;
            case 'High CPU':
              matchesFilters &= server.resources.cpu > 80; // cpu로 변경
              break;
            case 'High Memory':
              matchesFilters &= server.resources.memory > 80; // memory로 변경
              break;
            case 'High Disk':
              matchesFilters &= server.resources.disk > 80; // disk로 변경
              break;
          }
        }

        return (nameMatch || hostMatch || typeMatch) && matchesFilters;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  title: const Text('서버 목록'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pushNamed(context, RoutePaths.serverAdd);
                      },
                    ),
                  ],
                  floating: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomSearchBar(
                      controller: _searchController,
                      hintText: '서버 검색...',
                      filters: _selectedFilters,
                      onChanged: (query) {
                        final provider = context.read<ServerProvider>();
                        _filterServers(provider.servers, query);
                      },
                      onFilterTap: () {
                        // 필터 시트는 이미 CustomSearchBar에서 처리
                      },
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: Consumer<ServerProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // 재시도 로직
                                },
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        );
                      }

                      final servers = _searchController.text.isEmpty &&
                              _selectedFilters.isEmpty
                          ? provider.servers
                          : _filteredServers;

                      if (servers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dns_outlined,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty ||
                                        _selectedFilters.isNotEmpty
                                    ? '검색 결과가 없습니다'
                                    : '서버가 없습니다\n새로운 서버를 추가해보세요',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          // 서버 목록 새로고침 로직
                        },
                        child: ListView.builder(
                          itemCount: servers.length,
                          itemBuilder: (context, index) {
                            final server = servers[index];
                            return ServerListItem(
                              server: server,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/server/details',
                                  arguments: {'server': server},
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: NavigationBar(
                backgroundColor: Colors.grey[900],
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(context, '/dashboard');
                      break;
                    case 1:
                      Navigator.pushReplacementNamed(context, '/stats');
                      break;
                    case 2:
                      // 현재 화면이므로 무시
                      break;
                    case 3:
                      Navigator.pushReplacementNamed(context, '/alerts');
                      break;
                    case 4:
                      Navigator.pushReplacementNamed(context, '/settings');
                      break;
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '홈',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insert_chart_outlined),
                    selectedIcon: Icon(Icons.insert_chart),
                    label: '통계',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.computer_outlined),
                    selectedIcon: Icon(Icons.computer),
                    label: '서버',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_outlined),
                    selectedIcon: Icon(Icons.notifications),
                    label: '알림',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu),
                    selectedIcon: Icon(Icons.menu),
                    label: '메뉴',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
