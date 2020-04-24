@JS()
library cache;

import 'package:js/js.dart';

@JS()
class CacheService {
  external static Cache getDocumentCache();

  external static Cache getScriptCache();

  external static Cache getUserCache();
}

@JS()
class Cache {
  external String get(String key);

  external Object getAll(List<String> keys);

  external void put(String key, String value, [num expirationInSeconds]);

  external void putAll(Map<String, String> values, [num expirationInSeconds]);

  external void remove(String key);

  external void removeAll(List<String> keys);
}
