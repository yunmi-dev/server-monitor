// lib/widgets/settings/timezone_selection_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/settings_provider.dart';

class TimeZoneSelectionSheet extends StatelessWidget {
  const TimeZoneSelectionSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timezones = [
      'UTC',
      'UTC+1',
      'UTC+2',
      'UTC+3',
      'UTC+4',
      'UTC+5',
      'UTC+6',
      'UTC+7',
      'UTC+8',
      'UTC+9',
      'UTC+10',
      'UTC+11',
      'UTC+12',
      'UTC-1',
      'UTC-2',
      'UTC-3',
      'UTC-4',
      'UTC-5',
      'UTC-6',
      'UTC-7',
      'UTC-8',
      'UTC-9',
      'UTC-10',
      'UTC-11',
      'UTC-12',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time Zone',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: timezones.length,
              itemBuilder: (context, index) {
                final timezone = timezones[index];
                return ListTile(
                  title: Text(timezone),
                  onTap: () {
                    context.read<SettingsProvider>().setTimeZone(timezone);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
