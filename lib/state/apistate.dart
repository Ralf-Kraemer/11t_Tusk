import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iqon/model/status.dart';
import 'package:iqon/state/objects/ApiOAuth.dart';
import 'objects/ApiActivityPub.dart';

/// Riverpod 3 AsyncNotifier provider
final statusesProvider = AsyncNotifierProvider<StatusNotifier, List<Status>>(
  () => StatusNotifier(),
);

class StatusNotifier extends AsyncNotifier<List<Status>> {
  final ApiActivityPub api = ApiActivityPub();
  final ApiOAuth oauth = ApiOAuth();

  List<Status> _statusList = [];
  int _currentPage = 1;
  bool _isLoading = false;

  @override
  Future<List<Status>> build() async {
    // Called automatically when provider is first watched
    return _retrieveStatuses(loadMore: false);
  }

  /// Load next page (for infinite scrolling)
  Future<void> loadNextStatuses() async {
    await _retrieveStatuses(loadMore: true);
  }

  /// Core method to fetch statuses from API
  Future<List<Status>> _retrieveStatuses({bool loadMore = false}) async {
    if (_isLoading) return _statusList;

    _isLoading = true;

    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
    }

    final accessToken = await oauth.maybeRefreshAccessToken();
    if (accessToken == null) {
      _isLoading = false;
      throw Exception('Login not valid');
    }

    try {
      final newStatuses = await api.getStatusList(page: _currentPage);

      if (_currentPage == 1) {
        _statusList = newStatuses;
      } else {
        _statusList = [..._statusList, ...newStatuses];
      }

      // Update state in Riverpod 3
      state = AsyncData(_statusList);

      return _statusList;
    } catch (error, stackTrace) {
      if (loadMore) _currentPage--;
      state = AsyncError(error, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}
