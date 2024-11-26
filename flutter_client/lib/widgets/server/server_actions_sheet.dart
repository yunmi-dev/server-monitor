// lib/widgets/server/server_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/server.dart';

class ServerActionsSheet extends StatelessWidget {
  final Server server;

  const ServerActionsSheet({
    super.key,
    required this.server,
    required String serverId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.white),
            title: const Text(
              'Restart Server',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // Implement restart logic
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.white),
            title: const Text(
              'View Logs',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/server-logs',
                  arguments: server.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              'Server Settings',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/server-settings',
                arguments: server.id,
              );
            },
          ),
        ],
      ),
    );
  }
}
