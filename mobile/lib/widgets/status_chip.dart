// lib/widgets/status_chip.dart
// Coloured little labels: Not uploaded / In progress / Submitted,
// and Pending / Ready to publish / Published for a whole class.

import 'package:flutter/material.dart';

import '../models/submission_state.dart';
import 'app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({super.key, required this.label, required this.color, this.icon});

  // For one subject of one class
  factory StatusChip.submission(SubmissionState state,
      {int entered = 0, int total = 0}) {
    switch (state) {
      case SubmissionState.submitted:
        return const StatusChip(
            label: 'Submitted', color: AppColors.success, icon: Icons.check_circle);
      case SubmissionState.inProgress:
        return StatusChip(
            // everyone has marks but the teacher has not pressed Submit yet
            label: entered == total && total > 0
                ? 'Awaiting submit'
                : 'In progress $entered/$total',
            color: AppColors.warning,
            icon: Icons.timelapse);
      case SubmissionState.notUploaded:
        return const StatusChip(
            label: 'Not uploaded', color: AppColors.danger, icon: Icons.cancel);
    }
  }

  // For a whole class: "Published", "Ready to publish", "Pending"
  factory StatusChip.classStatus(String statusLabel) {
    switch (statusLabel) {
      case 'Published':
        return const StatusChip(label: 'Published', color: AppColors.success, icon: Icons.lock);
      case 'Ready to publish':
        return const StatusChip(
            label: 'Ready to publish', color: AppColors.primary, icon: Icons.task_alt);
      default:
        return const StatusChip(label: 'Pending', color: AppColors.warning, icon: Icons.hourglass_bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
