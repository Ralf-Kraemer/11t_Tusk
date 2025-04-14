import 'package:shared_preferences/shared_preferences.dart';

class Helper {
  static final Helper _instance = Helper._internal();

  Helper._internal();

  factory Helper.get() {
    return _instance;
  }

  // Retrieves the stored access token
  Future<String?> getAccessToken() async {
    return await getPrefString('accessToken');
  }

  // Retrieves the Fediverse entry point URL
  Future<String?> getHomeInstanceName() async {
    return await getPrefString('homeInstanceName');
  }

  // Updates the Fediverse entry point URL
  Future<bool> setHomeInstanceName(String value) async {
    return await setPrefString('homeInstanceName', value);
  }


  // Retrieves a string value from SharedPreferences
  Future<String?> getPrefString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Saves a string value to SharedPreferences
  Future<bool> setPrefString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  // Retrieves an integer value from SharedPreferences
  Future<int?> getPrefInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  // Saves an integer value to SharedPreferences
  Future<bool> setPrefInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  // Removes a key from SharedPreferences
  Future<bool> removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  // Checks if a key exists in SharedPreferences
  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  // Clears all data in SharedPreferences
  Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}
