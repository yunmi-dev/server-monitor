// lib/widgets/server/server_list_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/config/colors.dart';
import 'package:flutter_client/models/resource_usage.dart';

class ServerListItem extends StatefulWidget {
  final Server server;
  final VoidCallback? onTap;

  const ServerListItem({
    super.key,
    required this.server,
    this.onTap,
  });

  @override
  State<ServerListItem> createState() => _ServerListItemState();
}

class _ServerListItemState extends State<ServerListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _resourceAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resourceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatusIndicator(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.server.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Uptime: ${widget.server.uptime}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: AnimatedIcon(
                            icon: AnimatedIcons.menu_close,
                            progress: _resourceAnimation,
                          ),
                          onPressed: _toggleExpand,
                        ),
                      ],
                    ),
                    SizeTransition(
                      sizeFactor: _resourceAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          ServerMetricsRow(resources: widget.server.resources),
                          if (widget.server.status == ServerStatus.warning ||
                              widget.server.status == ServerStatus.critical)
                            _buildWarningBanner(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.server.status.color,
        boxShadow: [
          BoxShadow(
            color: widget.server.status.color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.server.status == ServerStatus.critical
                  ? 'Critical: Immediate attention required'
                  : 'Warning: Performance issues detected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

// ServerListItem 클래스의 _buildActionButtons() 메서드 업데이트
  Widget _buildActionButtons() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 48 : 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.restart_alt,
              label: 'Restart',
              onPressed: () async {
                final context = this.context; // Store context
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final serverProvider =
                    Provider.of<ServerProvider>(context, listen: false);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('서버 재시작'),
                    content: Text('${widget.server.name} 서버를 재시작하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(dialogContext).colorScheme.error,
                        ),
                        child: const Text('재시작'),
                      ),
                    ],
                  ),
                );

                if (!mounted) return;

                if (confirmed == true) {
                  try {
                    await serverProvider.restartServer(widget.server.id);
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('서버 재시작 요청이 전송되었습니다')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('서버 재시작 실패: $e')),
                    );
                  }
                }
              },
            ),
            _ActionButton(
              icon: Icons.terminal,
              label: 'Console',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/server/console',
                  arguments: {'server': widget.server},
                );
              },
            ),
            _ActionButton(
              icon: Icons.visibility,
              label: 'Logs',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/logs',
                  arguments: {'serverId': widget.server.id},
                );
              },
            ),
            _ActionButton(
              icon: Icons.settings,
              label: 'Settings',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/server/settings',
                  arguments: {'server': widget.server},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
}

// lib/widgets/server/server_metrics_row.dart
class ServerMetricsRow extends StatelessWidget {
  final ResourceUsage resources;

  const ServerMetricsRow({
    super.key,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MetricIndicator(
          label: 'CPU',
          value: resources.cpu,
          icon: Icons.memory,
          color: AppColors.cpuColor,
        ),
        _MetricIndicator(
          label: 'Memory',
          value: resources.memory,
          icon: Icons.storage,
          color: AppColors.memoryColor,
        ),
        _MetricIndicator(
          label: 'Disk',
          value: resources.disk,
          icon: Icons.disc_full,
          color: AppColors.diskColor,
        ),
      ],
    );
  }
}

class _MetricIndicator extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _MetricIndicator({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: value / 100,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 4,
              ),
            ),
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
