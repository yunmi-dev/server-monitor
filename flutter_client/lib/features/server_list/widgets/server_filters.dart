// lib/features/server_list/widgets/server_filters.dart

import 'package:flutter/material.dart';

class ServerFilters extends StatelessWidget {
  final Function(Map<String, bool>) onFilterChanged;

  const ServerFilters({
    Key? key,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: true,
            onSelected: (selected) {
              // TODO: Implement filter logic
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Production'),
            selected: false,
            onSelected: (selected) {
              // TODO: Implement filter logic
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Development'),
            selected: false,
            onSelected: (selected) {
              // TODO: Implement filter logic
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Staging'),
            selected: false,
            onSelected: (selected) {
              // TODO: Implement filter logic
            },
          ),
        ],
      ),
    );
  }
}
