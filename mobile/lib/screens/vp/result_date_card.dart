// lib/screens/vp/result_date_card.dart
// The "Result Date" card at the top of the Principal / VP dashboard.
// Shows the date (or "Not set yet") and the days left. Only the VP can change it:
// "Set / Change Result Date" opens a calendar; "Clear" removes the date.
// Teachers get automatic reminders 7 days before, daily from 6 to 3 days, and URGENT from 2 days.

import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';

class ResultDateCard extends StatefulWidget {
  const ResultDateCard({super.key});

  @override
  State<ResultDateCard> createState() => _ResultDateCardState();
}

class _ResultDateCardState extends State<ResultDateCard> {
  late Future<ResultDateInfo> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = dataService.getResultDate();
  }

  Future<void> _save(DateTime? day) async {
    setState(() => _saving = true);
    try {
      final info = await dataService.setResultDate(day);
      if (!mounted) return;
      setState(() => _future = Future.value(info));
      showMessage(
          context,
          day == null
              ? 'Result Date cleared.'
              : 'Result Date set to ${formatDay(day)} (${daysLeftText(info.daysRemaining)}).');
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pick(ResultDateInfo info) async {
    final today = info.today; // the school's "today" from the server
    final current = info.resultDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: (current != null && !current.isBefore(today)) ? current : today.add(const Duration(days: 7)),
      firstDate: today, // a past date is not allowed
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Pick the Result Date',
      confirmText: 'Set date',
    );
    if (picked != null) await _save(picked);
  }

  Future<void> _clear() async {
    final ok = await confirmDialog(
      context,
      title: 'Clear the Result Date?',
      message: 'Teachers will stop getting automatic Result Date reminders until a new date is set.',
      confirmText: 'Clear',
      isDanger: true,
    );
    if (ok) await _save(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResultDateInfo>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
              child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: AppColors.danger),
              title: const Text('Result Date could not be loaded'),
              subtitle: Text(errorText(snapshot.error!)),
              trailing: IconButton(
                tooltip: 'Retry',
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _future = dataService.getResultDate()),
              ),
            ),
          );
        }
        final info = snapshot.data!;
        final days = info.daysRemaining;
        final urgent = days != null && days >= 0 && days <= 2;
        final color = urgent ? AppColors.danger : AppColors.primary;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, color: color),
                    const SizedBox(width: 8),
                    const Text('Result Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (info.isSet)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(daysLeftText(days),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(info.isSet ? formatDay(info.resultDate!) : 'Not set yet',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: info.isSet ? color : AppColors.muted)),
                const SizedBox(height: 4),
                Text(
                  info.isSet
                      ? 'Teachers with pending marks get reminders 7 days before, '
                          'every day from 6 days, and an URGENT alert from 2 days before.'
                      : 'Set the day results are announced. Teachers with pending marks '
                          'will then get automatic reminders.',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _pick(info),
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: const Text('Set / Change Result Date'),
                      ),
                    ),
                    if (info.isSet) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _saving ? null : _clear,
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
