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

import 'brackets.dart' show participantLocation;
import 'config.dart';
import 'tournament.dart';
import 'utils.dart';

import 'package:google_apps/google_apps.dart';

/// (Re)Builds the cache.
///
/// Runtime calls to the Google Apps service are very expensive, and it is
/// hence advisable to limit the number of API calls.
///
/// The cache sheet groups all interesting properties of the individual
/// tournament sheets (of each participant) into one sheet. This way, many
/// operation scan be performed without even looking at the participant sheets.
///
/// The cache is built based on the *colors* of the tournament sheets.
/// Conceptually it runs through the tournament sheet and finds two
/// competitors by detecting their colors. The corresponding round-number (and
/// results) are similarly found by detecting cells with the correct colors.
void rebuildCacheDart() {
  var spreadsheet = SpreadsheetApp.getActiveSpreadsheet();

  var cacheSheet = spreadsheet.getSheetByName(cacheSheetName);
  if (cacheSheet != null) spreadsheet.deleteSheet(cacheSheet);
  cacheSheet = spreadsheet.insertSheet();
  cacheSheet.setName(cacheSheetName);
  cacheSheet.hideSheet();

  var sheets = allParticipants.map((participant) {
    var name = sheetNameFromParticipant(participant);
    return spreadsheet.getSheetByName(name);
  }).toList();

  var formulas = <List<String>>[];

  for (var sheet in sheets) {
    if (sheet == null) continue;  // Not all sheets have been built yet.
    var range = sheet.getDataRange();
    var rowCount = range.getNumRows();
    var columnCount = range.getNumColumns();

    var colors = range.getBackgrounds();

    var sheetName = sheet.getName();

    String ref(int row, int column) {
      var alphaColumn = String.fromCharCode('A'.codeUnitAt(0) + column);
      return '=$sheetName!\$$alphaColumn\$${row + 1}';
    }

    var participantNameReference = '=$sheetName!$participantLocation';

    for (var j = 0; j < columnCount; j += 2) {
      String competitorARef;
      String roundRef;
      int roundRow;
      int roundColumn;
      BattleType type;
      String resultRef;
      for (var i = 0; i < rowCount; i++) {
        var color = colors[i][j];
        switch (color) {
          case competitorColor:
            if (roundRef == null) {
              // This might overwrite the competitorA, if it was referring to the
              // tournament winner cell. That's fine, since the winner isn't
              // paired anymore.
              competitorARef = ref(i, j);
            } else {
              var competitorBRef = ref(i, j);
              formulas.add([
                participantNameReference,
                competitorARef,
                competitorBRef,
                '"${battleTypeToString[type]}"',
                resultRef,
                roundRef,
                '$roundRow',
                '$roundColumn'
              ]);
              roundRef = null;
            }
            break;
          case winnerRoundColor:
          case loserRoundColor:
          case bonusRoundColor:
            if (color == winnerRoundColor) type = BattleType.winner;
            if (color == loserRoundColor) type = BattleType.loser;
            if (color == bonusRoundColor) type = BattleType.bonus;

            roundRef = ref(i, j);
            roundRow = i + 1;
            roundColumn = j + 1;
            resultRef = ref(i, j + 1);
            break;
        }
      }
    }
  }
  var maxRows = cacheSheet.getMaxRows();
  if (maxRows < formulas.length) {
    cacheSheet.insertRows(maxRows - 1, (formulas.length - maxRows));
  }
  var range = cacheSheet.getRange(1, 1, formulas.length, formulas.first.length);
  range.setFormulas(formulas);
}
