// lib/screens/server/servers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/constants/route_paths.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/widgets/server/add_server_modal.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void dispose() {
    super.dispose();
  }

  void _showAddServerModal() {
    // BuildContext context 캡처
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddServerModal(
        onAdd: (name, host, port, username, password, type) async {
          final serverProvider =
              Provider.of<ServerProvider>(context, listen: false);
          try {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('서버 연결 테스트 중...')),
            );

            await serverProvider.testConnection(
              host: host,
              port: port,
              username: username,
              password: password,
            );

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('서버 추가 중...')),
            );

            await serverProvider.addServer(
              name: name,
              host: host,
              port: port,
              username: username,
              password: password,
              type: type,
            );

            navigator.pop();
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('서버가 추가되었습니다.')),
            );
          } catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('서버 추가 실패: $e')),
            );
          }
        },
      ),
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
      selected: _selectedStatus == label,
      label: Text(label),
      onSelected: (bool selected) {
        setState(() {
          _selectedStatus = selected ? label : 'All';
        });
      },
      backgroundColor: Colors.grey[900],
      selectedColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildServerList() {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var filteredServers = provider.servers.where((server) {
          // Apply search filter
          if (_searchQuery.isNotEmpty &&
              !server.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }

          // Apply status filter
          switch (_selectedStatus) {
            case 'Online':
              return server.isOnline;
            case 'Offline':
              return !server.isOnline;
            case 'Warning':
              return server.hasWarnings;
            default:
              return true;
          }
        }).toList();

        if (filteredServers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.computer_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No servers found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredServers.length,
          itemBuilder: (context, index) {
            return _buildServerCard(context, filteredServers[index]);
          },
        );
      },
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
