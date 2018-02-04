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
/// `dart2js --csp -o sheet.js example/sheet.dart`.
///
/// See [apps_script_uploader](https://pub.dartlang.org/packages/apps_script_uploader)
/// for a description on how to execute the generated program.

@JS()
library sheet;

import 'package:js/js.dart';
import 'package:google_apps/spreadsheet.dart';
import 'src/data.dart';

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
      .addItem("sheet", "${prefix}sheet")
      .addToUi();
}

void exportToJs() {
  onOpen = allowInterop(onOpenDart);
  demo = allowInterop(demoDart);
}

void demoDart() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().insertSheet();
  var imageHeight = imageData.length ~/ imageWidth;
  if (sheet.getMaxRows() < imageHeight + 1) {
    sheet.insertRows(1, imageHeight - sheet.getMaxRows());
  }
  if (sheet.getMaxColumns() < imageWidth + 1) {
    sheet.insertColumns(1, imageWidth - sheet.getMaxColumns());
  }
  for (int i = 0; i < imageWidth; i++) {
    sheet.setColumnWidth(i + 1, 2);
  }
  for (int i = 0; i < imageHeight; i++) {
    sheet.setRowHeight(i + 1, 3);
  }
  var colors = [];
  var index = 0;
  for (int i = 0; i < imageHeight; i++) {
    var row = [];
    colors.add(row);
    for (int j = 0; j < imageWidth; j++) {
      var color = imageData[index++];
      if (color == 0) {
        row.add(null);
        continue;
      }
      var r = (color & 0xFF000000) >> 32;
      var r2 = r.toRadixString(16);
      if (r2.length != 2) r2 = "0$r2";
      var g = (color & 0xFF00) >> 8;
      var g2 = g.toRadixString(16);
      if (g2.length != 2) g2 = "0$g2";
      var b = (color & 0xFF0000) >> 16;
      var b2 = b.toRadixString(16);
      if (b2.length != 2) b2 = "0$b2";
      row.add("#$r2$g2$b2");
    }
  }
  sheet.getRange(1, 1, imageHeight, imageWidth).setBackgrounds(colors);
}

main() {
  exportToJs();
}
