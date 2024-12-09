// lib/screens/server_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/widgets/server/server_list_item.dart';
import 'package:flutter_client/widgets/charts/common/search_bar.dart';
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
  int _selectedIndex = 2;
  //bool _showBottomBar = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterServers(List<Server> servers, String query) {
    setState(() {});
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
                SliverFillRemaining(child: Consumer<ServerProvider>(
                  builder: (context, provider, child) {
                    debugPrint(
                        'Consumer 호출됨: isLoading=${provider.isLoading}, servers=${provider.servers.length}');

                    if (provider.servers.isEmpty) {
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
                              '서버가 없습니다\n새로운 서버를 추가해보세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    // 검색어가 있을 때만 필터링
                    final servers = _searchController.text.isNotEmpty
                        ? provider.servers
                            .where((server) => server.name
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase()))
                            .toList()
                        : provider.servers;

                    return ListView.builder(
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        return ServerListItem(
                          server: servers[index],
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/server/details',
                            arguments: {'server': servers[index]},
                          ),
                        );
                      },
                    );
                  },
                )),
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
