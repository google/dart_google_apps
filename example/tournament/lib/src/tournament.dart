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
import 'utils.dart';

import 'package:google_apps/google_apps.dart';

enum BattleType {
  winner,
  loser,
  bonus,
}

const battleTypeToString = {
  BattleType.winner: 'winner',
  BattleType.loser: 'loser',
  BattleType.bonus: 'bonus',
};
const stringToBattleType = {
  'winner': BattleType.winner,
  'loser': BattleType.loser,
  'bonus': BattleType.bonus,
};

int compareBattleTypes(BattleType a, BattleType b) {
  if (a == b) return 0;
  if (a == BattleType.winner) return 1;
  if (b == BattleType.winner) return -1;
  if (a == BattleType.loser) return 1;
  return -1;
}

void combineStatesAndResponses(List<State> states, List<Response> responses) {
  // Per participant and indexed by round number.
  var structured = <String, Map<int, Response>>{};
  for (var response in responses) {
    var perParticipant = structured.putIfAbsent(response.participant, () => {});
    perParticipant[response.roundNumber] = response;
  }

  for (var state in states) {
    var participant = state.participant;

    for (var pairing in state.allPairings) {
      if (pairing.hasResult) {
        var response = structured[participant][pairing.round];
        response.competitorA = pairing.competitorA;
        response.competitorB = pairing.competitorB;
        pairing.response = response;
      }
    }
  }
}

class Response {
  final String participant;
  final int roundNumber;
  final String result;
  final String aComment;
  final String bComment;

  /// [competitorA] and [competitorB] are not set automatically.
  ///
  /// Use [combineStatesAndResponses] to fill them.
  String competitorA;
  String competitorB;

  Response(this.participant, this.roundNumber, this.result, this.aComment,
      this.bComment);

  String get winnerComment => result == 'A' ? aComment : bComment;

  String get loserComment => result == 'A' ? bComment : aComment;

  String get winner => result == 'A' ? competitorA : competitorB;

  String get loser => result == 'A' ? competitorB : competitorA;
}

List<Response> readResponses() {
  var spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  var responsesSheet = spreadsheet.getSheetByName(resultsSheetName);
  var entries = responsesSheet.getDataRange().getValues().cast<List>();

  int toIndex(String columnDescription) =>
      columnDescription.codeUnitAt(0) - 'A'.codeUnitAt(0);

  var participantIndex = toIndex(resultsParticipantColumn);
  var roundIndex = toIndex(resultsRoundColumn);
  var resultIndex = toIndex(resultsWinColumn);
  var commentAIndex = toIndex(resultsCommentsAColumn);
  var commentBIndex = toIndex(resultsCommentsBColumn);
  // Skip the header row.
  return entries.skip(1).map((List row) {
    return Response(row[participantIndex], row[roundIndex], row[resultIndex],
        row[commentAIndex], row[commentBIndex]);
  }).toList();
}

class Pairing implements Comparable<Pairing> {
  /// The row of the round-number.
  final int row;

  /// The column of the round-number.
  final int column;
  final String competitorA;
  final String competitorB;
  final BattleType type;

  /// -1 if the round hasn't been run yet.
  final int round;

  // Either "A", "B" or null.
  final String result;

  /// This field isn't set automatically. Use [combineStatesAndResponses] to
  /// fill it.
  Response response;

  Pairing(this.row, this.column, this.competitorA, this.competitorB,
      {this.type, this.round, this.result});

  bool get hasPlayed => round != -1;

  bool get canBePlayed => !hasPlayed && competitorA != '' && competitorB != '';

  bool get hasResult => result != null;

  String get winner {
    if (!hasResult) throw 'Winner is only available when there is a result';
    return result == 'A' ? competitorA : competitorB;
  }

  String get loser {
    if (!hasResult) throw 'Loser is only available when there is a result';
    return result == 'A' ? competitorB : competitorA;
  }

  @override
  int compareTo(Pairing other) {
    var typeComp = compareBattleTypes(type, other.type);
    if (typeComp != 0) return typeComp;
    if (column != other.column) return column.compareTo(other.column);
    return row.compareTo(other.row);
  }

  @override
  String toString() {
    return '<$competitorA - $competitorB>';
  }
}

Map<String, List<Pairing>> computeAllPairings() {
  var spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  var participants = allParticipants;
  var cacheSheet = spreadsheet.getSheetByName(cacheSheetName);
  var cache = cacheSheet.getDataRange().getValues();

  var pairingsPerParticipant = <String, List<Pairing>>{};
  for (var participant in participants) {
    pairingsPerParticipant[participant] = [];
  }

  for (var row in cache) {
    var column = 0;
    String participant = row[column++];
    String competitorA = row[column++];
    String competitorB = row[column++];
    var type = stringToBattleType[row[column++]];
    String result = row[column++];
    if (result == '') result = null;
    int roundNumber = row[column] == '' ? -1 : row[column];
    column++;
    int roundRow = row[column++];
    int roundColumn = row[column++];

    pairingsPerParticipant[participant].add(Pairing(
        roundRow, roundColumn, competitorA, competitorB,
        type: type, result: result, round: roundNumber));
  }

  return pairingsPerParticipant;
}

class State {
  final String participant;
  final bool isActive;
  final String url;
  final List<Pairing> allPairings;
  final bool hasLoserBracket;
  final List<Pairing> winnerPairings;
  final List<Pairing> loserPairings;
  final List<Pairing> bonusPairings;
  final List<int> missingResults;
  final List<Pairing> availableWinnerPairings;
  final List<Pairing> availableLoserPairings;
  final int nextRoundNumber;
  final int playedWinnersCount;
  final int playedLosersCount;
  final int playedBonusCount;
  final int finishedWinnersCount;
  final int finishedLosersCount;
  final int finishedBonusCount;
  final int aSelectionCount;

  factory State(String participant, bool isActive, String url,
      List<Pairing> allPairings) {
    var inStock = inStockCompetitors;

    bool canBePlayed(Pairing pairing) {
      return pairing.canBePlayed &&
          inStock.contains(pairing.competitorA) &&
          inStock.contains(pairing.competitorB);
    }

    var winnerPairings = <Pairing>[];
    var loserPairings = <Pairing>[];
    var bonusPairings = <Pairing>[];
    var availableWinnerPairings = <Pairing>[];
    var availableLoserPairings = <Pairing>[];
    var playedWinnersCount = 0;
    var playedLosersCount = 0;
    var playedBonusCount = 0;
    var finishedWinnersCount = 0;
    var finishedLosersCount = 0;
    var finishedBonusCount = 0;
    var missingResults = <int>[];
    var maxRoundNumber = 0;
    var aSelectionCount = 0;
    for (var pairing in allPairings) {
      switch (pairing.type) {
        case BattleType.winner:
          winnerPairings.add(pairing);
          if (pairing.round > 0) playedWinnersCount++;
          if (pairing.hasResult) finishedWinnersCount++;
          if (canBePlayed(pairing)) availableWinnerPairings.add(pairing);
          break;
        case BattleType.loser:
          loserPairings.add(pairing);
          if (pairing.round > 0) playedLosersCount++;
          if (pairing.hasResult) finishedLosersCount++;
          if (canBePlayed(pairing)) availableLoserPairings.add(pairing);
          break;
        default:
          assert(pairing.type == BattleType.bonus);
          bonusPairings.add(pairing);
          if (pairing.round > 0) playedBonusCount++;
          if (pairing.hasResult) finishedBonusCount++;
      }
      if (pairing.hasPlayed && !pairing.hasResult) {
        if (pairing.round != 0) missingResults.add(pairing.round);
      }
      if (pairing.hasPlayed) {
        maxRoundNumber = math.max(pairing.round, maxRoundNumber);
      }
      if (pairing.result == 'A') aSelectionCount++;
    }
    var hasLoserBracket = loserPairings.isNotEmpty;
    var nextRoundNumber = maxRoundNumber + 1;
    winnerPairings.sort();
    loserPairings.sort();
    bonusPairings.sort();
    availableWinnerPairings.sort();
    availableLoserPairings.sort();

    return State._(
        participant,
        isActive,
        url,
        allPairings,
        hasLoserBracket,
        winnerPairings,
        loserPairings,
        bonusPairings,
        missingResults,
        availableWinnerPairings,
        availableLoserPairings,
        nextRoundNumber,
        playedWinnersCount,
        playedLosersCount,
        playedBonusCount,
        finishedWinnersCount,
        finishedLosersCount,
        finishedBonusCount,
        aSelectionCount);
  }

  State._(
      this.participant,
      this.isActive,
      this.url,
      this.allPairings,
      this.hasLoserBracket,
      this.winnerPairings,
      this.loserPairings,
      this.bonusPairings,
      this.missingResults,
      this.availableWinnerPairings,
      this.availableLoserPairings,
      this.nextRoundNumber,
      this.playedWinnersCount,
      this.playedLosersCount,
      this.playedBonusCount,
      this.finishedWinnersCount,
      this.finishedLosersCount,
      this.finishedBonusCount,
      this.aSelectionCount);

  int get finishedCount =>
      finishedWinnersCount + finishedLosersCount + finishedBonusCount;

  String get participantName => normalizeName(participant);
}
