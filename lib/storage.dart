class DartisStorage {
  final Map<String, String> _data = {};

  Future<void> set(String key, String value) async {
    _data[key] = value;
  }

  Future<String?> get(String key) async {
    return _data[key];
  }
}
