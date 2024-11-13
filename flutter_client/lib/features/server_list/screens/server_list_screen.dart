// lib/features/server_list/screens/server_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../server_list_provider.dart';
import '../widgets/server_list_item.dart';
import '../widgets/server_filters.dart';
import '../../../shared/models/server.dart';
import '../widgets/add_server_dialog.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({Key? key}) : super(key: key);

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ServerListProvider>().initialize());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Servers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddServerDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search servers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ServerListProvider>().setSearchQuery('');
                  },
                ),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<ServerListProvider>().setSearchQuery(value);
              },
            ),
          ),
          ServerFilters(
            onFilterChanged: (filters) {
              context.read<ServerListProvider>().updateFilters(filters);
            },
          ),
          Expanded(
            child: Consumer<ServerListProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.initialize(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final servers = provider.filteredServers;
                if (servers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No servers found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.initialize(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ServerListItem(
                          server: server,
                          onTap: () => _showServerDetails(context, server),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // void _showAddServerDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Add New Server'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextField(
  //             decoration: const InputDecoration(
  //               labelText: 'Server Name',
  //               hintText: 'Enter server name',
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             decoration: const InputDecoration(
  //               labelText: 'Location',
  //               hintText: 'Enter server location',
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           DropdownButtonFormField<String>(
  //             decoration: const InputDecoration(
  //               labelText: 'Type',
  //             ),
  //             items: const [
  //               DropdownMenuItem(
  //                   value: 'Production', child: Text('Production')),
  //               DropdownMenuItem(
  //                   value: 'Development', child: Text('Development')),
  //               DropdownMenuItem(value: 'Staging', child: Text('Staging')),
  //             ],
  //             onChanged: (value) {},
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             // TODO: Implement server addition
  //             Navigator.pop(context);
  //           },
  //           child: const Text('Add'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showAddServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddServerDialog(), // 여기만 수정
    ).then((result) {
      if (result != null) {
        // TODO: 서버 추가 로직 구현
        print('New server details: $result');
        // context.read<ServerListProvider>().addServer(result);
      }
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SizedBox(
        height: 300,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Servers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              // TODO: Implement filter options
            ],
          ),
        ),
      ),
    );
  }

  void _showServerDetails(BuildContext context, Server server) {
    // TODO: Navigate to server details screen
  }
}

class _ServerListItem extends StatelessWidget {
  final Server server;

  const _ServerListItem({
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.circle,
          size: 12,
          color: server.isOnline ? Colors.green : Colors.red,
        ),
        title: Text(
          server.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${server.type} • ${server.location}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show server actions menu
          },
        ),
      ),
    );
  }
}
