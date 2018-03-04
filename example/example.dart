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
/// `dart2js --csp -o hello.js example/hello_docs.dart`.
///
/// See [apps_script_tools](https://pub.dartlang.org/packages/apps_script_tools)
/// for a description on how to execute the generated program.

@JS()
library hello_docs;

import 'package:js/js.dart';
import 'package:google_apps/document.dart';

@JS()
external set sayHello(value);

@JS()
external set onOpen(value);

void sayHelloDart() {
  DocumentApp.getUi().alert("Hello world");
}

void onOpenDart(e) {
  DocumentApp
      .getUi()
      .createMenu("from dart")
      .addItem("say hello", "sayHello")
      .addToUi();
}

main(List<String> arguments) {
  onOpen = allowInterop(onOpenDart);
  sayHello = allowInterop(sayHelloDart);
}
