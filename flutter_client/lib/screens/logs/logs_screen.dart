// lib/screens/logs/logs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/widgets/logs/log_filter_sheet.dart';
import 'package:flutter_client/widgets/logs/log_level_badge.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class LogsScreen extends StatefulWidget {
  final String? serverId;

  const LogsScreen({
    super.key,
    this.serverId,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedLogLevels = {'error', 'warning', 'info', 'debug'};

  bool _isLoading = false;
  bool _isSearching = false;
  bool _autoScroll = true;
  bool _hasMore = true;
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _autoScrollTimer;
  Timer? _searchDebouncer;

  List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeLogs();
    _scrollController.addListener(_scrollListener);
    _setupAutoScroll();
    _searchController.addListener(() {
      _searchDebouncer?.cancel();
      _searchDebouncer =
          Timer(const Duration(milliseconds: 500), _initializeLogs);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _autoScrollTimer?.cancel();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _setupAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_autoScroll && mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializeLogs() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final logs = await context.read<ServerProvider>().fetchLogs(
            serverId: widget.serverId,
            levels: _selectedLogLevels.toList(),
            startDate: _startDate,
            endDate: _endDate,
            search: _searchController.text,
            limit: AppConstants.defaultPageSize,
          );

      if (!mounted) return;

      setState(() {
        _logs = logs;
        _hasMore = logs.length >= AppConstants.defaultPageSize;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('로그를 불러오는데 실패했습니다');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final lastLog = _logs.last;
      final moreLogs = await context.read<ServerProvider>().fetchLogs(
            serverId: widget.serverId,
            levels: _selectedLogLevels.toList(),
            startDate: _startDate,
            endDate: _endDate,
            search: _searchController.text,
            limit: AppConstants.defaultPageSize,
            before: lastLog.timestamp,
          );

      if (!mounted) return;

      setState(() {
        _logs.addAll(moreLogs);
        _hasMore = moreLogs.length >= AppConstants.defaultPageSize;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('추가 로그를 불러오는데 실패했습니다');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreLogs();
    }
  }

  Future<void> _handleExport() async {
    try {
      setState(() => _isLoading = true);

      final allLogs = await context.read<ServerProvider>().fetchAllLogs(
            serverId: widget.serverId,
            levels: _selectedLogLevels.toList(),
            startDate: _startDate,
            endDate: _endDate,
            search: _searchController.text,
          );

      final csv = StringBuffer();
      csv.writeln('Timestamp,Level,Source,Message');

      for (final log in allLogs) {
        csv.writeln(
            '${log.timestamp.toIso8601String()},${log.level.name},${log.source},"${log.message.replaceAll('"', '""')}"');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/logs_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv.toString());

      if (!mounted) return;

      await Share.shareFiles(
        [file.path],
        text: '서버 로그 내보내기',
      );
    } catch (e) {
      if (!mounted) return;
      _showError('로그 내보내기에 실패했습니다');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildLogListView(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Text(widget.serverId != null ? '서버 로그' : '시스템 로그'),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () => setState(() => _isSearching = !_isSearching),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilters,
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _handleExport,
        ),
      ],
    );
  }

  Widget _buildLogListView() {
    if (_isLoading && _logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.spacing),
      itemCount: _logs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _logs.length) {
          return _hasMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacing),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox();
        }

        return _buildLogItem(_logs[index]);
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _initializeLogs();
    });
  }

  Future<void> _exportLogs() async {
    try {
      setState(() => _isLoading = true);

      // 모든 로그 데이터 가져오기
      final serverProvider = context.read<ServerProvider>();
      final allLogs = await serverProvider.getAllLogs(
        serverId: widget.serverId,
        levels: _selectedLogLevels.toList(),
        startDate: _startDate,
        endDate: _endDate,
        search: _searchController.text,
      );

      // CSV 형식으로 변환
      final csv = StringBuffer();
      csv.writeln('Timestamp,Level,Source,Message');

      for (final log in allLogs) {
        csv.writeln(
            '${log.timestamp.toIso8601String()},${log.level},${log.source},"${log.message.replaceAll('"', '""')}"');
      }

      // 파일 저장 및 공유
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/logs_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv.toString());

      await Share.shareFiles(
        [file.path],
        text: '서버 로그 내보내기',
      );
    } catch (e) {
      _showError('로그 내보내기에 실패했습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        // 검색 필터 초기화
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() => _autoScroll = !_autoScroll);
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LogFilterSheet(
        selectedLevels: _selectedLogLevels,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLogLevels = result['levels'] as Set<String>;
        _startDate = result['startDate'] as DateTime?;
        _endDate = result['endDate'] as DateTime?;
      });
      _initializeLogs();
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing),
      color: const Color(0xFF1E1E1E),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '검색어를 입력하세요',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.cardBorderRadius / 2),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing,
            vertical: AppConstants.spacing / 2,
          ),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          // 검색 로직 구현
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_startDate != null || _endDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '기간: ${_formatDateRange(_startDate, _endDate)}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                onDeleted: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _initializeLogs();
                },
              ),
            ),
          ..._selectedLogLevels.map((level) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LogLevelBadge(
                  level: level,
                  onDeleted: () {
                    setState(() {
                      _selectedLogLevels.remove(level);
                    });
                    _initializeLogs();
                  },
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget _buildLogList() {
    if (_isLoading && _logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.spacing),
      itemCount: _logs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _logs.length) {
          return _hasMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacing),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox();
        }

        return _buildLogItem(_logs[index]);
      },
    );
  }

  Widget _buildLogItem(LogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        border: Border.all(
          color: _getLogLevelColor(log.level as String).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LogLevelBadge(level: log.level, showDelete: false),
                  const SizedBox(width: AppConstants.spacing),
                  Text(
                    DateUtils.format(log.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    log.source,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacing / 2),
              Text(
                log.message,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_autoScroll)
          FloatingActionButton(
            heroTag: 'pause',
            mini: true,
            onPressed: _toggleAutoScroll,
            child: const Icon(Icons.pause),
          ),
        const SizedBox(height: AppConstants.spacing),
        FloatingActionButton(
          heroTag: 'scroll',
          onPressed: _autoScroll ? null : _toggleAutoScroll,
          child: const Icon(Icons.play_arrow),
        ),
      ],
    );
  }

  void _showLogDetails(LogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConstants.spacing * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                LogLevelBadge(level: log.level, showDelete: false),
                const SizedBox(width: AppConstants.spacing),
                Text(
                  DateUtils.format(log.timestamp),
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing),
            const Text(
              '메시지',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacing / 2),
            Text(
              log.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: AppConstants.spacing),
            const Text(
              '상세 정보',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacing / 2),
            Text(
              '소스: ${log.source}',
              style: const TextStyle(color: Colors.white),
            ),
            // 추가 로그 메타데이터 표시
          ],
        ),
      ),
    );
  }

  Color _getLogLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${DateUtils.format(start)} - ${DateUtils.format(end)}';
    } else if (start != null) {
      return '${DateUtils.format(start)}부터';
    } else if (end != null) {
      return '${DateUtils.format(end)}까지';
    }
    return '';
  }
}
