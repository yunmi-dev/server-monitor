// lib/widgets/common/search_bar.dart
import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class CustomSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final List<String>? filters;
  final bool showFilterButton;
  final TextEditingController? controller;
  final ValueChanged<bool>? onFocusChanged;

  const CustomSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onFilterTap,
    this.filters,
    this.showFilterButton = true,
    this.controller,
    this.onFocusChanged,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    widget.onFocusChanged?.call(_isFocused);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            border: Border.all(
              color: _isFocused
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: AppConstants.spacing),
              Icon(
                Icons.search,
                color: _isFocused
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: AppConstants.spacing / 2),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '검색어를 입력하세요',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: widget.onChanged,
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                ),
              if (widget.showFilterButton)
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    _showFilterBottomSheet(context);
                  },
                ),
            ],
          ),
        ),
        if (widget.filters != null && widget.filters!.isNotEmpty)
          SizeTransition(
            sizeFactor: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacing),
              child: Wrap(
                spacing: AppConstants.spacing / 2,
                runSpacing: AppConstants.spacing / 2,
                children: widget.filters!.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: true,
                    onSelected: (selected) {
                      // Handle filter selection
                    },
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FilterBottomSheet(
              scrollController: scrollController,
              onFilterApplied: (filters) {
                Navigator.pop(context);
                widget.onFilterTap?.call();
              },
            );
          },
        );
      },
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(List<String>) onFilterApplied;

  const FilterBottomSheet({
    super.key,
    required this.scrollController,
    required this.onFilterApplied,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final List<String> _selectedFilters = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacing),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear();
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AppConstants.spacing),
            children: [
              _buildFilterSection(
                'Status',
                ['Online', 'Offline', 'Warning', 'Critical'],
              ),
              _buildFilterSection(
                'Resource Usage',
                ['High CPU', 'High Memory', 'High Disk', 'High Network'],
              ),
              _buildFilterSection(
                'Server Type',
                ['Production', 'Staging', 'Development', 'Testing'],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacing),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppConstants.spacing),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onFilterApplied(_selectedFilters);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<String> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.spacing / 2),
        Wrap(
          spacing: AppConstants.spacing / 2,
          runSpacing: AppConstants.spacing / 2,
          children: filters.map((filter) {
            final isSelected = _selectedFilters.contains(filter);
            return FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFilters.add(filter);
                  } else {
                    _selectedFilters.remove(filter);
                  }
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacing),
      ],
    );
  }
}

// 검색 결과를 보여주는 확장 위젯
class SearchResults extends StatelessWidget {
  final List<SearchResultItem> results;
  final VoidCallback? onClear;

  const SearchResults({
    super.key,
    required this.results,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              '검색 결과가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing,
            vertical: AppConstants.spacing / 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '검색 결과 ${results.length}개',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onClear != null)
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return SearchResultTile(result: result);
            },
          ),
        ),
      ],
    );
  }
}

class SearchResultTile extends StatelessWidget {
  final SearchResultItem result;

  const SearchResultTile({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        result.icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(result.title),
      subtitle: Text(result.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Handle result selection
      },
    );
  }
}

class SearchResultItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
}
