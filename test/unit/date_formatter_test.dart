// ignore_for_file: avoid_implementing_value_types
import 'package:flutter_test/flutter_test.dart';

import 'package:nextcloud_deck/core/utils/date_formatter.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';

// Stub AppLocalizations
//
// AppLocalizations is generated as an abstract class, so we can extend it
// directly - no BuildContext, no testWidgets, no mocking package required.
// Every member returns the canonical English string from app_en.arb so the
// tests read naturally and match production output.
class _FakeL10n extends AppLocalizations {
  _FakeL10n() : super('en');

  // DateFormatter-relevant strings
  @override
  String get cardOverdue => 'Overdue';
  @override
  String get cardDueToday => 'Due today';
  @override
  String get dueTomorrow => 'Due tomorrow';
  @override
  String get dueOn => 'Due';
  @override
  String dueInDays(int days) => 'Due in $days days';

  // Everything else (unused by DateFormatter but required by the abstract)
  @override
  String get appTitle => 'Nextcloud Deck';
  @override
  String get appBuiltBy => '';
  @override
  String get onboardingTitle1 => '';
  @override
  String get onboardingBody1 => '';
  @override
  String get onboardingTitle2 => '';
  @override
  String get onboardingBody2 => '';
  @override
  String get onboardingTitle3 => '';
  @override
  String get onboardingBody3 => '';
  @override
  String get onboardingSkip => '';
  @override
  String get onboardingNext => '';
  @override
  String get onboardingGetStarted => '';
  @override
  String get loginTitle => '';
  @override
  String get loginSubtitle => '';
  @override
  String get loginUrlLabel => '';
  @override
  String get loginServerUrlHint => '';
  @override
  String get loginUrlValidationEmpty => '';
  @override
  String get loginUrlValidationScheme => '';
  @override
  String get loginConnect => '';
  @override
  String get loginConnecting => '';
  @override
  String get loginWaitingForAuth => '';
  @override
  String get loginApproveInfo => '';
  @override
  String get loginWebViewTitle => '';
  @override
  String get loginPollingTitle => '';
  @override
  String get loginCancelledByUser => '';
  @override
  String get loginErrorGeneric => '';
  @override
  String get loginPollingTimeout => '';
  @override
  String get logoutConfirmTitle => '';
  @override
  String get logoutConfirmBody => '';
  @override
  String get logoutConfirm => '';
  @override
  String get cancel => '';
  @override
  String get boardsTitle => '';
  @override
  String get boardsEmptyTitle => '';
  @override
  String get boardsEmptyBody => '';
  @override
  String get boardCreate => '';
  @override
  String get boardTitleLabel => '';
  @override
  String get boardColorLabel => '';
  @override
  String get boardEdit => '';
  @override
  String get boardDelete => '';
  @override
  String get boardArchive => '';
  @override
  String get boardUnarchive => '';
  @override
  String get boardContextMenu => '';
  @override
  String get stackCreate => '';
  @override
  String get stackTitleLabel => '';
  @override
  String get stackRename => '';
  @override
  String get stackDelete => '';
  @override
  String get stackEmpty => '';
  @override
  String get cardCreate => '';
  @override
  String get cardTitleLabel => '';
  @override
  String get cardDescriptionLabel => '';
  @override
  String get cardDescriptionHint => '';
  @override
  String get cardDueDateLabel => '';
  @override
  String get cardNoDueDate => '';
  @override
  String get cardLabelsLabel => '';
  @override
  String get cardAssigneesLabel => '';
  @override
  String get cardDetailsLabel => '';
  @override
  String get cardCreatedLabel => '';
  @override
  String get cardOwnerLabel => '';
  @override
  String get cardHasDescription => '';
  @override
  String get cardNoDescription => '';
  @override
  String get cardMove => '';
  @override
  String get cardEdit => '';
  @override
  String get cardDelete => '';
  @override
  String get cardSave => '';
  @override
  String get cardViewEdit => '';
  @override
  String get moveCardTitle => '';
  @override
  String get searchHint => '';
  @override
  String get searchPrompt => '';
  @override
  String get searchNoResults => '';
  @override
  String get filterTitle => '';
  @override
  String get filterAssignedToMe => '';
  @override
  String get filterOverdue => '';
  @override
  String get filterHasDueDate => '';
  @override
  String get filterByLabel => '';
  @override
  String get filterClear => '';
  @override
  String get filterApply => '';
  @override
  String get sortSectionTitle => '';
  @override
  String get sortOrder => '';
  @override
  String get sortDueDate => '';
  @override
  String get sortCreatedDate => '';
  @override
  String get sortAlphabetical => '';
  @override
  String get settingsTitle => '';
  @override
  String get settingsAccountSection => '';
  @override
  String get settingsSyncSection => '';
  @override
  String get settingsPreferencesSection => '';
  @override
  String get settingsAboutSection => '';
  @override
  String get settingsSyncNow => '';
  @override
  String get settingsSyncing => '';
  @override
  String get settingsSyncSuccess => '';
  @override
  String get settingsSyncFailed => '';
  @override
  String get settingsViewSyncLogs => '';
  @override
  String get settingsConflicts => '';
  @override
  String get settingsClearCache => '';
  @override
  String get settingsClearCacheTitle => '';
  @override
  String get settingsClearCacheConfirm => '';
  @override
  String get settingsClearCacheConfirmButton => '';
  @override
  String get settingsClearCacheSuccess => '';
  @override
  String get settingsConflictResolution => '';
  @override
  String get settingsConflictResolutionTitle => '';
  @override
  String get settingsConflictAsk => '';
  @override
  String get settingsConflictKeepLocal => '';
  @override
  String get settingsConflictKeepServer => '';
  @override
  String get settingsShowIntro => '';
  @override
  String get settingsLogout => '';
  @override
  String get settingsApiVersion => '';
  @override
  String get settingsServerVersion => '';
  @override
  String get settingsAppVersion => '';
  @override
  String get syncLogsTitle => '';
  @override
  String get syncLogsEmpty => '';
  @override
  String get syncLogsClear => '';
  @override
  String get syncLogOpCreated => '';
  @override
  String get syncLogOpUpdated => '';
  @override
  String get syncLogOpDeleted => '';
  @override
  String get conflictsTitle => '';
  @override
  String get conflictsEmpty => '';
  @override
  String get conflictLocalVersion => '';
  @override
  String get conflictServerVersion => '';
  @override
  String get conflictKeepLocal => '';
  @override
  String get conflictKeepServer => '';
  @override
  String get conflictResolvedLocal => '';
  @override
  String get conflictResolvedServer => '';
  @override
  String get conflictSnackbar => '';
  @override
  String get conflictSnackbarAction => '';
  @override
  String get syncLogOpConflictResolved => '';
  @override
  String get offlineBanner => '';
  @override
  String get unableToLoadUpdates => '';
  @override
  String get unableToLoadBoard => '';
  @override
  String get accountSectionServer => '';
  @override
  String get accountSectionApp => '';
  @override
  String get accountServerUrl => '';
  @override
  String get splashTagline => '';
  @override
  String get splashPoweredBy => '';
  @override
  String get loginFailed => '';
  @override
  String get retry => '';
  @override
  String get loading => '';
  @override
  String get error => '';
  @override
  String get delete => '';
  @override
  String get rename => '';
  @override
  String get save => '';
  @override
  String get edit => '';
  @override
  String get create => '';
  @override
  String get close => '';
  @override
  String get ok => '';
  @override
  String get yes => '';
  @override
  String get no => '';
  @override
  String get unknownError => '';
  @override
  String get noInternetShort => '';
  @override
  String get emptyValue => '';
  @override
  String get unknownValue => '';

  // Parametrised methods (unused by DateFormatter)
  @override
  String boardsArchivedSection(int count) => '';
  @override
  String boardDeleteConfirm(String title) => '';
  @override
  String stackDeleteConfirm(String title) => '';
  @override
  String stackCardCount(int count) => '';
  @override
  String cardDeleteConfirm(String title) => '';
  @override
  String moveCardSubtitle(String title) => '';
  @override
  String moveCardCount(int count) => '';
  @override
  String conflictEntityLabel(String type, int id) => '';
  @override
  String conflictDetectedAt(String when) => '';
  @override
  String offlineBannerQueued(int count) => '';
}

// Singleton so every test shares one instance - cheap and stateless.
final _l10n = _FakeL10n();

// Helpers
/// Returns today's midnight, which is the boundary DateFormatter uses.
DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime _daysFromNow(int days) => _today().add(Duration(days: days));

String _formatDue(DateTime dt) => DateFormatter.formatDue(dt, _l10n);

// Tests
void main() {
  // formatDue
  group('DateFormatter.formatDue', () {
    group('today boundary', () {
      test('midnight today → "Due today"', () {
        expect(_formatDue(_today()), 'Due today');
      });

      test('noon today → "Due today"', () {
        final noon = _today().add(const Duration(hours: 12));
        expect(_formatDue(noon), 'Due today');
      });

      test('one second before midnight today → "Due today"', () {
        final almostTomorrow = _today().add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
        expect(_formatDue(almostTomorrow), 'Due today');
      });
    });

    group('tomorrow boundary', () {
      test('midnight tomorrow → "Due tomorrow"', () {
        expect(_formatDue(_daysFromNow(1)), 'Due tomorrow');
      });

      test('noon tomorrow → "Due tomorrow"', () {
        final tomorrowNoon = _daysFromNow(1).add(const Duration(hours: 12));
        expect(_formatDue(tomorrowNoon), 'Due tomorrow');
      });
    });

    group('near future (2-6 days)', () {
      for (final days in [2, 3, 5, 6]) {
        test('$days days from now → "Due in $days days"', () {
          expect(_formatDue(_daysFromNow(days)), 'Due in $days days');
        });
      }
    });

    group('far future (7+ days)', () {
      test('exactly 7 days → formatted date with "Due" prefix', () {
        final result = _formatDue(_daysFromNow(7));
        expect(result, startsWith('Due '));
        // Should NOT contain "days" (that's only for 2-6)
        expect(result, isNot(contains('days')));
      });

      test('30 days → formatted date with "Due" prefix', () {
        final result = _formatDue(_daysFromNow(30));
        expect(result, startsWith('Due '));
        expect(result, isNot(contains('days')));
      });

      test('365 days → contains the correct year', () {
        final nextYear = _daysFromNow(365);
        final result = _formatDue(nextYear);
        expect(result, contains(nextYear.year.toString()));
      });
    });

    group('overdue', () {
      test('yesterday → starts with "Overdue"', () {
        expect(_formatDue(_daysFromNow(-1)), startsWith('Overdue'));
      });

      test('3 days ago → starts with "Overdue"', () {
        expect(_formatDue(_daysFromNow(-3)), startsWith('Overdue'));
      });

      test('overdue string contains " · " separator and the date', () {
        final threeDaysAgo = _daysFromNow(-3);
        final result = _formatDue(threeDaysAgo);
        expect(result, contains(' · '));
        // The formatted date should include the year
        expect(result, contains(threeDaysAgo.year.toString()));
      });

      test('one second before today midnight is yesterday → overdue', () {
        final justBeforeMidnight = _today().subtract(
          const Duration(seconds: 1),
        );
        expect(_formatDue(justBeforeMidnight), startsWith('Overdue'));
      });
    });

    group('boundary: exactly at cutoffs', () {
      test('day 6 → "Due in 6 days" (not formatted date)', () {
        expect(_formatDue(_daysFromNow(6)), equals('Due in 6 days'));
      });

      test('day 7 → formatted date (not "in N days")', () {
        final result = _formatDue(_daysFromNow(7));
        expect(result, isNot(contains('days')));
        expect(result, isNot(equals('Due tomorrow')));
        expect(result, isNot(equals('Due today')));
      });
    });
  });

  // formatDate / formatDateTime / formatTime
  group('DateFormatter.formatDate', () {
    test('formats a known date to "MMM d, y"', () {
      final dt = DateTime(2025, 3, 5);
      expect(DateFormatter.formatDate(dt), equals('Mar 5, 2025'));
    });

    test('single-digit day has no leading zero', () {
      expect(
        DateFormatter.formatDate(DateTime(2024, 1, 9)),
        equals('Jan 9, 2024'),
      );
    });

    test('double-digit day', () {
      expect(
        DateFormatter.formatDate(DateTime(2024, 12, 31)),
        equals('Dec 31, 2024'),
      );
    });
  });

  group('DateFormatter.formatDateTime', () {
    test('includes date and time separated by ·', () {
      final dt = DateTime(2025, 6, 15, 14, 30);
      final result = DateFormatter.formatDateTime(dt);
      expect(result, contains('Jun 15, 2025'));
      expect(result, contains('·'));
    });

    test('formats AM time correctly', () {
      final dt = DateTime(2025, 1, 1, 9, 5);
      final result = DateFormatter.formatDateTime(dt);
      expect(result, contains('AM'));
    });

    test('formats PM time correctly', () {
      final dt = DateTime(2025, 1, 1, 13, 0);
      final result = DateFormatter.formatDateTime(dt);
      expect(result, contains('PM'));
    });
  });

  group('DateFormatter.formatTime', () {
    test('formats noon as 12:00 PM', () {
      expect(
        DateFormatter.formatTime(DateTime(2025, 1, 1, 12, 0)),
        equals('12:00 PM'),
      );
    });

    test('formats midnight as 12:00 AM', () {
      expect(
        DateFormatter.formatTime(DateTime(2025, 1, 1, 0, 0)),
        equals('12:00 AM'),
      );
    });

    test('formats 9:05 AM with leading zero on minutes', () {
      expect(
        DateFormatter.formatTime(DateTime(2025, 1, 1, 9, 5)),
        equals('9:05 AM'),
      );
    });
  });

  // formatLog / formatLogMillis
  group('DateFormatter.formatLog', () {
    test('produces yyyy-MM-dd HH:mm:ss format', () {
      final dt = DateTime(2025, 1, 15, 10, 30, 45);
      // formatLog converts to local time; test the pattern rather than exact value
      expect(
        DateFormatter.formatLog(dt),
        matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'),
      );
    });

    test('zero-pads month, day, hours, minutes, seconds', () {
      // Use a UTC date and convert to local to avoid timezone sensitivity
      final dt = DateTime(2025, 3, 5, 8, 4, 2);
      final result = DateFormatter.formatLog(dt);
      expect(result, contains('2025'));
      expect(result, matches(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'));
    });
  });

  group('DateFormatter.formatLogMillis', () {
    test('returns a string with the correct year', () {
      final millis = DateTime(2025, 1, 15, 10, 30, 0).millisecondsSinceEpoch;
      expect(DateFormatter.formatLogMillis(millis), contains('2025'));
    });

    test('matches expected date string for a known timestamp', () {
      final dt = DateTime(2024, 6, 1, 0, 0, 0);
      final result = DateFormatter.formatLogMillis(dt.millisecondsSinceEpoch);
      // Pattern check - timezone-safe
      expect(result, matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'));
      expect(result, contains('2024'));
    });

    test('epoch 0 does not throw', () {
      expect(() => DateFormatter.formatLogMillis(0), returnsNormally);
    });

    test('very large timestamp (year 2100) does not throw', () {
      final bigMillis = DateTime(2100, 12, 31).millisecondsSinceEpoch;
      expect(() => DateFormatter.formatLogMillis(bigMillis), returnsNormally);
    });
  });

  // formatEpoch
  group('DateFormatter.formatEpoch', () {
    test('converts epoch seconds (not millis)', () {
      final dt = DateTime(2025, 6, 15, 12, 0, 0);
      final epochSeconds = dt.millisecondsSinceEpoch ~/ 1000;
      final result = DateFormatter.formatEpoch(epochSeconds);
      expect(result, contains('Jun 15, 2025'));
    });

    test('epoch 0 (1970-01-01) does not throw', () {
      expect(() => DateFormatter.formatEpoch(0), returnsNormally);
    });
  });
}
