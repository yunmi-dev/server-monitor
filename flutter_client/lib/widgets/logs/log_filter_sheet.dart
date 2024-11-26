// lib/widgets/logs/log_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/utils/date_utils.dart';

class LogFilterSheet extends StatefulWidget {
  final Set<String> selectedLevels;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? additionalFilters;

  const LogFilterSheet({
    super.key,
    required this.selectedLevels,
    this.startDate,
    this.endDate,
    this.additionalFilters,
  });

  @override
  State<LogFilterSheet> createState() => _LogFilterSheetState();
}

class _LogFilterSheetState extends State<LogFilterSheet> {
  late Set<String> _selectedLevels;
  DateTime? _startDate;
  DateTime? _endDate;
  final Map<String, dynamic> _additionalFilters = {};

  final List<String> _availableLevels = ['error', 'warning', 'info', 'debug'];
  final Map<String, String> _presetRanges = {
    '1시간': '1h',
    '6시간': '6h',
    '12시간': '12h',
    '1일': '1d',
    '7일': '7d',
    '30일': '30d',
  };

  @override
  void initState() {
    super.initState();
    _selectedLevels = Set.from(widget.selectedLevels);
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    if (widget.additionalFilters != null) {
      _additionalFilters.addAll(widget.additionalFilters!);
    }
  }

  void _applyPresetRange(String preset) {
    final now = DateTime.now();
    switch (preset) {
      case '1h':
        _startDate = now.subtract(const Duration(hours: 1));
        break;
      case '6h':
        _startDate = now.subtract(const Duration(hours: 6));
        break;
      case '12h':
        _startDate = now.subtract(const Duration(hours: 12));
        break;
      case '1d':
        _startDate = now.subtract(const Duration(days: 1));
        break;
      case '7d':
        _startDate = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        _startDate = now.subtract(const Duration(days: 30));
        break;
    }
    _endDate = now;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '로그 필터',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('초기화'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing * 2),
                  _buildLogLevels(),
                  const SizedBox(height: AppConstants.spacing * 2),
                  _buildDateFilter(),
                  const SizedBox(height: AppConstants.spacing * 2),
                  _buildPresetRanges(),
                  const SizedBox(height: AppConstants.spacing * 2),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildLogLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '로그 레벨',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLevels.map((level) {
            final isSelected = _selectedLevels.contains(level);
            return FilterChip(
              label: Text(
                level.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLevels.add(level);
                  } else {
                    _selectedLevels.remove(level);
                  }
                });
              },
              backgroundColor: Colors.transparent,
              selectedColor: Colors.white.withOpacity(0.1),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius / 2),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기간',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacing),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                '시작일',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~', style: TextStyle(color: Colors.white)),
            ),
            Expanded(
              child: _buildDateButton(
                '종료일',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: Theme.of(context).colorScheme.primary,
                      onPrimary: Colors.white,
                      surface: const Color(0xFF1E1E1E),
                      onSurface: Colors.white,
                    ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius:
              BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        ),
        child: Text(
          value != null ? DateTimeUtils.formatDate(value) : label,
          style: TextStyle(
            color: value != null ? Colors.white : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPresetRanges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 선택',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetRanges.entries.map((entry) {
            return ActionChip(
              label: Text(
                entry.key,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              onPressed: () => _applyPresetRange(entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedLevels.clear();
      _startDate = null;
      _endDate = null;
      _additionalFilters.clear();
    });
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        const SizedBox(width: AppConstants.spacing),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'levels': _selectedLevels,
              'startDate': _startDate,
              'endDate': _endDate,
              if (_additionalFilters.isNotEmpty)
                'additionalFilters': _additionalFilters,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('적용'),
        ),
      ],
    );
  }
}
