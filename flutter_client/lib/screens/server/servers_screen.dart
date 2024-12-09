// lib/screens/server/servers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/constants/route_paths.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/widgets/server/add_server_modal.dart';
import 'package:flutter_client/widgets/server/server_list_item.dart';
import 'package:flutter_client/widgets/charts/common/empty_state_widget.dart';
import 'package:flutter_client/services/storage_service.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  String _searchQuery = '';
  ServerStatus? _selectedStatus;
  ServerType? _selectedOsType;
  ServerCategory? _selectedCategory;
  bool? _hasWarnings;
  String? _selectedFilter = 'All';

  void _showAddServerModal() async {
    final storage = await StorageService.initialize();
    if (await storage.getToken() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      // 로그인 화면으로 이동
      Navigator.pushNamed(context, RoutePaths.login);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddServerModal(
        onAdd: (name, host, port, username, password, type, category) async {
          final serverProvider =
              Provider.of<ServerProvider>(context, listen: false);
          try {
            await serverProvider.testConnection(
              host: host,
              port: port,
              username: username,
              password: password,
            );

            await serverProvider.addServer(
              name: name,
              host: host,
              port: port,
              username: username,
              password: password,
              type: type,
              category: category,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('서버가 추가되었습니다')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('서버 추가 실패: $e')),
            );
          }
        },
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          _buildStatusFilterChip(ServerStatus.online, '온라인'),
          _buildStatusFilterChip(ServerStatus.offline, '오프라인'),
          FilterChip(
            selected: _hasWarnings == true,
            label: const Text('경고'),
            onSelected: (selected) =>
                setState(() => _hasWarnings = selected ? true : null),
          ),
          PopupMenuButton<ServerType>(
            child: Chip(label: Text(_selectedOsType?.displayName ?? '운영체제')),
            itemBuilder: (_) => AppConstants.serverTypeItems
                .map((item) =>
                    PopupMenuItem(value: item.value, child: item.child))
                .toList(),
            onSelected: (type) => setState(() => _selectedOsType = type),
          ),
          PopupMenuButton<ServerCategory>(
            child: Chip(label: Text(_selectedCategory?.displayName ?? '서버 유형')),
            itemBuilder: (_) => AppConstants.serverCategoryItems
                .map((item) =>
                    PopupMenuItem(value: item.value, child: item.child))
                .toList(),
            onSelected: (category) =>
                setState(() => _selectedCategory = category),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(ServerStatus status, String label) {
    return FilterChip(
      selected: _selectedStatus == status,
      label: Text(label),
      onSelected: (selected) =>
          setState(() => _selectedStatus = selected ? status : null),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToServerDetails(Server server) {
    Navigator.pushNamed(
      context,
      RoutePaths.serverDetails,
      arguments: {'server': server},
    );
  }

  Widget _buildServerList() {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredServers = provider.filterServers(
          searchQuery: _searchQuery,
          status: _selectedStatus,
          type: _selectedOsType,
          hasWarnings: _hasWarnings,
        );

        if (filteredServers.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.dns_outlined,
            message: '서버를 찾을 수 없습니다',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredServers.length,
          itemBuilder: (context, index) => ServerListItem(
            server: filteredServers[index],
            onTap: () => _navigateToServerDetails(filteredServers[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ServerProvider>().refreshAll();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddServerModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 키보드가 올라올 때의 패딩 조정
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterChips(),
                ],
              ),
            ),
            Expanded(
              child: _buildServerList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // top 패딩 제거
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search servers...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Online'),
          const SizedBox(width: 8),
          _buildFilterChip('Offline'),
          const SizedBox(width: 8),
          _buildFilterChip('Warning'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      selected: _selectedFilter == label,
      label: Text(label),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : 'All';

          // 필터에 따른 ServerStatus 설정
          switch (_selectedFilter) {
            case 'Online':
              _selectedStatus = ServerStatus.online;
              break;
            case 'Offline':
              _selectedStatus = ServerStatus.offline;
              break;
            case 'Warning':
              _selectedStatus = ServerStatus.warning;
              break;
            default:
              _selectedStatus = null;
          }
        });
      },
      backgroundColor: Colors.grey[900],
      selectedColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildServerCard(BuildContext context, Server server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RoutePaths.serverDetails,
            arguments: {'server': server},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: server.isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      server.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (server.hasWarnings)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildResourceIndicator(
                      'CPU',
                      server.resources.cpu,
                      AppConstants.criticalThreshold,
                      AppConstants.warningThreshold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildResourceIndicator(
                      'Memory',
                      server.resources.memory,
                      AppConstants.criticalThreshold,
                      AppConstants.warningThreshold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceIndicator(
    String label,
    double value,
    double criticalThreshold,
    double warningThreshold,
  ) {
    Color getColor() {
      if (value >= criticalThreshold) return Colors.red;
      if (value >= warningThreshold) return Colors.orange;
      return Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: getColor(),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[900],
            valueColor: AlwaysStoppedAnimation<Color>(getColor()),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
