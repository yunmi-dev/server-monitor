// lib/screens/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/alert_provider.dart';
import 'package:flutter_client/widgets/alert_filter_sheet.dart';
import 'package:flutter_client/widgets/alert_list_item.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<String> _selectedAlerts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          if (_selectedAlerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark as Read',
              onPressed: () {
                // Mark selected alerts as read
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Alerts',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const AlertFilterSheet(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All systems are running normally',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.alerts.length,
            itemBuilder: (context, index) {
              final alert = provider.alerts[index];
              return Dismissible(
                key: Key(alert.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Alert'),
                      content: const Text(
                          'Are you sure you want to delete this alert?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  provider.deleteAlert(alert.id);
                },
                child: AlertListItem(
                  alert: alert,
                  isSelected: _selectedAlerts.contains(alert.id),
                  onSelect: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAlerts.add(alert.id);
                      } else {
                        _selectedAlerts.remove(alert.id);
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
