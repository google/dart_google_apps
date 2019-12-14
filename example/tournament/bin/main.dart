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
library main;

import 'package:js/js.dart';
import 'package:tournament/menu.dart' as tournament_menu;
import 'package:google_apps/google_apps.dart';

@JS()
external set onOpen(value);

void onOpenDart(e, [String prefix]) {
  String withPrefix(String funName) {
    if (prefix == null) return funName;
    return '$prefix.$funName';
  }

  var menu = SpreadsheetApp.getUi().createAddonMenu();
  var dartMenu = tournament_menu.createMenuEntries();
  dartMenu.forEach((caption, value) {
    if (caption == null) {
      menu = menu.addSeparator();
    } else if (value is Map) {
      var subMenu = SpreadsheetApp.getUi().createMenu(caption);
      value.forEach((caption, funName) {
        subMenu = subMenu.addItem(caption, withPrefix(funName));
      });
      menu = menu.addSubMenu(subMenu);
    } else {
      assert(value is String);
      menu = menu.addItem(caption, withPrefix(value));
    }
  });
  menu.addToUi();
}

void exportToJs() {
  onOpen = allowInterop(onOpenDart);
}

void main() {
  exportToJs();
  tournament_menu.exportToJs();
}
