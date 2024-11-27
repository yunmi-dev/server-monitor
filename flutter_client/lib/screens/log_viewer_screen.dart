// lib/screens/log_viewer_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/models/log_filter.dart';
import 'package:flutter_client/providers/log_provider.dart';
import 'package:flutter_client/widgets/logs/log_filter_chip.dart';
import 'package:flutter_client/widgets/logs/log_entry_card.dart';
import 'package:flutter_client/widgets/logs/log_filter_sheet.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupScrollListener();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogProvider>().loadLogs(
            filter: const LogFilter(
              levels: [LogLevel.error, LogLevel.warning, LogLevel.info],
            ),
          );
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !context.read<LogProvider>().isLoading &&
          context.read<LogProvider>().hasMore) {
        _loadMoreLogs();
      }
    });
  }

  Future<void> _loadMoreLogs() async {
    final provider = context.read<LogProvider>();
    final currentFilter = provider.currentFilter;
    await provider.loadLogs(
      filter: currentFilter.copyWith(
        offset: currentFilter.offset + currentFilter.limit,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<LogProvider>();
    await provider.loadLogs(
      filter: provider.currentFilter.copyWith(offset: 0),
    );
  }

  void _handleSearch(String query) {
    final provider = context.read<LogProvider>();
    provider.updateFilter(
      provider.currentFilter.copyWith(
        search: query.isEmpty ? null : query,
        offset: 0,
      ),
    );
  }

  void _showFilterSheet() async {
    final logProvider = context.read<LogProvider>();
    final currentFilter = logProvider.currentFilter;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LogFilterSheet(
        selectedLevels: currentFilter.levels?.map((e) => e.name).toSet() ??
            LogLevel.values.map((e) => e.name).toSet(),
        startDate: currentFilter.from,
        endDate: currentFilter.to,
        additionalFilters: {
          'component': currentFilter.component,
          'serverId': currentFilter.serverId,
        },
      ),
    );

    if (result != null && mounted) {
      final selectedLevels = (result['levels'] as Set<String>)
          .map((level) => LogLevel.values.firstWhere(
                (e) => e.name == level,
                orElse: () => LogLevel.info,
              ))
          .toList();

      final newFilter = LogFilter(
        levels: selectedLevels,
        from: result['startDate'] as DateTime?,
        to: result['endDate'] as DateTime?,
        component: result['additionalFilters']?['component'] as String?,
        serverId: result['additionalFilters']?['serverId'] as String?,
        limit: currentFilter.limit,
      );

      await logProvider.updateFilter(newFilter);
    }
  }

  Future<void> _showLogDetail(LogEntry log) async {
    final levelColor = log.level.color;

    await showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: const Color(0xFF1E1E1E),
        ),
        child: AlertDialog(
          title: Row(
            children: [
              Icon(log.level.icon, color: levelColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.component,
                  style: TextStyle(color: levelColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '메시지: ${log.message}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '레벨: ${log.level.label}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '시간: ${log.exactTimestamp}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (log.serverId != null)
                  Text(
                    '서버: ${log.serverId}',
                    style: const TextStyle(color: Colors.white),
                  ),
                if (log.stackTrace != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '스택 트레이스:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      log.stackTrace!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '메타데이터:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(log.metadata),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '로그 검색...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
                onChanged: _handleSearch,
              )
            : const Text('로그 뷰어'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                _handleSearch('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<LogProvider>(
        builder: (context, provider, _) {
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              LogFilterBar(
                selectedLevels: provider.currentFilter.levels?.toSet() ??
                    Set.from(LogLevel.values),
                onSelectionChanged: (levels) {
                  provider.updateFilter(
                    provider.currentFilter.copyWith(
                      levels: levels.toList(),
                      offset: 0,
                    ),
                  );
                },
                logCounts: provider.getLevelCounts(),
              ),
              Expanded(
                child: provider.logs.isEmpty && !provider.isLoading
                    ? const Center(
                        child: Text(
                          '로그가 없습니다.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: provider.logs.length +
                              (provider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.logs.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final log = provider.logs[index];
                            return LogEntryCard(
                              log: log,
                              searchQuery: _searchController.text,
                              onTap: () => _showLogDetail(log),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
