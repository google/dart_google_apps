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
import 'package:ranking/ranking.dart';

// Used both as target for the menu and the callback from the selection sidebar.
void generateFinalReportsDart([List selectedParticipants]) {
  if (selectedParticipants == null) {
    // Menu click
    var html = StringBuffer();
    html.write('<html><body>');
    html.write(
        "<input type='button' onclick='selectAll()' value='Select All' />");
    html.write(
        "<input type='button' onclick='selectNone()' value='Select None' />");

    for (var participant in allParticipants) {
      var participantName = normalizeName(participant);
      var escapedParticipant = htmlEscape.convert(participant);
      var escapedParticipantName = htmlEscape.convert(participantName);
      html.write('<div><input '
          "name='participantCheckBox' "
          "value='$escapedParticipant' "
          "type='checkbox' />"
          '<label>$escapedParticipantName</label>'
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
      google.script.run.withSuccessHandler(close).generateFinalReports(result);
      return false;
    }
    function selectAll() {
      var checkBoxes = document.querySelectorAll('input[name=participantCheckBox]');
      for (var i = 0; i < checkBoxes.length; i++) {
        checkBoxes[i].checked = true;
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
    userInterface.setTitle('Final Reports');
    SpreadsheetApp.getUi().showSidebar(userInterface);
    return;
  }
  // Callback from sidebar.
  var spreadsheet = SpreadsheetApp.getActiveSpreadsheet();

  var activeSet = Set<String>.from(activeParticipants);
  var allPairings = computeAllPairings();
  var urls = urlMapping;
  var participantStates = <String, State>{};
  for (var participant in selectedParticipants) {
    var pairings = allPairings[participant];
    var isActive = activeSet.contains(participant);
    participantStates[participant] =
        State(participant, isActive, urls[participant], pairings);
  }

  var responses = readResponses();

  combineStatesAndResponses(participantStates.values.toList(), responses);

  // Might require more permissions: https://developers.google.com/apps-script/concepts/scopes
  var folder =
      DriveApp.getRootFolder().createFolder('Final Report - ${DateTime.now()}');

  for (var participant in selectedParticipants) {
    var participantName = normalizeName(participant);
    var name = sheetNameFromParticipant(participant);
    var sheet = spreadsheet.getSheetByName(name);
    var data = sheet.getDataRange().getValues();

    var individualReportSpreadsheet = SpreadsheetApp.create(participantName);
    moveFileToFolder(individualReportSpreadsheet, folder);
    var tmpSheet = individualReportSpreadsheet.getSheets()[0];
    var individualSheet = sheet.copyTo(individualReportSpreadsheet);
    individualSheet.setName(sheet.getName());
    individualSheet.getRange(1, 1, data.length, data[0].length).setValues(data);
    individualReportSpreadsheet.deleteSheet(tmpSheet);

    var state = participantStates[participant];
    var pairings = state.allPairings.toList();
    pairings.sort((a, b) => a.round.compareTo(b.round));

    for (var pairing in pairings) {
      var response = pairing.response;
      if (response == null) continue;
      if (response.aComment == '' && response.bComment == '') {
        continue;
      }

      var text = '';
      if (response.aComment != '') {
        text += '\nA: ${response.aComment}';
      }
      if (response.bComment != '') {
        text += '\nB: ${response.bComment}';
      }

      individualSheet
          .getRange(pairing.row, pairing.column, 1, 1)
          .setNote(text.trim());
    }
  }

  var id = folder.getId();
  var html = """
  <html><body>
  <div>Created a <A href='https://docs.google.com/drive/folders/$id' target='_blank'>folder</A>.</div>
  <input type='button' onclick=' google.script.host.close()' value='OK' />
  </body></html>
  """;
  var userInterface = HtmlService.createHtmlOutput(html.toString());
  SpreadsheetApp.getUi().showModalDialog(userInterface, 'Final Reports Ready');
}

Map<String, double> get rankedCompetitors {
  print('1');
  var competitors = allCompetitors;
  print('2');

  var pairings = computeAllPairings();
  print('3');

  var games = <List<String>>[];

  for (var pairs in pairings.values) {
    for (var pair in pairs) {
      if (!pair.hasResult) continue;
      if (pair.result == 'A') {
        games.add([pair.competitorA, pair.competitorB]);
      } else {
        games.add([pair.competitorB, pair.competitorA]);
      }
    }
  }

  var scores = computeBradleyTerryScores(games);
  var ranked = competitors.toList()
    ..sort((a, b) {
      var scoreA = scores[a] ?? 0;
      var scoreB = scores[b] ?? 0;
      return -scoreA.compareTo(scoreB);
    });
  var result = <String, double>{};
  for (var competitor in ranked) {
    result[competitor] = scores[competitor] ?? 0;
  }
  return result;
}

// Used both as target for the menu and the callback from the selection sidebar.
void generateCompetitorReportsDart([List selectedCompetitors]) {
  if (selectedCompetitors == null) {
    // Menu click
    var html = StringBuffer();
    html.write('<html><body>');
    html.write(
        "<input type='button' onclick='selectAll()' value='Select All' />");
    html.write(
        "<input type='button' onclick='selectNone()' value='Select None' />");

    for (var competitor in rankedCompetitors.keys) {
      var escapedCompetitor = htmlEscape.convert(competitor);
      html.write('<div><input '
          "name='competitorCheckBox' "
          "value='$escapedCompetitor' "
          "type='checkbox' />"
          '<label>$escapedCompetitor</label>'
          '</div>');
    }
    html.write(
        "<input type='button' onclick='submitChecked()' value='Submit' />");
    html.write("""<script>
    function submitChecked() {
      var result = [];
      var checkedBoxes = document.querySelectorAll('input[name=competitorCheckBox]:checked');
      for (var i = 0; i < checkedBoxes.length; i++) {
        result.push(checkedBoxes[i].value);
      }
      google.script.run.withSuccessHandler(close).generateCompetitorReports(result);
      return false;
    }
    function selectAll() {
      var checkBoxes = document.querySelectorAll('input[name=competitorCheckBox]');
      for (var i = 0; i < checkBoxes.length; i++) {
        checkBoxes[i].checked = true;
      }
    }
    function selectNone() {
      var checkBoxes = document.querySelectorAll('input[name=competitorCheckBox]');
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
    userInterface.setTitle('Competitor Reports');
    SpreadsheetApp.getUi().showSidebar(userInterface);
    return;
  }
  // Callback from sidebar.

  var activeSet = Set<String>.from(allCompetitors);
  var urls = urlMapping;
  var allPairings = computeAllPairings();
  var allStates = allParticipants.map((participant) {
    var pairings = allPairings[participant];
    var isActive = activeSet.contains(participant);
    return State(participant, isActive, urls[participant], pairings);
  }).toList();

  var responses = readResponses();

  combineStatesAndResponses(allStates, responses);

  // Map from competitor to all responses for each participant.
  var collectedResponses = <String, Map<String, List<Response>>>{};

  for (var response in responses) {
    var perCompetitor =
        collectedResponses.putIfAbsent(response.competitorA, () => {});
    perCompetitor.putIfAbsent(response.participant, () => []).add(response);
    perCompetitor =
        collectedResponses.putIfAbsent(response.competitorB, () => {});
    perCompetitor.putIfAbsent(response.participant, () => []).add(response);
  }

  // Might require more permissions: https://developers.google.com/apps-script/concepts/scopes
  var document = DocumentApp.create('Report - ${DateTime.now()}');
  var body = document.getBody();

  var isFirst = true;
  for (String competitor in selectedCompetitors) {
    Paragraph paragraph;
    if (isFirst) {
      isFirst = false;
      // Reuse already existing paragraph.
      paragraph = body.getChild(0);
    } else {
      paragraph = body.appendParagraph('');
    }
    paragraph.setText(competitor);
    paragraph
        .setAlignment(DocumentApp.HorizontalAlignment.CENTER)
        .setHeading(DocumentApp.ParagraphHeading.TITLE);

    void writeComments(Response response) {
      var participantName = normalizeName(response.participant);
      String comment;
      bool wasWinner;
      if (competitor == response.competitorA) {
        comment = response.aComment;
        wasWinner = response.result == 'A';
      } else {
        comment = response.bComment;
        wasWinner = response.result == 'B';
      }
      if (comment != '') {
        var winnerTag = wasWinner ? ' (W)' : '';
        body
            .appendParagraph('$participantName$winnerTag: $comment')
            .editAsText()
            .setBold(0, participantName.length, true);
      }
    }

    var participantResponses = collectedResponses[competitor];
    if (participantResponses != null) {
      participantResponses.forEach((_, responses) {
        responses.forEach(writeComments);
      });
    }

    body.appendPageBreak();
  }

  var id = document.getId();
  var html = """
  <html><body>
  <div>Created a <A href='https://docs.google.com/document/d/$id' target='_blank'>document</A>.</div>
  <input type='button' onclick=' google.script.host.close()' value='OK' />
  </body></html>
  """;
  var userInterface = HtmlService.createHtmlOutput(html.toString());
  SpreadsheetApp.getUi().showModalDialog(userInterface, 'Reports Ready');
}

void competitorRankingDart() {
  var ranked = rankedCompetitors;
  var table = [];
  ranked.forEach((name, score) {
    table.add([name, (score * 1000).toStringAsFixed(3)]);
  });

  var html = StringBuffer();
  html.writeln('<html><body>');
  html.writeln('<table>');
  html.writeln('<tr><th>Competitor</th><th>Bradley-Terry Score</th></tr>');
  table.forEach((entry) {
    html.writeln('<tr>');
    html.write('<td>');
    html.write(entry[0]);
    html.write('</td>');
    html.write('<td>');
    html.write(entry[1]);
    html.write('</td>');
    html.writeln('</tr>');
  });
  html.writeln('</table>');
  html.write('</body></html>');
  var userInterface = HtmlService.createHtmlOutput(html.toString());
  userInterface.setTitle('Ranking');
  SpreadsheetApp.getUi().showModalDialog(userInterface, 'Competitor Ranking');
}
