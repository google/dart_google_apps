// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Compile this example with
/// `dart2js --csp -o menu.js example/menu.dart`.
///
/// See [apps_script_uploader](https://pub.dartlang.org/packages/apps_script_uploader)
/// for a description on how to execute the generated program.

@JS()
library demo;

import 'package:google_apps/spreadsheet.dart';
import 'package:js/js.dart';

@JS()
external set onOpen(value);

@JS()
external set demo(value);

// The optional [prefix] is to make it easier to use this function
// in a shared library.
void onOpenDart(e, [String prefix]) {
  if (prefix == null) {
    prefix = "";
  } else {
    prefix = "$prefix.";
  }
  SpreadsheetApp
      .getUi()
      .createMenu("Dart")
      .addItem("hello", "hello")
      .addToUi();
}

void exportToJs() {
  onOpen = allowInterop(onOpenDart);
  demo = allowInterop(demoDart);
}

void demoDart() {
  SpreadsheetApp.getUi().alert("Hello World");
}

main() {
  exportToJs();
}
