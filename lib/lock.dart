@JS()
library lock;

import 'package:js/js.dart';

@JS()
class LockService {
  external static Lock getDocumentLock();

  external static Lock getScriptLock();

  external static Lock getUserLock();
}

@JS()
class Lock {
  external bool hasLock();

  external void releaseLock();

  external bool tryLock(num timeoutInMillis);

  external void waitLock(num timeoutInMillis);
}
