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
/// `dart2js --csp -o html_docs.js example/html_docs.dart`.
///
/// See [apps_script_uploader](https://pub.dartlang.org/packages/apps_script_uploader)
/// for a description on how to execute the generated program.

@JS()
library html_docs;

import 'package:js/js.dart';
import 'package:google_apps/google_apps.dart';

@JS()
external set onOpen(value);

@JS()
external set demo(value);

@JS()
external set modal(value);

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
      .addItem("demo", "${prefix}demo")
      .addToUi();
}

void exportToJs() {
  onOpen = allowInterop(onOpenDart);
  demo = allowInterop(demoDart);
  modal = allowInterop(modalDart);
}

String sideBar = r"""
<html>
<body>
<div>
<input name="check" value="Menus" type="checkbox" checked="true"/>
<label>Menus</label>
</div>
<div>
<input name="check" value="Hello World" type="checkbox" checked="true"/>
<label>Hello World</label>
</div>
<div>
<input name="check" value="Cell Manipulation" type="checkbox" checked="true"/>
<label>Cell Manipulation</label>
</div>
<div>
<input name="check" value="Sidebar" type="checkbox" checked="true"/>
<label>Sidebar</label>
</div>
<div>
<input name="check" value="Modal Dialog" type="checkbox" />
<label>Modal Dialog</label>
</div>
<div>
<input name="check" value="Documents" type="checkbox" />
<label>Documents</label>
</div>
<input type="button" onclick="submit()" value="Next" />

<script>
function submit() {
  var result = [];
  var checkedBoxes = document.querySelectorAll('input[name=check]:checked');
  for (var i = 0; i < checkedBoxes.length; i++) {
    result.push(checkedBoxes[i].value);
  }
  google.script.run.withSuccessHandler(close).modal(result);
  return false;
}

function close() {
  google.script.host.close();
}
</script>
</body>
</html>
""";

void demoDart() {
  HtmlOutput sideBarHtml = HtmlService.createHtmlOutput(sideBar);
  SpreadsheetApp.getUi().showSidebar(sideBarHtml);
}

void modalDart(selected) {
  var document = DocumentApp.create("doc-demo - ${new DateTime.now()}");
  var body = document.getBody();
  body.appendParagraph("Created from Dart").editAsText().setFontSize(32);
  body
      .appendParagraph("Selected items: ${selected}")
      .editAsText()
      .setFontSize(20);

  var id = document.getId();
  String html = """
  <html><body>
  <div>Created a <A href='https://docs.google.com/document/d/$id' target='_blank'>document</A>.</div>
  <input type='button' onclick=' google.script.host.close()' value='OK' />
  </body></html>
  """;
  HtmlOutput userInterface = HtmlService.createHtmlOutput(html.toString());
  SpreadsheetApp.getUi().showModalDialog(userInterface, "Document Ready");
}

main() {
  exportToJs();
}
