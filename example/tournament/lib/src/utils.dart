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

import 'package:google_apps/google_apps.dart';

/// Alerts the user with a popup.
void alert(String msg) {
  SpreadsheetApp.getUi().alert(msg);
}

/// Alerts the user of an error and throws the error.
void error(String msg) {
  alert(msg);
  throw msg;
}

/// Takes a participant [name] and normalizes it.
///
/// If the [name] is an email address returns the local part (everything before
/// the '@').
String normalizeName(String name) {
  if (name.contains('@')) {
    return name.substring(0, name.indexOf('@'));
  }
  return name;
}

/// Returns the name of the sheet for the given [participant].
String sheetNameFromParticipant(String participant) {
  return normalizeName(participant);
}


/// Moves [file] into [folder].
///
/// The [file] argument must have an id (accessed via `getId`). As such,
/// [Spreadsheet]s and [Document]s work.
void moveFileToFolder(var file, Folder folder) {
  file = DriveApp.getFileById(file.getId());
  folder.addFile(file);
  DriveApp.getRootFolder().removeFile(file);
}
