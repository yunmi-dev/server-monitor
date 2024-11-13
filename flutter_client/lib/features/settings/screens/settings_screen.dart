// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              ListTile(
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  selected: {themeProvider.themeMode},
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.smartphone),
                    ),
                  ],
                  onSelectionChanged: (Set<ThemeMode> modes) {
                    themeProvider.setThemeMode(modes.first);
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive alerts about server status'),
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
              ),
              SwitchListTile(
                title: const Text('Critical Alerts Only'),
                subtitle: const Text('Only notify for critical issues'),
                value: settings.criticalAlertsOnly,
                onChanged: settings.notificationsEnabled
                    ? settings.setCriticalAlertsOnly
                    : null,
              ),
            ],
          ),
          _buildSection(
            title: 'Data & Sync',
            children: [
              ListTile(
                title: const Text('Refresh Interval'),
                subtitle: Text('${settings.refreshInterval} seconds'),
                trailing: DropdownButton<int>(
                  value: settings.refreshInterval,
                  items: [15, 30, 60, 120].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value sec'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      settings.setRefreshInterval(value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Clear stored data and preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),
          _buildSection(
            title: 'Account',
            children: [
              ListTile(
                title: const Text('Sign Out'),
                textColor: Colors.red,
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                onTap: () => _showSignOutDialog(context),
              ),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0 (Beta)'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BETA',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const ListTile(
                title: Text('Terms of Service'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                title: Text('Privacy Policy'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out? You\'ll need to sign in again to access your account.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
            onPressed: () {
              // TODO: Implement sign out
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will clear all locally stored data and preferences. The app will restart afterwards. Continue?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('Clear'),
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
