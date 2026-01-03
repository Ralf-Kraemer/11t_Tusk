import '../../model/status.dart';
import '../../utils/constants.dart';
import 'package:toot_ui/helper.dart';
import '../../utils/httpclient.dart';

class ApiActivityPub {
  final HttpClient httpClient = HttpClient();
  final helper = Helper.get();

  /// Fetch statuses from ActivityPub outbox
  /// Optional paging via `page` (not all servers support it)
  Future<List<Status>> getStatusList({int page = 1}) async {
    List<Status> result = [];

    // Base URL from helper
    var baseUrl = await helper.getPrefString('baseUrl');
    if (baseUrl == null) throw Exception('Base URL not set');

    // ActivityPub home timeline usually comes from /outbox
    // You might append `?page=...` if server supports paging
    var endpoint = '$baseUrl/$API_BASE/$API_TIMELINES_HOME';
    if (page > 1) {
      endpoint += '?page=$page';
    }

    try {
      final response = await httpClient.get(endpoint);

      if (response.data is Map) {
        // ActivityPub Collection object
        final items = response.data['orderedItems'] ?? response.data['items'] ?? [];
        if (items is List) {
          for (var v in items) {
            try {
              result.add(Status.fromJson(v));
            } catch (error) {
              // ignore parsing errors for individual items
              print('Status parse error: ${error.toString()}');
            }
          }
        }
      } else if (response.data is List) {
        // Some servers may return a raw list
        for (var v in response.data) {
          try {
            result.add(Status.fromJson(v));
          } catch (error) {
            print('Status parse error: ${error.toString()}');
          }
        }
      } else {
        print('Unexpected response format: ${response.data.runtimeType}');
      }
    } catch (error, stack) {
      print('API fetch error: $error');
      print(stack);
      rethrow;
    }

    return result;
  }
}
