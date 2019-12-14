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

import 'dart:math' as math;

import 'config.dart';
import 'cache.dart';
import 'utils.dart';

import 'package:google_apps/google_apps.dart';

/// Creates (or replaces) a sheet with brackets for the selected participant.
///
/// This function is primarily used when new participants join at a later moment.
void createBracketForSelectedDart() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(configSheetName);
  // Returns the active cell
  var cell = sheet.getActiveCell();
  var participant = cell.getValue();
  createBracketFor(participant);
  rebuildCacheDart();
}

/// Creates (or replaces) a sheet with brackets for all participants.
void createBracketForAllDart() {
  allParticipants.forEach(createBracketFor);
  rebuildCacheDart();
}

/// Deletes all bracket sheets.
///
/// This function uses the participant names to find the sheets. As a
/// consequence, removing participants from the list before invoking this
/// function would not remove their bracket sheets.
///
/// This function is mostly useful for development.
void deleteAllBracketSheetsDart() {
  var participants = allParticipants;
  var ss = SpreadsheetApp.getActiveSpreadsheet();

  for (var participant in participants) {
    var name = sheetNameFromParticipant(participant);
    var sheet = ss.getSheetByName(name);
    if (sheet != null) ss.deleteSheet(sheet);
  }
  var cacheSheet = ss.getSheetByName(cacheSheetName);
  if (cacheSheet != null) ss.deleteSheet(cacheSheet);
}

void createBracketFor(String participant) {
  var participants = allParticipants;
  if (!participants.contains(participant)) {
    error('Not a valid participant: $participant');
  }

  var sheet = _createParticipantSheet(participant);
  _fillWithBrackets(sheet, participant);
}

/// The location of the name of the participant, used to find the corresponding
/// battle-results in the results-sheet.
const String participantLocation = r'$B$1';

/// Creates a fresh sheet for the given participant.
///
/// If a sheet already exists overwrites it.
Sheet _createParticipantSheet(String participant) {
  var sheetName = sheetNameFromParticipant(participant);
  var activeSpreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = activeSpreadsheet.getSheetByName(sheetName);

  // Remove it first, if it already exists.
  if (sheet != null) activeSpreadsheet.deleteSheet(sheet);

  sheet = activeSpreadsheet.insertSheet();
  sheet.setName(sheetName);
  sheet.getRange(participantLocation).offset(0, -1).setValue('Participant:');
  sheet.getRange(participantLocation).setValue(participant);
  return sheet;
}

/// Fills the given sheet with a new bracket.
///
/// Depending on the [isDoubleElimination] the generated sheets will be
/// double elimination or not.
///
/// If only some participants want to do double-elimination, then it is safe
/// to delete the double-elimination entries from the sheet *and* then to
/// rebuild the cache.
///
/// This code was inspired by
///   [https://developers.google.com/apps-script/articles/bracket_maker]
void _fillWithBrackets(Sheet sheet, String participant) {
  var competitorNames = allCompetitors;
  var competitorCount = competitorNames.length;
  var competitorsRange = competitorsConfig.range;
  var competitorsColumnANotation =
      String.fromCharCode('A'.codeUnitAt(0) + competitorsRange.getColumn() - 1);
  var competitorsRow = competitorsRange.getRow();

  if (competitorCount < 3) {
    error('You must have at least 3 competitors.');
  }

  var competitorIndices =
      List<int>.generate(competitorCount, (x) => x).toList();

  var upperPower = (math.log(competitorCount) / math.ln2).ceil();

  // Find out what is the number that is a power of 2 and lower than
  // numCompetitors.
  var withByesCount = math.pow(2, upperPower);

  competitorIndices.shuffle();

  if (competitorCount < withByesCount) {
    // Fill with Byes.
    var missing = withByesCount - competitorCount;
    var newCompetitorIndices = <int>[];

    var remainingCompetitors = competitorCount;

    // We are avoiding having two pairings containing a bye next to each
    // other, as the byes would meet in the loser-bracket.
    var lastContainedBye = false;
    for (var i = 0; i < withByesCount ~/ 2; i++) {
      if (!lastContainedBye && missing > 0 || missing == remainingCompetitors) {
        newCompetitorIndices.add(-1);
        newCompetitorIndices.add(competitorIndices[--remainingCompetitors]);
        missing--;
        lastContainedBye = true;
      } else {
        newCompetitorIndices.add(competitorIndices[--remainingCompetitors]);
        newCompetitorIndices.add(competitorIndices[--remainingCompetitors]);
        lastContainedBye = false;
      }
    }
    competitorIndices = newCompetitorIndices.reversed.toList();
  }

  // Enter the competitors for the 1st round
  var cells = <_SheetCell>[];
  for (var i = 0; i < competitorIndices.length; i++) {
    var competitorIndex = competitorIndices[i];
    String formula;
    if (competitorIndex != -1) {
      formula = '=$configSheetName!'
          '\$$competitorsColumnANotation'
          '\$${competitorsRow + competitorIndex}';
    }
    var row = 3 + i * 2;
    var cell = _SheetCell(sheet, row, 1,
        isBye: competitorIndex == -1, formula: formula);
    cells.add(cell);
  }

  // Connects the given list of cells and connects them pairwise.
  //
  // Returns two lists: one with the cells of all winners, and one
  //   for all the losers. The loser cells don't have any position yet, and
  //   can be discarded. For example, the loser-bracket doesn't care for
  //   any losers anymore. Similarly, losers are always discarded, if there is
  //   no double-elimination.
  List<List<_SheetCell>> connectAll(List<_SheetCell> cells,
      {bool isWinnerBracket}) {
    var winners = <_SheetCell>[];
    var losers = <_SheetCell>[];
    for (var i = 0; i < cells.length; i += 2) {
      var cellA = cells[i];
      var cellB = cells[i + 1];
      var winnerLoser =
          cellA.connectTo(cellB, isWinnerBracket: isWinnerBracket);
      winners.add(winnerLoser[0]);
      losers.add(winnerLoser[1]);
    }
    return [winners, losers];
  }

  var winners = cells;
  var allLosers = <List<_SheetCell>>[];
  while (winners.length > 1) {
    var winnersLosers = connectAll(winners, isWinnerBracket: true);
    winners = winnersLosers[0];
    allLosers.add(winnersLosers[1]);
  }

  if (!isDoubleElimination) return;

  // 2 for the header, and 3 to have some space.
  var loserPos = competitorIndices.length * 2 + 6;

  var losersIndex = 0;
  var firstRoundLosers = allLosers[losersIndex++];
  // Sets the positions of the losers.
  for (var i = 0; i < firstRoundLosers.length; i += 2) {
    // Add 3 for the incoming loser from phase 2.
    loserPos += 3;

    firstRoundLosers[i] = firstRoundLosers[i].withPos(loserPos, 1);
    loserPos += 2;

    firstRoundLosers[i + 1] = firstRoundLosers[i + 1].withPos(loserPos, 1);
    loserPos += 2;
  }

  var shouldDoubleUp = false;
  var shouldInvertIncoming = true;
  var losers = firstRoundLosers;
  var previousLosers;
  while (losers.length > 1 || shouldDoubleUp) {
    if (shouldDoubleUp) {
      var newLosers = <_SheetCell>[];
      var incoming = allLosers[losersIndex++];
      if (shouldInvertIncoming) {
        incoming = incoming.reversed.toList();
      }
      shouldInvertIncoming = !shouldInvertIncoming;
      for (var i = 0; i < losers.length; i++) {
        // We use the positions of the previous phase to compute the
        // position of the incoming losers.
        var previousLoser = previousLosers[i * 2];
        // Introduce a new competitor (coming from the winner's bracket).
        var incomingCell = incoming[i]
            .withPos(previousLoser.row - 2, previousLoser.column + 2);
        newLosers.add(incomingCell);
        newLosers.add(losers[i]);
      }
      losers = newLosers;
    }
    shouldDoubleUp = !shouldDoubleUp;
    // Keep track of the previous losers to make it easier to compute the
    // position of incoming losers.
    previousLosers = losers;
    var winnersLosers = connectAll(losers, isWinnerBracket: false);
    // The winners advance. The losers are out now.
    losers = winnersLosers[0];
  }

  // Create a final pairing between the winner's and loser's bracket winners.
  var winnersWinner = winners[0];
  var losersWinner = losers[0];
  var column = winnersWinner.column + 2;
  var winnersRef = winnersWinner._a1Notation;
  var losersRef = losersWinner._a1Notation;
  var cellA = _SheetCell(sheet, 3, column, formula: '=$winnersRef');
  var cellB = _SheetCell(sheet, 5, column, formula: '=$losersRef');
  cellA.connectTo(cellB, isWinnerBracket: true);
}

/// A cell in the participant's sheet.
///
/// When building the bracket, we use this class to refer to already
/// generated cells.
class _SheetCell {
  final Sheet sheet;
  final int row;
  final int column;

  /// Whether this cell is a bye.
  final bool isBye;

  /// A position-independent formula (which means that we can write at any
  /// place in the sheet).
  final String formula;

  _SheetCell(this.sheet, this.row, this.column,
      {this.formula, this.isBye = false});

  _SheetCell withPos(int row, int column) {
    return _SheetCell(sheet, row, column, formula: formula, isBye: isBye);
  }

  Range get _range => sheet.getRange(row, column);

  String get _a1Notation => _range.getA1Notation();

  /// Writes the cells data into the sheet.
  void markActive() {
    _range.setFormula(formula);
    _range.setBackground(competitorColor);
  }

  /// Connects this cell to [cell2].
  ///
  /// Returns two cells.
  /// The first entry is the winner-cell. The second, the loser cell *without*
  /// the correct location.
  ///
  /// The loser cell is only relevant for double-elimination tournaments.
  List<_SheetCell> connectTo(_SheetCell cell2, {bool isWinnerBracket}) {
    assert(column == cell2.column);
    var newRow = (row + cell2.row) ~/ 2;
    if (isBye && cell2.isBye) {
      var winner = _SheetCell(sheet, newRow, column + 2, isBye: true);
      var loser = _SheetCell(sheet, -1, -1, isBye: true);
      return [winner, loser];
    } else if (isBye || cell2.isBye) {
      var dataCell = isBye ? cell2 : this;
      var winner =
          _SheetCell(sheet, newRow, column + 2, formula: dataCell.formula);
      var loser = _SheetCell(sheet, -1, -1, isBye: true);
      return [winner, loser];
    } else {
      markActive();
      cell2.markActive();
      var fromRow = row;
      var toRow = cell2.row;
      var connector =
          sheet.getRange(fromRow, column + 1, toRow - fromRow + 1, 1);
      sheet.setColumnWidth(connector.getColumn(), connectorWidth);
      connector.setBackground(connectorColor);
      var outcomeCell = sheet.getRange(newRow, column + 1);
      outcomeCell.setFormula(_outcomeFormula);
      var roundCell = sheet.getRange(newRow, column);
      roundCell
          .setBackground(isWinnerBracket ? winnerRoundColor : loserRoundColor);
      var winnerFormula =
          computeNextRoundCompetitorFormula(this, cell2, outcomeCell);
      var winner =
          _SheetCell(sheet, newRow, column + 2, formula: winnerFormula);
      winner.markActive();
      var loserFormula = computeNextRoundCompetitorFormula(
          this, cell2, outcomeCell,
          invert: true);
      var loser = _SheetCell(sheet, newRow, column + 2, formula: loserFormula);
      return [winner, loser];
    }
  }

  /// Creates the formula that queries the results sheet for the result
  /// of this battle.
  ///
  /// If a result is available writes "A" or "B" into the cell.
  String get _outcomeFormula {
    var participant = participantLocation;
    var query = '"select $resultsWinColumn '
        '''where $resultsParticipantColumn = '"&$participant&"' and '''
        '$resultsRoundColumn = "&INDIRECT("R[0]C[-1]", false)';
    return '=IFERROR(QUERY($resultsQualifiedRange, $query))';
  }

  /// Computes the formula that finds the competitor for the next round, using
  /// the found outcome (see [_outcomeFormula]).
  String computeNextRoundCompetitorFormula(
      _SheetCell cellA, _SheetCell cellB, Range outcomeCell,
      {bool invert = false}) {
    var outcome = outcomeCell.getA1Notation();
    var a = cellA._a1Notation;
    var b = cellB._a1Notation;

    if (invert) {
      return '=IFS($outcome = "", "", $outcome = "A", $b, $outcome = "B", $a)';
    }
    return '=IFS($outcome = "", "", $outcome = "A", $a, $outcome = "B", $b)';
  }
}
