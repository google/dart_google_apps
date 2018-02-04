# google_apps

A library to write Google Apps scripts.

## Usage

A simple usage example:

``` dart
@JS()
library apps;

import 'package:google_apps/google_apps.dart';
import 'package:js/js.dart'

main() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("someSheet");
  var cell = sheet.getActiveCell();
  cell.
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
