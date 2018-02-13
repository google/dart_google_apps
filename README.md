# Dart APIs for Google Apps scripts

This is not an official Google product. It is not supported by the Dart team.

This package is still in an experimental state.

A library to write Google Apps scripts.

This library has been written on a per-need basis. As such it is missing lots
of useful functionality that I just hadn't needed yet. Until the API coverage
is nearing completeness I recommend to checkout the GIT repository during
development and to use this library with a `path` directive, adding the missing
functions when they are encountered.

Consider contributing your changes back to the original repository.

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
