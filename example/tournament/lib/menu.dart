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
library brackets;

import 'src/brackets.dart';
import 'src/cache.dart';
import 'src/next_round.dart';
import 'src/reports.dart';

import 'package:js/js.dart';

@JS()
external set createBracketForSelected(value);

@JS()
external set createBracketForAll(value);

@JS()
external set deleteAllBracketSheets(value);

@JS()
external set prepareNextRound(value);

@JS()
external set competitorRanking(value);

@JS()
external set generateFinalReports(value);

@JS()
external set generateCompetitorReports(value);

@JS()
external set rebuildCache(value);

@JS()
external set test(value);

void exportToJs() {
  createBracketForSelected = allowInterop(createBracketForSelectedDart);
  createBracketForAll = allowInterop(createBracketForAllDart);
  deleteAllBracketSheets = allowInterop(deleteAllBracketSheetsDart);
  prepareNextRound = allowInterop(prepareNextRoundDart);
  competitorRanking = allowInterop(competitorRankingDart);
  rebuildCache = allowInterop(rebuildCacheDart);
  generateFinalReports = allowInterop(generateFinalReportsDart);
  generateCompetitorReports = allowInterop(generateCompetitorReportsDart);
  test = allowInterop(testDart);
}

Map<String, dynamic> createMenuEntries() {
  return <String, dynamic>{
    'Setup': {
      'Create Bracket for Selected': 'createBracketForSelected',
      'Create Bracket for All': 'createBracketForAll',
    },
    'Next Round': 'prepareNextRound',
    'Reports': {
      'Ranking': 'competitorRanking',
      'Participants': 'generateFinalReports',
      'Competitors': 'generateCompetitorReports',
    },
    'Maintenance': {
      'Rebuild Cache': 'rebuildCache',
      'Delete all Bracket-sheets': 'deleteAllBracketSheets',
    },
    // 'Debug': 'test',
  };
}

void testDart() {}
