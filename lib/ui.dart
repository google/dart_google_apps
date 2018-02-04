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

@JS()
library ui;

import 'package:js/js.dart';
import 'html.dart';
export 'html.dart';

@JS()
class UI {
  external void prompt(String msg);
  external void alert(String msg);
  external Menu createMenu(String caption);
  external Menu createAddonMenu();
  external void showModalDialog(HtmlOutput userInterface, String title);
  external void showSidebar(HtmlOutput userInterface);
}

@JS()
class Menu {
  external Menu addItem(String caption, String functionName);
  external Menu addSeparator();
  external Menu addSubMenu(Menu menu);
  external void addToUi();
}
