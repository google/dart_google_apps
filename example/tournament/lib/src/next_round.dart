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

import 'dart:convert';

import 'config.dart';
import 'tournament.dart';
import 'utils.dart';

import 'package:google_apps/google_apps.dart';

/// Computes the percentage of how often 'A' was picked for the given pairings.
///
/// Returns -1, if there is no completed battle.
///
/// This stat is only useful if participants taste the competitors in a
/// specific order ("A" first).
int computeAPercentage(List<Pairing> pairings) {
  var selectedACount = 0;
  var completedPairingsCount = 0;
  for (var pairing in pairings) {
    var result = pairing.result;
    if (result != null) {
      completedPairingsCount++;
      if (result == 'A') selectedACount++;
    }
  }
  if (completedPairingsCount == 0) return -1;
  return selectedACount * 100 ~/ completedPairingsCount;
}

/// Computes the percentage of how often 'A' was picked for all pairings.
///
/// Returns -1, if there is no completed battle.
///
/// This stat is only useful if participants taste the competitors in a
/// specific order ("A" first).
int computeTotalAPercentage(List<List<Pairing>> allPairings) {
  var selectedACount = 0;
  var completedPairingsCount = 0;
  for (var pairings in allPairings) {
    for (var pairing in pairings) {
      var result = pairing.result;
      if (result != null) {
        completedPairingsCount++;
        if (result == 'A') selectedACount++;
      }
    }
  }
  if (completedPairingsCount == 0) return -1;
  return selectedACount * 100 ~/ completedPairingsCount;
}

/// Computes the ids of participants for the selection-buttons.
///
/// When preparing a new round, we allow the administrator to select
/// participants that are behind, or that do double-elimination.
///
/// We compute these ids here and return them in a list:
/// - the first entry of the returned list contains the participants that are
///   behind. That is, participants that have played fewer rounds than other
///   participants.
/// - the second entry contains the participants that play double-elimination.
///   When not all participants do the same
List<List<int>> computeSelections(List<State> states) {
  var behindParticipants = <int>{};
  var doubleEliminationParticipants = <int>[];

  var maxWinnerRounds = 0;
  var maxLoserRounds = 0;
  for (var i = 0; i < states.length; i++) {
    var state = states[i];
    if (state.playedWinnersCount < maxWinnerRounds ||
        state.playedLosersCount < maxLoserRounds) {
      behindParticipants.add(i);
    }

    if (state.playedWinnersCount > maxWinnerRounds) {
      maxWinnerRounds = state.playedWinnersCount;
      // All participants so far are behind.
      for (var j = 0; j < i; j++) {
        behindParticipants.add(j);
      }
      if (maxLoserRounds < state.playedLosersCount) {
        maxLoserRounds = state.playedLosersCount;
      }
    }
    if (state.playedLosersCount > maxLoserRounds) {
      maxLoserRounds = state.playedLosersCount;
      // Insert all existing doubleEliminationParticipants in the behind list.
      behindParticipants.addAll(doubleEliminationParticipants);
    }
    if (state.hasLoserBracket) {
      doubleEliminationParticipants.add(i);
    }
  }
  return [behindParticipants.toList()..sort(), doubleEliminationParticipants];
}

/// Prepares the next round.
///
/// This function is called in two different ways:
/// 1. from the menu, which opens a side-bar.
/// 2. as a callback from the side-bar.
void prepareNextRoundDart([List userData]) {
  if (userData == null) {
    // Menu click.
    openNextRoundWindow();
  } else {
    // Callback from the opened window.
    createNextRoundDocument(userData);
  }
}

/// Opens a side-bar with the participants.
///
/// The administrator can then select the active participants. The callback
/// of the window then invokes [prepareNextRoundDart] again, which then
/// creates the documents for the next round.
void openNextRoundWindow() {
  var participants = activeParticipants;
  var urls = urlMapping;

  var allPairings = computeAllPairings();

  var states = participants.map((participant) {
    var pairings = allPairings[participant];
    var isActive = true;
    return State(participant, isActive, urls[participant], pairings);
  }).toList();

  var totalPlayed = 0;
  var totalASelected = 0;
  for (var state in states) {
    totalPlayed += state.finishedCount;
    totalASelected += state.aSelectionCount;
  }
  var totalAPercentage = -1;
  if (totalPlayed != 0) {
    totalAPercentage = 100 * totalASelected ~/ totalPlayed;
  }

  var selections = computeSelections(states);

  var behindSelection = selections[0];
  var doubleEliminationSelection = selections[1];

  var html = StringBuffer();
  html.write('<html><body>');
  html.write("<input type='button' "
      "onclick='selectAll()' "
      "value='Select All' />"
      '<br>');
  if (doubleEliminationSelection.isNotEmpty) {
    html.write("<input type='button' "
        "onclick='selectDoubleElimination()' "
        "value='Select Double Elimination' />"
        '<br>');
  }
  html.write("<input type='button' "
      "onclick='selectBehind()' "
      "value='Select Behind' />"
      '<br>');
  html.write("<input type='button' "
      "onclick='selectNone()' "
      "value='Select None' />"
      '<br>');

  for (var i = 0; i < states.length; i++) {
    var state = states[i];
    var isEnabled = state.isActive &&
        (state.availableWinnerPairings.isNotEmpty ||
            state.availableLoserPairings.isNotEmpty);
    var participant = state.participant;
    var participantName = state.participantName;
    var checkBoxValue = json.encode(participant);
    var playedWinnersCount = state.playedWinnersCount;
    var playedLosersCount = state.playedLosersCount;
    var playedCount = playedWinnersCount + playedLosersCount;
    var hasLoserBracket = state.hasLoserBracket;

    var countSuffix = '$playedCount';
    if (hasLoserBracket) {
      countSuffix += ' ($playedWinnersCount | $playedLosersCount)';
    }
    var missing = state.missingResults;
    var missingSuffix = missing.isEmpty ? '' : ' - [${missing.join(', ')}]';
    var suffix = '$countSuffix$missingSuffix';
    var escapedParticipantName = htmlEscape.convert(participantName);
    var escapedCheckBoxValue = htmlEscape.convert(checkBoxValue);
    html.write('<div><input '
        "name='participantCheckBox' "
        "value='$escapedCheckBoxValue' "
        '${isEnabled ? '' : 'disabled=true '}'
        "type='checkbox' />"
        '<label>$escapedParticipantName - $suffix</label>'
        '</div>');
  }
  html.write(
      "<input type='button' onclick='submitChecked()' value='Submit' />");
  html.write("""<script>
  function submitChecked() {
    var result = [];
    var checkedBoxes = document.querySelectorAll('input[name=participantCheckBox]:checked');
    for (var i = 0; i < checkedBoxes.length; i++) {
      result.push(checkedBoxes[i].value);
    }
    result.push($totalAPercentage);
    google.script.run.withSuccessHandler(close).prepareNextRound(result);
    return false;
  }
  function selectAll() {
    var checkBoxes = document.querySelectorAll('input[name=participantCheckBox]');
    for (var i = 0; i < checkBoxes.length; i++) {
      if (!checkBoxes[i].disabled) checkBoxes[i].checked = true;
    }
  }
  function selectBehind() {
    selectNone();
    var behind = $behindSelection;
    var checkBoxes = document.querySelectorAll('input[name=participantCheckBox]');
    for (var i = 0; i < behind.length; i++) {
      var index = behind[i];
      if (!checkBoxes[index].disabled) checkBoxes[index].checked = true;
    }
  }
  function selectDoubleElimination() {
    selectNone();
    var doubleElimination = $doubleEliminationSelection;
    var checkBoxes = document.querySelectorAll('input[name=participantCheckBox]');
    for (var i = 0; i < doubleElimination.length; i++) {
      var index = doubleElimination[i];
      if (!checkBoxes[index].disabled) checkBoxes[index].checked = true;
    }
  }
  function selectNone() {
    var checkBoxes = document.querySelectorAll('input[name=participantCheckBox]');
    for (var i = 0; i < checkBoxes.length; i++) {
      checkBoxes[i].checked = false;
    }
  }
  function close() {
    google.script.host.close();
  }
  </script>""");

  html.write('</body></html>');
  var userInterface = HtmlService.createHtmlOutput(html.toString());
  userInterface.setTitle('Next Round');
  SpreadsheetApp.getUi().showSidebar(userInterface);
}

/// Finds the next pairing.
///
/// The pairings in a state are sorted lower rounds first, top-to-bottom.
///
/// This method only needs to decide whether to pick a winner or loser bracket
/// pairing. We pick loser bracket, unless there are winner brackets that feed
/// into the unplayed loser-bracket column.
Pairing findBestNextPairing(State state) {
  var winnerPairings = state.availableWinnerPairings;
  var loserPairings = state.availableLoserPairings;

  if (winnerPairings.isEmpty) return loserPairings.first;
  if (loserPairings.isEmpty) return winnerPairings.first;

  var winnerColumn = winnerPairings.first.column;
  var loserColumn = loserPairings.first.column;
  if (winnerColumn == 0) return winnerPairings.first;
  if (loserColumn == 0) return loserPairings.first;
  if ((loserColumn - 1) < (winnerColumn - 2) * 2) return loserPairings.first;
  return winnerPairings.first;
}

void createNextRoundDocument(List userData) {
  // Might require more permissions: https://developers.google.com/apps-script/concepts/scopes
  var document = DocumentApp.create('round - ${DateTime.now()}');
  var body = document.getBody();

  var isFirst = true;
  var totalAPercentage = userData.last;
  var checkBoxValues = userData.sublist(0, userData.length - 1);
  if (checkBoxValues.isEmpty) return;

  var selectedParticipants =
      checkBoxValues.map((x) => x as String).map(json.decode).toList();
  var urls = urlMapping;
  var allPairings = computeAllPairings();
  var states = selectedParticipants.map((participant) {
    var isActive = true;
    return State(
        participant, isActive, urls[participant], allPairings[participant]);
  }).toList();

  var leftIndex = 0;
  var rightIndex = (states.length + 1) ~/ 2;
  var lastPageTable = List<List<String>>(states.length);

  for (var j = 0; j < states.length; j++) {
    var i = j;
    if (isPrinting2PagesPerSheet) {
      // We reorder the pages so that we can cut in the middle and then
      // put the two piles of papers on top of each other while still having
      // the order we want.
      if (j.isEven) {
        i = leftIndex++;
      } else {
        i = rightIndex++;
      }
    }
    var state = states[i];
    var participant = state.participantName;
    var selectedPairing = findBestNextPairing(state);
    var row = selectedPairing.row;
    var column = selectedPairing.column;
    var competitorA = selectedPairing.competitorA;
    var competitorB = selectedPairing.competitorB;
    var roundNumber = state.nextRoundNumber;
    var missingResults = state.missingResults;
    var selectedAPercentage = state.finishedCount == 0
        ? -1
        : 100 * state.aSelectionCount ~/ state.finishedCount;

    var inTestMode = false;
    if (inTestMode) {
      body.appendParagraph('IN TEST MODE. NOT SETTING THE SHEET');
    } else {
      var sheetName = sheetNameFromParticipant(participant);
      SpreadsheetApp.getActiveSpreadsheet()
          .getSheetByName(sheetName)
          .getRange(row, column)
          .setValue(roundNumber);
    }

    Paragraph paragraph;
    if (isFirst) {
      isFirst = false;
      // Reuse already existing paragraph.
      paragraph = body.getChild(0);
    } else {
      paragraph = body.appendParagraph('');
    }
    paragraph.setText('$participant - $roundNumber');
    paragraph
        .setAlignment(DocumentApp.HorizontalAlignment.CENTER)
        .editAsText()
        .setFontSize(32);
    body.appendParagraph(state.url).editAsText().setFontSize(20);
    if (missingResults.isNotEmpty) {
      body.appendParagraph('Missing results for: ${missingResults.join(', ')}');
    }
    if (selectedAPercentage != -1) {
      body
          .appendParagraph('Your A-percentage: $selectedAPercentage%')
          .editAsText()
          .setFontSize(12);
    }
    if (totalAPercentage != -1) {
      body
          .appendParagraph('Total A-percentage: $totalAPercentage%')
          .editAsText()
          .setFontSize(12);
    }
    var table = body.appendTable([
      ['A', 'B']
    ]);
    table.setBorderColor('#ffffff');
    Paragraph cellA = table.getCell(0, 0).getChild(0);
    Paragraph cellB = table.getCell(0, 1).getChild(0);
    cellA
        .setAlignment(DocumentApp.HorizontalAlignment.LEFT)
        .editAsText()
        .setFontSize(27);
    cellB
        .setAlignment(DocumentApp.HorizontalAlignment.RIGHT)
        .editAsText()
        .setFontSize(27);
    body.appendPageBreak();
    lastPageTable[i] = [participant, competitorA, competitorB];
  }
  if (states.length.isEven && isPrinting2PagesPerSheet) {
    // Add an empty page to move the table to the right side.
    body.appendPageBreak();
  }
  // Add a small paragraph, to reset the default font size.
  body.appendParagraph('').editAsText().setFontSize(12);
  body.appendTable(lastPageTable);

  var id = document.getId();
  var html = """
  <html><body>
  <div>Created a <A href='https://docs.google.com/document/d/$id' target='_blank'>document</A>.</div>
  <input type='button' onclick=' google.script.host.close()' value='OK' />
  </body></html>
  """;
  var userInterface = HtmlService.createHtmlOutput(html.toString());
  SpreadsheetApp.getUi().showModalDialog(userInterface, 'Next Round Ready');
}
