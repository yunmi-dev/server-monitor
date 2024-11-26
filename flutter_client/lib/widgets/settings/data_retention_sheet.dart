// lib/widgets/settings/data_retention_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/settings_provider.dart';

class DataRetentionSheet extends StatelessWidget {
  const DataRetentionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final retentionOptions = [7, 14, 30, 60, 90, 180, 365];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Retention Period',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: retentionOptions.length,
              itemBuilder: (context, index) {
                final days = retentionOptions[index];
                return ListTile(
                  title: Text('$days days'),
                  onTap: () {
                    context.read<SettingsProvider>().setDataRetentionDays(days);
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
