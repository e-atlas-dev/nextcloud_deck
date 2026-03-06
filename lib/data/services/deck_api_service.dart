import 'package:nextcloud_deck/core/constants/api_constants.dart';
import 'package:nextcloud_deck/core/network/api_client.dart';

/// Wraps every endpoint of the Nextcloud Deck REST API v1.1.
class DeckApiService {
  DeckApiService({required this.apiClient, required this.serverUrl});

  final ApiClient apiClient;
  final String serverUrl;

  String _deck(String path) => '$serverUrl${ApiConstants.deckApiPath}$path';

  // BOARDS

  Future<List<Map<String, dynamic>>> getBoards() =>
      apiClient.getList(_deck('/boards?fullDetails=true'));

  Future<Map<String, dynamic>> getBoard(int boardId) =>
      apiClient.get(_deck('/boards/$boardId'));

  Future<Map<String, dynamic>> createBoard({
    required String title,
    required String color,
  }) => apiClient.post(_deck('/boards'), {'title': title, 'color': color});

  Future<Map<String, dynamic>> updateBoard(
    int boardId, {
    required String title,
    required String color,
    bool archived = false,
  }) => apiClient.put(_deck('/boards/$boardId'), {
    'title': title,
    'color': color,
    'archived': archived,
  });

  Future<void> deleteBoard(int boardId) =>
      apiClient.delete(_deck('/boards/$boardId'));

  // STACKS

  /// Returns a single stack with its cards embedded (used for conflict detection).
  Future<Map<String, dynamic>> getStack(int boardId, int stackId) =>
      apiClient.get(_deck('/boards/$boardId/stacks/$stackId'));

  Future<List<Map<String, dynamic>>> getStacks(int boardId) =>
      apiClient.getList(_deck('/boards/$boardId/stacks'));

  Future<Map<String, dynamic>> createStack(
    int boardId, {
    required String title,
    required int order,
  }) => apiClient.post(_deck('/boards/$boardId/stacks'), {
    'title': title,
    'order': order,
  });

  Future<Map<String, dynamic>> updateStack(
    int boardId,
    int stackId, {
    required String title,
    required int order,
  }) => apiClient.put(_deck('/boards/$boardId/stacks/$stackId'), {
    'title': title,
    'order': order,
  });

  Future<void> deleteStack(int boardId, int stackId) =>
      apiClient.delete(_deck('/boards/$boardId/stacks/$stackId'));

  // CARDS

  Future<List<Map<String, dynamic>>> getCards(int boardId, int stackId) =>
      apiClient.getList(_deck('/boards/$boardId/stacks/$stackId/cards'));

  Future<Map<String, dynamic>> createCard(
    int boardId,
    int stackId, {
    required String title,
    String description = '',
    String? duedate,
  }) => apiClient.post(_deck('/boards/$boardId/stacks/$stackId/cards'), {
    'title': title,
    'description': description,
    'type': 'plain',
    'order': 999,
    if (duedate != null) 'duedate': duedate,
  });

  Future<Map<String, dynamic>> updateCard(
    int boardId,
    int stackId,
    int cardId, {
    required Map<String, dynamic> fields,
  }) => apiClient.put(
    _deck('/boards/$boardId/stacks/$stackId/cards/$cardId'),
    fields,
  );

  Future<void> deleteCard(int boardId, int stackId, int cardId) =>
      apiClient.delete(_deck('/boards/$boardId/stacks/$stackId/cards/$cardId'));

  /// Moves a card to a different stack (or reorders within the same stack).
  Future<Map<String, dynamic>> moveCard(
    int boardId,
    int stackId,
    int cardId, {
    required int targetStackId,
    required int order,
  }) => apiClient.put(
    _deck('/boards/$boardId/stacks/$targetStackId/cards/$cardId/reorder'),
    {'order': order},
  );

  Future<Map<String, dynamic>> assignLabel(
    int boardId,
    int stackId,
    int cardId,
    int labelId,
  ) => apiClient.post(
    _deck('/boards/$boardId/stacks/$stackId/cards/$cardId/assignLabel'),
    {'labelId': labelId},
  );

  Future<void> removeLabel(int boardId, int stackId, int cardId, int labelId) =>
      apiClient.post(
        _deck('/boards/$boardId/stacks/$stackId/cards/$cardId/removeLabel'),
        {'labelId': labelId},
      );

  Future<Map<String, dynamic>> assignUser(
    int boardId,
    int stackId,
    int cardId,
    String userId,
  ) => apiClient.post(
    _deck('/boards/$boardId/stacks/$stackId/cards/$cardId/assignUser'),
    {'userId': userId},
  );

  Future<void> unassignUser(
    int boardId,
    int stackId,
    int cardId,
    String userId,
  ) => apiClient.post(
    _deck('/boards/$boardId/stacks/$stackId/cards/$cardId/unassignUser'),
    {'userId': userId},
  );

  // LABELS

  Future<Map<String, dynamic>> createLabel(
    int boardId, {
    required String title,
    required String color,
  }) => apiClient.post(_deck('/boards/$boardId/labels'), {
    'title': title,
    'color': color,
  });

  Future<void> deleteLabel(int boardId, int labelId) =>
      apiClient.delete(_deck('/boards/$boardId/labels/$labelId'));

  // CAPABILITIES

  Future<Map<String, dynamic>> getCapabilities() =>
      apiClient.get('$serverUrl/ocs/v1.php/cloud/capabilities?format=json');
}
