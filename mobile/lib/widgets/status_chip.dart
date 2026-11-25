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

  // For one subject of one class, as the SUBJECT TEACHER sees it (plain words, no "draft")
  factory StatusChip.submission(SubmissionState state,
      {int entered = 0, int total = 0}) {
    switch (state) {
      case SubmissionState.submitted:
        return const StatusChip(
            label: 'Final Submitted', color: AppColors.success, icon: Icons.lock);
      case SubmissionState.inProgress:
        return const StatusChip(
            label: 'Saved — Not Submitted Yet',
            color: AppColors.warning,
            icon: Icons.save_outlined);
      case SubmissionState.notUploaded:
        return const StatusChip(
            label: 'Not started', color: AppColors.danger, icon: Icons.radio_button_unchecked);
    }
  }

  // The same subject as the CLASS TEACHER sees it: simply Submitted or Pending
  factory StatusChip.classTeacherView(SubmissionState state) {
    if (state == SubmissionState.submitted) {
      return const StatusChip(
          label: 'Submitted', color: AppColors.success, icon: Icons.check_circle);
    }
    return StatusChip(
        label: 'Pending',
        color: state == SubmissionState.notUploaded ? AppColors.danger : AppColors.warning,
        icon: Icons.hourglass_bottom);
  }

  // One student's result card: Ready or Waiting
  factory StatusChip.cardReady(bool isReady) => isReady
      ? const StatusChip(label: 'Ready', color: AppColors.success, icon: Icons.check_circle)
      : const StatusChip(label: 'Waiting', color: AppColors.warning, icon: Icons.schedule);

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
