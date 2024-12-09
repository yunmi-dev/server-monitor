// lib/widgets/common/confirm_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String confirmText;
  final bool isDestructive;
  final VoidCallback? onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText,
    required this.confirmText,
    this.isDestructive = false,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDestructive)
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 48,
              ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelText ?? '취소',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: AppConstants.spacing),
                ElevatedButton(
                  onPressed: () {
                    onConfirm?.call();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardBorderRadius / 2,
                      ),
                    ),
                  ),
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 사용 예시:
void showDeleteConfirmation(BuildContext context) {
  showDialog<bool>(
    context: context,
    builder: (context) => const ConfirmDialog(
      title: '삭제 확인',
      content: '정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
    ),
  );
}
