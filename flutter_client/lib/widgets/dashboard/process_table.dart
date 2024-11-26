// lib/widgets/dashboard/process_table.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_client/models/process.dart';
import 'package:collection/collection.dart';

class ProcessTable extends StatefulWidget {
  final List<Process> processes;
  final Function(Process)? onKillProcess;
  final Function(Process)? onRestartProcess;
  final Function(List<Process>)? onExportData;

  const ProcessTable({
    super.key,
    required this.processes,
    this.onKillProcess,
    this.onRestartProcess,
    this.onExportData,
  });

  @override
  State<ProcessTable> createState() => _ProcessTableState();
}

class _ProcessTableState extends State<ProcessTable> {
  bool _sortAscending = false;
  int _sortColumnIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Process> _filteredProcesses = [];
  final Set<Process> _selectedProcesses = {};

  @override
  void initState() {
    super.initState();
    _filteredProcesses = widget.processes;
  }

  @override
  void didUpdateWidget(ProcessTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(oldWidget.processes, widget.processes)) {
      _updateFilteredProcesses();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredProcesses() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredProcesses = widget.processes.where((process) {
        return process.name.toLowerCase().contains(searchTerm) ||
            process.user.toLowerCase().contains(searchTerm) ||
            process.pid.toString().contains(searchTerm);
      }).toList();
      _sortProcesses();
    });
  }

  void _sortProcesses() {
    switch (_sortColumnIndex) {
      case 0:
        _filteredProcesses.sort((a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case 1:
        _filteredProcesses.sort((a, b) =>
            _sortAscending ? a.pid.compareTo(b.pid) : b.pid.compareTo(a.pid));
        break;
      case 2:
        _filteredProcesses.sort((a, b) => _sortAscending
            ? a.cpuUsage.compareTo(b.cpuUsage)
            : b.cpuUsage.compareTo(a.cpuUsage));
        break;
      case 3:
        _filteredProcesses.sort((a, b) => _sortAscending
            ? a.memoryUsage.compareTo(b.memoryUsage)
            : b.memoryUsage.compareTo(a.memoryUsage));
        break;
      case 4:
        _filteredProcesses.sort((a, b) => _sortAscending
            ? a.status.compareTo(b.status)
            : b.status.compareTo(a.status));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Processes (${_filteredProcesses.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: SearchBar(
                        controller: _searchController,
                        hintText: 'Search by name, user, or PID...',
                        leading: const Icon(Icons.search),
                        onChanged: (value) {
                          _updateFilteredProcesses();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedProcesses.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () {
                          // Implement batch kill functionality
                          for (final process in _selectedProcesses) {
                            widget.onKillProcess?.call(process);
                          }
                          setState(() => _selectedProcesses.clear());
                        },
                        icon: const Icon(Icons.stop),
                        label: Text('Kill (${_selectedProcesses.length})'),
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More actions',
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'export',
                          enabled: _filteredProcesses.isNotEmpty,
                          child: const Row(
                            children: [
                              Icon(Icons.download),
                              SizedBox(width: 8),
                              Text('Export Data'),
                            ],
                          ),
                          onTap: () =>
                              widget.onExportData?.call(_filteredProcesses),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                cardTheme: const CardTheme(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                ),
              ),
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 16,
                minWidth: 600,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                showCheckboxColumn: true,
                dividerThickness: 1,
                headingRowHeight: 48,
                dataRowHeight: 52,
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest,
                ),
                columns: [
                  DataColumn2(
                    label: const Text('Process Name'),
                    size: ColumnSize.L,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                        _sortProcesses();
                      });
                    },
                  ),
                  DataColumn2(
                    label: const Text('PID'),
                    size: ColumnSize.S,
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                        _sortProcesses();
                      });
                    },
                  ),
                  DataColumn2(
                    label: const Text('CPU (%)'),
                    size: ColumnSize.M,
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                        _sortProcesses();
                      });
                    },
                  ),
                  DataColumn2(
                    label: const Text('Memory'),
                    size: ColumnSize.M,
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                        _sortProcesses();
                      });
                    },
                  ),
                  DataColumn2(
                    label: const Text('Status'),
                    size: ColumnSize.S,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                        _sortProcesses();
                      });
                    },
                  ),
                  const DataColumn2(
                    label: Text('Actions'),
                    size: ColumnSize.S,
                  ),
                ],
                rows: _filteredProcesses.map((process) {
                  final isSelected = _selectedProcesses.contains(process);
                  return DataRow2(
                    selected: isSelected,
                    onSelectChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedProcesses.add(process);
                        } else {
                          _selectedProcesses.remove(process);
                        }
                      });
                    },
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              process.statusIcon,
                              size: 16,
                              color: process.statusColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(process.name),
                                  Text(
                                    process.user,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(process.pid.toString())),
                      DataCell(
                        _CpuUsageIndicator(
                          usage: process.cpuUsage,
                        ),
                      ),
                      DataCell(Text(process.formattedMemoryUsage)),
                      DataCell(
                        _StatusChip(
                          status: process.status,
                          color: process.statusColor,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.stop),
                              onPressed: () =>
                                  widget.onKillProcess?.call(process),
                              tooltip: 'Kill Process',
                            ),
                            IconButton(
                              icon: const Icon(Icons.restart_alt),
                              onPressed: () =>
                                  widget.onRestartProcess?.call(process),
                              tooltip: 'Restart Process',
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      _ProcessDetailsDialog(process: process),
                                );
                              },
                              tooltip: 'Process Details',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CpuUsageIndicator extends StatelessWidget {
  final double usage;

  const _CpuUsageIndicator({required this.usage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Add this at the top of your file
    const kWarningColor = Color(0xFFFFA726); // Orange 400
    // or const kWarningColor = Color(0xFFFFB74D); // Orange 300

    // Then use it in the getUsageColor function:
    Color getUsageColor(double usage) {
      if (usage > 80) {
        return colorScheme.error;
      } else if (usage > 50) {
        return kWarningColor;
      }
      return colorScheme.primary;
    }

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: usage / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(getUsageColor(usage)),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            '${usage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProcessDetailsDialog extends StatelessWidget {
  final Process process;

  const _ProcessDetailsDialog({required this.process});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Process Details: ${process.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('PID', process.pid.toString()),
            _DetailRow('User', process.user),
            _DetailRow('Status', process.status),
            _DetailRow('CPU Usage', '${process.cpuUsage.toStringAsFixed(1)}%'),
            _DetailRow('Memory Usage', process.formattedMemoryUsage),
            _DetailRow('Threads', process.threadCount.toString()),
            _DetailRow('Start Time', process.startTime.toString()),
            _DetailRow('Uptime', process.uptime),
            const Divider(),
            const Text('Command',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                process.command,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
