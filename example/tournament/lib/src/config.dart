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

import 'utils.dart';
import 'package:google_apps/google_apps.dart';

/// A list of all participants.
final List<String> allParticipants = participantsConfig.read();

/// A list of boolean flags whether participants are active.
///
/// This returns the boolean flags and must be matched up with
/// [allParticipants]. Use [activeParticipants] to get a list of filtered
/// participants.
///
/// No checks are done to ensure that this list has the same length as the
/// number of [allParticipants].
final List<String> allActives = activesConfig.read();

/// A list of active participants.
///
/// This combines [allParticipants] and [allActives] to filter out participants
/// that are not active.
final List<String> activeParticipants = () {
  var participants = allParticipants;
  var activeFlags = allActives;
  if (participants.length != activeFlags.length) {
    error('Participants and Actives have different lengths.');
  }
  var activeParticipants = <String>[];
  for (var i = 0; i < participants.length; i++) {
    if (boolify(activeFlags[i])) {
      activeParticipants.add(participants[i]);
    }
  }
  return activeParticipants;
}();

final Map<String, String> urlMapping = () {
  var participants = allParticipants;
  var urls = urlConfig.read();
  var result = <String, String>{};
  for (var i = 0; i < participants.length; i++) {
    result[participants[i]] = urls[i];
  }
  return result;
}();

/// A list of all competitors.
final List<String> allCompetitors = competitorsConfig.read();

/// A list of boolean flags whether competitors are in stock.
///
/// This returns the boolean flags and must be matched up with [allCompetitors].
/// Use [inStockCompetitors] to get a filtered set of the competitors.
final List<String> allInStocks = inStockConfig.read();

/// A set of competitors that are in stock.
///
/// This combines [allCompetitors] and [allInStock].
final Set<String> inStockCompetitors = () {
  var competitors = allCompetitors;
  var inStock = allInStocks;
  if (competitors.length != inStock.length) {
    error('Competitors and In-stock have different lengths.');
  }

  var result = <String>{};
  for (var i = 0; i < competitors.length; i++) {
    if (boolify(inStock[i])) result.add(competitors[i]);
  }
  return result;
}();

/// Whether two next-round pages are printed on one paper sheet.
///
/// See [isPrinting2PagesPerSheetConfig].
final bool isPrinting2PagesPerSheet =
    boolify(isPrinting2PagesPerSheetConfig.read());

/// Whether the tournament for each participant is double-elimination.
final bool isDoubleElimination = boolify(isDoubleEliminationConfig.read());

/// The name of the sheet that contains all configurations.
const String configSheetName = 'Config';

/// The name of the sheet that contains all results.
///
/// Usually, the results are filled in through a form, but they can also be
/// filled in by hand. See below ([resultsParticipantColumn], ...) to see how
/// the results sheet must be filled.
const String resultsSheetName = 'Results';

/// The name of the sheet that contains the cache.
///
/// When there are many participants and competitors, running the script can
/// take a significant time. The cache-sheet speeds up the computations
/// significantly because it reduces the number of API calls.
const String cacheSheetName = 'Cache';

/// An list-entry in the config sheet.
///
/// Config entries are found by their header.
///
/// The library searches the header in the first column of the config sheet and
/// returns all entries that follow the header.
class ListConfigEntry {
  final String header;
  Range _range;
  List<String> _values;

  ListConfigEntry(this.header);

  /// Returns the range for this config.
  Range get range {
    if (_range == null) read();
    return _range;
  }

  /// Returns the entries for this config.
  List<String> read() {
    if (_values != null) return _values;

    var configSheet = _configSheet;
    var lastRow = configSheet.getLastRow();
    var lastColumn = configSheet.getLastColumn();
    var configValues =
        configSheet.getRange(1, 1, lastRow, lastColumn).getDisplayValues();

    var nextIsHeader = true;
    for (var i = 0; i < lastRow; i++) {
      if (nextIsHeader && configValues[i][0] == header) {
        var result = <String>[];
        for (var j = i + 1; j < lastRow; j++) {
          if (configValues[j][0] == '') break;
          result.add(configValues[j][0]);
        }
        _values = result;
        _range = configSheet.getRange(i + 2, 1, result.length, 1);
        return _values;
      }
      nextIsHeader = (configValues[i][0] == '');
    }
    error("Couldn't find ${header}");
    return [];
  }
}

/// An secondary entry in the config sheet.
///
/// Secondary entries are in a column next to the primary configuration.
/// They are identified by a primary configuration, and a secondary header.
///
/// The library searches the primary configuration, and then finds the header in
/// the same row.
class SecondaryConfigEntry {
  final ListConfigEntry primary;
  final String header;

  List<String> _values;

  SecondaryConfigEntry(this.primary, this.header);

  /// Returns the range for this config.
  List<String> read() {
    if (_values != null) return _values;

    var primaryRange = primary.range;
    // We search at most 10 columns.
    var headerRow = primaryRange.offset(-1, 0, 1, 10);
    var headerValuesRow = headerRow.getDisplayValues()[0];
    var secondaryOffset = -1;
    for (var i = 0; i < headerValuesRow.length; i++) {
      if (headerValuesRow[i] == header) {
        secondaryOffset = i;
        break;
      }
    }
    if (secondaryOffset == -1) error("Couldn't find ${header}");

    var secondaryRange = primaryRange.offset(0, secondaryOffset);
    var result = <String>[];
    var displayValues = secondaryRange.getDisplayValues();
    for (var i = 0; i < displayValues.length; i++) {
      result.add(displayValues[i][0]);
    }
    _values = result;
    return result;
  }
}

/// A single config entry in the config sheet.
///
/// Single entries are in a section and have just one value.
/// They are identified by a list configuration (the section), and a header
/// (in the section).
///
/// The library searches the primary configuration, and then finds the header in
/// the same column. The returned value is the entry next to the found header.
class SingleConfigEntry {
  final ListConfigEntry section;
  final String header;
  String _value;

  SingleConfigEntry(this.section, this.header);

  String read() {
    if (_value != null) return _value;
    var sectionValues = section.read();
    var sectionRange = section.range;
    for (var i = 0; i < sectionValues.length; i++) {
      if (sectionValues[i] == header) {
        _value = sectionRange.offset(i, 1, 1, 1).getDisplayValue();
        return _value;
      }
    }
    error("Couldn't find ${header}");
    return '';
  }
}

/// The configuration for all participating "judges".
///
/// These are the humans deciding which of the competitors win each sampling.
final participantsConfig = ListConfigEntry('Participants');

/// The configuration, whether a given participant is active.
///
/// When participants are (temporarily) out, then this flag can be set to false.
final activesConfig = SecondaryConfigEntry(participantsConfig, 'Active');

/// The URL that should be printed on the battle sheet.
///
/// Each participant may have a different one. For example, when the URL points
/// to a prefilled form sheet.
final urlConfig = SecondaryConfigEntry(participantsConfig, 'URL');

/// The configuration for the competitors.
///
/// These are the samples (chocolate, wine, ...) that are judged.
final competitorsConfig = ListConfigEntry('Competitors');

/// The configuration, whether a competitor is in stock.
///
/// Since the amount of samples is dependent on the choices of the participants
/// it can happen that not enough competitors have been bought/stocked.
///
/// When this configuration is set to false, the script will not create
/// pairings that require the out-of-stock competitor.
final inStockConfig = SecondaryConfigEntry(competitorsConfig, 'In Stock');

final miscSection = ListConfigEntry('Misc');

/// The configuration whether two next-round pages are printed on one sheet.
///
/// This reorders the order in which the pages are printed.
///
/// Print-outs are done in the order of the sheets. This allows the game-master
/// to organize the samples in such a way that the distribution is most
/// efficient.
///
/// Often, it's not necessary to have a full A4 (or letter) paper used for the
/// print-out, but half of it is enough. When printing two pages per paper-sheet
/// one can then cut all papers in the middle. When this flag is set to true,
/// it is then possible to put the left side (of the cut pages) on top of the
/// right side to get back the original order.
final isPrinting2PagesPerSheetConfig =
    SingleConfigEntry(miscSection, '2 Sheets per Page');

/// The configuration whether two next-round pages are printed on one sheet.
///
/// This reorders the order in which the pages are printed.
///
/// Print-outs are done in the order of the sheets. This allows the game-master
/// to organize the samples in such a way that the distribution is most
/// efficient.
///
/// Often, it's not necessary to have a full A4 (or letter) paper used for the
/// print-out, but half of it is enough. When printing two pages per paper-sheet
/// one can then cut all papers in the middle. When this flag is set to true,
/// it is then possible to put the left side (of the cut pages) on top of the
/// right side to get back the original order.
final isDoubleEliminationConfig =
    SingleConfigEntry(miscSection, 'Double Elimination');

/// The column of the results sheet that contains the participant.
const resultsParticipantColumn = 'B';

/// The column of the results sheet that contains the round number.
const resultsRoundColumn = 'C';

/// The column of the results sheet that contains the winner of the battle.
const resultsWinColumn = 'D';

/// The column of the results sheet that contains the comment for competitor A.
const resultsCommentsAColumn = 'E';

/// The column of the results sheet that contains the comment for competitor B.
const resultsCommentsBColumn = 'F';

/// The range of results.
///
/// Just skips the first row, since it contains the headers.
const resultsRange = r'$A$2:$D$9999';

/// Fully qualified range that includes the sheet-name.
const resultsQualifiedRange = '$resultsSheetName!$resultsRange';

// We are using "#ffffff' notation for colors, because this is, what
// 'getBackground` returns.

/// The color for competitors
const competitorColor = '#ffff00'; // yellow
/// The color of connectors.
const connectorColor = '#40C040'; // green
/// The color of the round/battle in the winner bracket.
const winnerRoundColor = '#e8f8f5';

/// The color of the round/battle in the loser bracket.
const loserRoundColor = '#ebf5fb';

/// The color of the round/battle for bonus rounds.
const bonusRoundColor = '#fce5cd';

/// Width of the connector column.
const connectorWidth = 15;

/// The config sheet.
final Sheet _configSheet =
    SpreadsheetApp.getActiveSpreadsheet().getSheetByName(configSheetName);

bool boolify(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value == 'TRUE') return true;
  return false;
}
