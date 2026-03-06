import 'package:flutter_test/flutter_test.dart';

import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/domain/entities/entities.dart';
import 'package:nextcloud_deck/presentation/providers/boards_provider.dart';

// Factory helpers - keep tests readable by only naming what matters
DeckCard _card({
  int id = 1,
  String title = 'Card',
  String description = '',
  int stackId = 1,
  int order = 0,
  bool archived = false,
  int deletedAt = 0,
  int createdAt = 0,
  int lastModified = 0,
  String? duedate,
  List<DeckLabel> labels = const [],
  List<DeckUser> assignedUsers = const [],
  DeckUser? owner,
}) => DeckCard(
  id: id,
  title: title,
  description: description,
  stackId: stackId,
  boardId: 1,
  order: order,
  archived: archived,
  createdAt: createdAt,
  lastModified: lastModified,
  deletedAt: deletedAt,
  duedate: duedate,
  labels: labels,
  assignedUsers: assignedUsers,
  owner: owner,
  type: 'plain',
);

DeckUser _user({
  String uid = 'alice',
  String displayName = 'Alice',
  int type = 0,
}) => DeckUser(uid: uid, displayName: displayName, type: type);

DeckLabel _label({
  int id = 1,
  String title = 'Bug',
  String color = 'D64545',
  int boardId = 1,
}) => DeckLabel(id: id, title: title, color: color, boardId: boardId);

// ISO-8601 helpers that avoid sub-second precision surprises
String _isoPast({int days = 1}) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String();
String _isoFuture({int days = 1}) =>
    DateTime.now().add(Duration(days: days)).toIso8601String();

void main() {
  // DeckUser
  group('DeckUser', () {
    test('fromJson parses all fields', () {
      final u = DeckUser.fromJson({
        'uid': 'bob',
        'displayname': 'Bob',
        'type': 1,
      });
      expect(u.uid, 'bob');
      expect(u.displayName, 'Bob');
      expect(u.type, 1);
    });

    test('fromJson uses safe defaults for missing fields', () {
      final u = DeckUser.fromJson({});
      expect(u.uid, '');
      expect(u.displayName, '');
      expect(u.type, 0);
    });

    test('equality is based on uid only', () {
      final a = _user(uid: 'alice', displayName: 'Alice');
      final b = _user(uid: 'alice', displayName: 'Different Name');
      final c = _user(uid: 'carol');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = _user(uid: 'alice');
      final b = _user(uid: 'alice');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toJson round-trips cleanly', () {
      final u = _user(uid: 'dave', displayName: 'Dave', type: 1);
      final json = u.toJson();
      final roundTrip = DeckUser.fromJson(json);
      expect(roundTrip.uid, u.uid);
      expect(roundTrip.displayName, u.displayName);
      expect(roundTrip.type, u.type);
    });
  });

  // DeckLabel
  group('DeckLabel', () {
    test('fromJson parses all fields', () {
      final l = DeckLabel.fromJson({
        'id': 7,
        'title': 'Feature',
        'color': '46BA61',
        'boardId': 2,
      });
      expect(l.id, 7);
      expect(l.title, 'Feature');
      expect(l.color, '46BA61');
      expect(l.boardId, 2);
    });

    test('fromJson falls back to brand blue for missing color', () {
      final l = DeckLabel.fromJson({'id': 1, 'title': 'X', 'boardId': 1});
      expect(l.color, '0082C9');
    });

    test('flutterColor produces a non-transparent color', () {
      final label = _label(color: 'D64545');
      // Red channel should be high, alpha should be 1.0
      expect(label.flutterColor.a, closeTo(1.0, 0.01));
    });

    test('flutterColor falls back to brand for invalid hex', () {
      final label = _label(color: 'ZZZZZZ');
      expect(label.flutterColor, equals(AppColors.brand));
    });

    test('copyWith only changes specified fields', () {
      final original = _label(title: 'Original', color: 'FF0000');
      final updated = original.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.color, 'FF0000');
      expect(updated.id, original.id);
      expect(updated.boardId, original.boardId);
    });

    test('toJson round-trips cleanly', () {
      final l = _label(id: 5, title: 'Regression', color: 'F7C948', boardId: 3);
      final rt = DeckLabel.fromJson(l.toJson());
      expect(rt.id, l.id);
      expect(rt.title, l.title);
      expect(rt.color, l.color);
      expect(rt.boardId, l.boardId);
    });
  });

  // DeckBoard
  group('DeckBoard.fromJson', () {
    test('parses a full board JSON', () {
      final json = {
        'id': 1,
        'title': 'My Board',
        'color': '0082C9',
        'archived': false,
        'shared': 0,
        'lastModified': 1700000000,
        'ETag': 'abc123',
        'owner': {'uid': 'alice', 'displayname': 'Alice', 'type': 0},
        'labels': [
          {'id': 10, 'title': 'Bug', 'color': 'D64545', 'boardId': 1},
        ],
        'permissions': {
          'PERMISSION_READ': true,
          'PERMISSION_EDIT': true,
          'PERMISSION_MANAGE': true,
          'PERMISSION_SHARE': false,
        },
      };

      final board = DeckBoard.fromJson(json);
      expect(board.id, 1);
      expect(board.title, 'My Board');
      expect(board.color, '0082C9');
      expect(board.archived, false);
      expect(board.owner?.uid, 'alice');
      expect(board.labels.length, 1);
      expect(board.labels.first.title, 'Bug');
      expect(board.permissionEdit, true);
      expect(board.permissionShare, false);
    });

    test('handles missing optional fields gracefully', () {
      final board = DeckBoard.fromJson({'id': 2, 'title': 'Minimal'});
      expect(board.id, 2);
      expect(board.title, 'Minimal');
      expect(board.labels, isEmpty);
      expect(board.owner, isNull);
      expect(board.color, '0082C9'); // default brand colour
    });

    test('parses multiple labels', () {
      final board = DeckBoard.fromJson({
        'id': 3,
        'title': 'Multi Label',
        'labels': [
          {'id': 1, 'title': 'A', 'color': 'FF0000', 'boardId': 3},
          {'id': 2, 'title': 'B', 'color': '00FF00', 'boardId': 3},
          {'id': 3, 'title': 'C', 'color': '0000FF', 'boardId': 3},
        ],
      });
      expect(board.labels.length, 3);
      expect(board.labels.map((l) => l.title), containsAll(['A', 'B', 'C']));
    });

    test('flutterColor is non-transparent', () {
      final board = DeckBoard.fromJson({
        'id': 1,
        'title': 'Coloured',
        'color': '46BA61',
      });
      expect(board.flutterColor.a, closeTo(1.0, 0.01));
    });

    test('copyWith changes only specified fields', () {
      final board = DeckBoard.fromJson({
        'id': 1,
        'title': 'Old',
        'color': 'FF0000',
        'archived': false,
      });
      final updated = board.copyWith(title: 'New', archived: true);
      expect(updated.title, 'New');
      expect(updated.archived, true);
      expect(updated.color, 'FF0000');
      expect(updated.id, 1);
    });

    test('toJson round-trips id, title, color, archived', () {
      final original = DeckBoard.fromJson({
        'id': 99,
        'title': 'Round Trip',
        'color': '9D5BD2',
        'archived': true,
      });
      final rt = DeckBoard.fromJson(original.toJson());
      expect(rt.id, 99);
      expect(rt.title, 'Round Trip');
      expect(rt.color, '9D5BD2');
      expect(rt.archived, true);
    });
  });

  // DeckStack
  group('DeckStack.fromJson', () {
    test('parses stack with nested cards', () {
      final json = {
        'id': 5,
        'title': 'To Do',
        'boardId': 1,
        'order': 0,
        'lastModified': 1700000000,
        'deletedAt': 0,
        'cards': [
          {
            'id': 100,
            'title': 'Card A',
            'description': '',
            'stackId': 5,
            'boardId': 1,
            'order': 0,
            'archived': false,
            'createdAt': 1700000000,
            'lastModified': 1700000000,
            'deletedAt': 0,
            'type': 'plain',
          },
        ],
      };

      final stack = DeckStack.fromJson(json);
      expect(stack.id, 5);
      expect(stack.title, 'To Do');
      expect(stack.cards.length, 1);
      expect(stack.cards.first.title, 'Card A');
    });

    test('handles missing cards array - defaults to empty list', () {
      final stack = DeckStack.fromJson({
        'id': 6,
        'title': 'Empty',
        'boardId': 1,
      });
      expect(stack.cards, isEmpty);
    });

    test('isDeleted is false when deletedAt is 0', () {
      final stack = DeckStack.fromJson({
        'id': 7,
        'title': 'Live',
        'boardId': 1,
        'deletedAt': 0,
      });
      expect(stack.isDeleted, isFalse);
    });

    test('isDeleted is true when deletedAt is non-zero', () {
      final stack = DeckStack.fromJson({
        'id': 8,
        'title': 'Gone',
        'boardId': 1,
        'deletedAt': 1700000000,
      });
      expect(stack.isDeleted, isTrue);
    });

    test('copyWith updates title and cards without changing other fields', () {
      final original = DeckStack.fromJson({
        'id': 9,
        'title': 'Old',
        'boardId': 1,
        'order': 2,
      });
      final updated = original.copyWith(title: 'New');
      expect(updated.title, 'New');
      expect(updated.id, 9);
      expect(updated.order, 2);
    });
  });

  // DeckCard
  group('DeckCard - due date computed properties', () {
    test('isOverdue is true for a past due date', () {
      final c = _card(duedate: _isoPast(days: 2));
      expect(c.isOverdue, isTrue);
      expect(c.isDueToday, isFalse);
    });

    test('isOverdue is false for a future due date', () {
      final c = _card(duedate: _isoFuture(days: 2));
      expect(c.isOverdue, isFalse);
    });

    test('isDueToday is true when due today', () {
      final now = DateTime.now();
      final todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);
      final c = _card(duedate: todayNoon.toIso8601String());
      expect(c.isDueToday, isTrue);
    });

    test('isOverdue is false when due tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final c = _card(duedate: tomorrow.toIso8601String());
      expect(c.isOverdue, isFalse);
    });

    test('isDueToday is false for yesterday', () {
      final c = _card(duedate: _isoPast(days: 1));
      expect(c.isDueToday, isFalse);
    });

    test('isDueToday is false for tomorrow', () {
      final c = _card(duedate: _isoFuture(days: 1));
      expect(c.isDueToday, isFalse);
    });

    test('hasDueDate is false when duedate is null', () {
      final c = _card(duedate: null);
      expect(c.hasDueDate, isFalse);
      expect(c.dueDateParsed, isNull);
      expect(c.isOverdue, isFalse);
      expect(c.isDueToday, isFalse);
    });

    test('hasDueDate is false for an empty string', () {
      final c = _card(duedate: '');
      expect(c.hasDueDate, isFalse);
      expect(c.dueDateParsed, isNull);
    });

    test('dueDateParsed returns null for a malformed date string', () {
      final c = _card(duedate: 'not-a-date');
      expect(c.dueDateParsed, isNull);
      expect(c.isOverdue, isFalse);
      expect(c.isDueToday, isFalse);
    });

    test(
      'dueDateParsed returns a valid DateTime for a well-formed ISO string',
      () {
        final c = _card(duedate: '2025-06-15T12:00:00.000Z');
        expect(c.dueDateParsed, isNotNull);
      },
    );

    test('isDeleted is false when deletedAt is 0', () {
      expect(_card(deletedAt: 0).isDeleted, isFalse);
    });

    test('isDeleted is true when deletedAt is non-zero', () {
      expect(_card(deletedAt: 1700000000).isDeleted, isTrue);
    });
  });

  group('DeckCard.fromJson', () {
    test('parses card with assignedUsers via participant wrapper', () {
      final json = {
        'id': 50,
        'title': 'Assigned',
        'description': '',
        'stackId': 1,
        'boardId': 1,
        'order': 0,
        'archived': false,
        'createdAt': 0,
        'lastModified': 0,
        'deletedAt': 0,
        'type': 'plain',
        'assignedUsers': [
          {
            'participant': {'uid': 'alice', 'displayname': 'Alice', 'type': 0},
          },
        ],
      };

      final card = DeckCard.fromJson(json);
      expect(card.assignedUsers.length, 1);
      expect(card.assignedUsers.first.uid, 'alice');
    });

    test('parses card without assignedUsers - defaults to empty', () {
      final card = DeckCard.fromJson({
        'id': 51,
        'title': 'Solo',
        'stackId': 1,
        'boardId': 1,
      });
      expect(card.assignedUsers, isEmpty);
      expect(card.labels, isEmpty);
    });

    test('parses labels nested inside card', () {
      final card = DeckCard.fromJson({
        'id': 52,
        'title': 'With Labels',
        'stackId': 1,
        'boardId': 1,
        'labels': [
          {'id': 1, 'title': 'Bug', 'color': 'D64545', 'boardId': 1},
          {'id': 2, 'title': 'Urgent', 'color': 'F7C948', 'boardId': 1},
        ],
      });
      expect(card.labels.length, 2);
      expect(card.labels.map((l) => l.title), containsAll(['Bug', 'Urgent']));
    });

    test('toJson round-trips all scalar fields', () {
      final original = _card(
        id: 99,
        title: 'Round-trip',
        description: 'desc',
        stackId: 5,
        order: 3,
        archived: false,
        deletedAt: 0,
      );
      final rt = DeckCard.fromJson(original.toJson());
      expect(rt.id, original.id);
      expect(rt.title, original.title);
      expect(rt.description, original.description);
      expect(rt.stackId, original.stackId);
      expect(rt.order, original.order);
      expect(rt.archived, original.archived);
    });
  });

  group('DeckCard.copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final original = _card(id: 4, title: 'Original', description: 'Desc');
      final updated = original.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.description, 'Desc');
      expect(updated.id, 4);
    });

    test('copyWith can move card to a different stack', () {
      final c = _card(stackId: 1);
      expect(c.copyWith(stackId: 2).stackId, 2);
    });

    test('copyWith clearDueDate removes the due date', () {
      final c = _card(duedate: _isoFuture(days: 5));
      final cleared = c.copyWith(clearDueDate: true);
      expect(cleared.hasDueDate, isFalse);
      expect(cleared.dueDateParsed, isNull);
    });

    test('copyWith can update labels', () {
      final newLabels = [_label(id: 99, title: 'New Label')];
      final c = _card(labels: [_label()]);
      final updated = c.copyWith(labels: newLabels);
      expect(updated.labels.length, 1);
      expect(updated.labels.first.title, 'New Label');
    });

    test('copyWith can archive a card', () {
      final c = _card(archived: false);
      expect(c.copyWith(archived: true).archived, isTrue);
    });
  });

  // FilterState
  group('FilterState.hasActiveFilter', () {
    test('false when all defaults', () {
      expect(const FilterState().hasActiveFilter, isFalse);
    });

    test('true when assignedToMe is set', () {
      expect(const FilterState(assignedToMe: true).hasActiveFilter, isTrue);
    });

    test('true when overdueOnly is set', () {
      expect(const FilterState(overdueOnly: true).hasActiveFilter, isTrue);
    });

    test('true when dueDateOnly is set', () {
      expect(const FilterState(dueDateOnly: true).hasActiveFilter, isTrue);
    });

    test('true when labelFilter is set', () {
      expect(FilterState(labelFilter: _label()).hasActiveFilter, isTrue);
    });

    test('true when searchQuery is non-empty', () {
      expect(const FilterState(searchQuery: 'x').hasActiveFilter, isTrue);
    });

    test('false when searchQuery is only whitespace', () {
      expect(const FilterState(searchQuery: '   ').hasActiveFilter, isFalse);
    });
  });

  group('FilterState.apply - pre-processing', () {
    test('strips archived cards before filtering', () {
      final cards = [
        _card(id: 1, archived: false),
        _card(id: 2, archived: true),
      ];
      final result = const FilterState().apply(cards);
      expect(result.map((c) => c.id), equals([1]));
    });

    test('strips deleted cards (deletedAt > 0) before filtering', () {
      final cards = [
        _card(id: 1, deletedAt: 0),
        _card(id: 2, deletedAt: 1700000000),
      ];
      final result = const FilterState().apply(cards);
      expect(result.map((c) => c.id), equals([1]));
    });

    test('strips both archived and deleted in one pass', () {
      final cards = [
        _card(id: 1),
        _card(id: 2, archived: true),
        _card(id: 3, deletedAt: 1),
        _card(id: 4),
      ];
      final result = const FilterState().apply(cards);
      expect(result.map((c) => c.id), equals([1, 4]));
    });

    test('returns a new list - does not mutate the input', () {
      final cards = [_card(id: 1), _card(id: 2)];
      final result = const FilterState().apply(cards);
      expect(identical(result, cards), isFalse);
    });
  });

  group('FilterState.apply - overdue filter', () {
    test('returns only overdue cards', () {
      final cards = [
        _card(id: 1, duedate: _isoPast(days: 1)),
        _card(id: 2, duedate: _isoFuture(days: 1)),
        _card(id: 3, duedate: null),
      ];
      final result = const FilterState(overdueOnly: true).apply(cards);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('returns empty list when no cards are overdue', () {
      final cards = [_card(duedate: _isoFuture(days: 1))];
      expect(const FilterState(overdueOnly: true).apply(cards), isEmpty);
    });
  });

  group('FilterState.apply - due date filter', () {
    test('returns only cards that have a due date', () {
      final cards = [
        _card(id: 1, duedate: _isoFuture(days: 3)),
        _card(id: 2, duedate: null),
        _card(id: 3, duedate: ''),
      ];
      final result = const FilterState(dueDateOnly: true).apply(cards);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });
  });

  group('FilterState.apply - label filter', () {
    test('returns only cards with the specified label', () {
      final bugLabel = _label(id: 10, title: 'Bug');
      final featLabel = _label(id: 20, title: 'Feature');
      final cards = [
        _card(id: 1, labels: [bugLabel]),
        _card(id: 2, labels: [featLabel]),
        _card(id: 3, labels: [bugLabel, featLabel]),
        _card(id: 4, labels: []),
      ];
      final result = FilterState(labelFilter: bugLabel).apply(cards);
      expect(result.map((c) => c.id), containsAll([1, 3]));
      expect(result.length, 2);
    });

    test('returns empty list when no card has the label', () {
      final rareLabel = _label(id: 99, title: 'Rare');
      final cards = [
        _card(labels: [_label(id: 1)]),
      ];
      expect(FilterState(labelFilter: rareLabel).apply(cards), isEmpty);
    });
  });

  group('FilterState.apply - assignee filter', () {
    test('returns only cards assigned to currentUsername', () {
      final alice = _user(uid: 'alice');
      final bob = _user(uid: 'bob');
      final cards = [
        _card(id: 1, assignedUsers: [alice]),
        _card(id: 2, assignedUsers: [bob]),
        _card(id: 3, assignedUsers: [alice, bob]),
        _card(id: 4, assignedUsers: []),
      ];
      final result = FilterState(
        assignedToMe: true,
        currentUsername: 'alice',
      ).apply(cards);
      expect(result.map((c) => c.id), containsAll([1, 3]));
      expect(result.length, 2);
    });

    test('assignedToMe with null currentUsername returns all cards', () {
      final alice = _user(uid: 'alice');
      final cards = [
        _card(id: 1, assignedUsers: [alice]),
        _card(id: 2),
      ];
      // currentUsername defaults to null - filter is a no-op
      final result = const FilterState(assignedToMe: true).apply(cards);
      expect(result.length, 2);
    });
  });

  group('FilterState.apply - text search', () {
    test('filters by title (case-insensitive)', () {
      final cards = [
        _card(id: 1, title: 'Fix the bug'),
        _card(id: 2, title: 'Write tests'),
        _card(id: 3, title: 'BUG: crash on login'),
      ];
      final result = const FilterState(searchQuery: 'bug').apply(cards);
      expect(result.map((c) => c.id), containsAll([1, 3]));
      expect(result.length, 2);
    });

    test('filters by description (case-insensitive)', () {
      final cards = [
        _card(id: 1, description: 'related to authentication'),
        _card(id: 2, description: 'UI polish'),
      ];
      final result = const FilterState(searchQuery: 'Auth').apply(cards);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('whitespace-only query returns all cards', () {
      final cards = [_card(id: 1), _card(id: 2)];
      expect(const FilterState(searchQuery: '   ').apply(cards).length, 2);
    });

    test('no match returns empty list', () {
      final cards = [_card(title: 'Unrelated')];
      expect(const FilterState(searchQuery: 'xyzzy').apply(cards), isEmpty);
    });
  });

  group('FilterState.apply - sorting', () {
    test('SortOption.order sorts ascending by card.order', () {
      final cards = [
        _card(id: 1, order: 3),
        _card(id: 2, order: 1),
        _card(id: 3, order: 2),
      ];
      final result = const FilterState(
        sortOption: SortOption.order,
      ).apply(cards);
      expect(result.map((c) => c.order).toList(), [1, 2, 3]);
    });

    test('SortOption.alphabetical sorts A→Z by title (case-insensitive)', () {
      final cards = [
        _card(id: 1, title: 'Zebra'),
        _card(id: 2, title: 'apple'),
        _card(id: 3, title: 'Mango'),
      ];
      final result = const FilterState(
        sortOption: SortOption.alphabetical,
      ).apply(cards);
      expect(result.map((c) => c.title.toLowerCase()).toList(), [
        'apple',
        'mango',
        'zebra',
      ]);
    });

    test('SortOption.alphabetical uses order as tie-breaker', () {
      final cards = [
        _card(id: 1, title: 'Alpha', order: 2),
        _card(id: 2, title: 'Alpha', order: 1),
      ];
      final result = const FilterState(
        sortOption: SortOption.alphabetical,
      ).apply(cards);
      expect(result.first.id, 2); // lower order wins the tie
    });

    test('SortOption.dueDate sorts ascending with nulls at end', () {
      final cards = [
        _card(id: 1, duedate: _isoFuture(days: 5)),
        _card(id: 2, duedate: null),
        _card(id: 3, duedate: _isoFuture(days: 2)),
      ];
      final result = const FilterState(
        sortOption: SortOption.dueDate,
      ).apply(cards);
      // Card 3 (2 days) then Card 1 (5 days) then Card 2 (no due date)
      expect(result[0].id, 3);
      expect(result[1].id, 1);
      expect(result[2].id, 2);
    });

    test('SortOption.createdDate sorts ascending by createdAt', () {
      final cards = [
        _card(id: 1, createdAt: 300),
        _card(id: 2, createdAt: 100),
        _card(id: 3, createdAt: 200),
      ];
      final result = const FilterState(
        sortOption: SortOption.createdDate,
      ).apply(cards);
      expect(result.map((c) => c.id).toList(), [2, 3, 1]);
    });
  });

  group('FilterState.apply - combined filters', () {
    test('overdue + label filter combines correctly (AND logic)', () {
      final bug = _label(id: 10, title: 'Bug');
      final cards = [
        _card(id: 1, duedate: _isoPast(), labels: [bug]), // overdue + bug
        _card(id: 2, duedate: _isoPast(), labels: []), // overdue, no label
        _card(id: 3, duedate: _isoFuture(), labels: [bug]), // bug, not overdue
      ];
      final result = FilterState(
        overdueOnly: true,
        labelFilter: bug,
      ).apply(cards);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('search + alphabetical sort work together', () {
      final cards = [
        _card(id: 1, title: 'Auth bug fix'),
        _card(id: 2, title: 'Authentication refactor'),
        _card(id: 3, title: 'Unrelated task'),
      ];
      final result = const FilterState(
        searchQuery: 'auth',
        sortOption: SortOption.alphabetical,
      ).apply(cards);
      expect(result.length, 2);
      expect(result.first.title.toLowerCase(), startsWith('auth bug'));
      expect(result.last.title.toLowerCase(), startsWith('authentication'));
    });
  });

  group('FilterState.copyWith', () {
    test('copyWith changes only specified fields', () {
      const original = FilterState(assignedToMe: true, overdueOnly: false);
      final updated = original.copyWith(overdueOnly: true);
      expect(updated.assignedToMe, true); // unchanged
      expect(updated.overdueOnly, true); // changed
    });

    test('clearLabel removes the label filter', () {
      final state = FilterState(labelFilter: _label());
      final cleared = state.copyWith(clearLabel: true);
      expect(cleared.labelFilter, isNull);
    });
  });
}
