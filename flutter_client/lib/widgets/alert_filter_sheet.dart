// lib/widgets/alert_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/alert_provider.dart';

class AlertFilterSheet extends StatefulWidget {
  const AlertFilterSheet({super.key});

  @override
  State<AlertFilterSheet> createState() => _AlertFilterSheetState();
}

class _AlertFilterSheetState extends State<AlertFilterSheet> {
  final _categories = ['System', 'Security', 'Performance', 'Network'];
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _selectedCategories =
        Provider.of<AlertProvider>(context, listen: false).selectedCategories;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Alerts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedCategories.clear());
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _categories.map((category) {
              return FilterChip(
                label: Text(category),
                selected: _selectedCategories.contains(category),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final provider =
                    Provider.of<AlertProvider>(context, listen: false);
                provider.setCategories(_selectedCategories);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
