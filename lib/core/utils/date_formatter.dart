import 'package:intl/intl.dart';

import 'package:nextcloud_deck/l10n/app_localizations.dart';

abstract final class DateFormatter {
  static final _dateFmt = DateFormat('MMM d, y');
  static final _dateTimeFmt = DateFormat('MMM d, y · h:mm a');
  static final _timeFmt = DateFormat('h:mm a');
  static final _logFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String formatDate(DateTime dt) => _dateFmt.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFmt.format(dt);
  static String formatTime(DateTime dt) => _timeFmt.format(dt);
  static String formatLog(DateTime dt) => _logFmt.format(dt.toLocal());

  /// Returns a human-friendly relative due-date string, fully localised.
  ///
  /// Requires [l10n] so the strings can be translated. Call this from a
  /// widget that already holds a BuildContext.
  static String formatDue(DateTime due, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;

    if (diff < 0) return '${l10n.cardOverdue} · ${_dateFmt.format(due)}';
    if (diff == 0) return l10n.cardDueToday;
    if (diff == 1) return l10n.dueTomorrow;
    if (diff < 7) return l10n.dueInDays(diff);
    return '${l10n.dueOn} ${_dateFmt.format(due)}';
  }

  static String formatEpoch(int epochSeconds) =>
      formatDateTime(DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000));

  /// Formats an epoch-millis timestamp for sync logs.
  static String formatLogMillis(int epochMillis) =>
      formatLog(DateTime.fromMillisecondsSinceEpoch(epochMillis));
}
