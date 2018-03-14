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
library spreadsheet;

import 'package:js/js.dart';
import 'ui.dart';

export 'html.dart';
export 'ui.dart';

@JS()
class SpreadsheetApp {
  external static UI getUi();
  external static Spreadsheet getActiveSpreadsheet();
  external static Sheet getActiveSheet();
  external static Range getActiveRange();
}

@JS()
class Spreadsheet {
  external Sheet getSheetByName(String name);
  external Range getRangeByName(String name);
  external Sheet insertSheet([int index]);
  external void deleteSheet(Sheet sheet);
  external void deleteActiveSheet();
  external List<Sheet> getSheets();
}

@JS()
class Sheet {
  external Range getActiveCell();
  external Range getRange(dynamic /*String or int*/ rowOrA1Notation, [int column, int rumRows, int numColumns]);
  external Range getDataRange();
  external int getMaxRows();
  external int getMaxColumns();
  external int getLastColumn();
  external int getLastRow();
  external String getName();
  external Sheet setName(String name);
  external Sheet clear();
  external Sheet clearContents();
  external Sheet clearFormats();
  external Sheet setColumnWidth(int columnIndex, int width);
  external Sheet setRowHeight(int rowIndex, int height);
  external Sheet insertRowAfter(int afterPosition);
  external Sheet insertRowBefore(int beforePosition);
  /// [numRows] is defaulting to 1.
  external void insertRows(rowIndex, [int numRows]);
  external Sheet insertRowsAfter(int afterPosition, int howMany);
  external Sheet insertRowsBefore(int beforePosition, int howMany);
  external void insertColumns(columnIndex, [int numColumns]);
  external int getIndex();
  external Sheet appendRow(List<dynamic> rowContents);
  external Sheet hideSheet();
  external bool isSheetHidden();
}

@JS()
class Range {
  external int getRow();
  external int getColumn();
  external dynamic getValue();
  external Range setValue(dynamic value);
  external List<List<dynamic>> getValues();
  external Range setValues(List<List<dynamic>> values);
  external String getDisplayValue();
  external List<List<String>> getDisplayValues();
  external String getFormula();
  external List<List<String>> getFormulas();
  external String getFormulaR1C1();
  external List<List<String>> getFormulasR1C1();
  external Range setFormula(String formula);

  /**
   * The size of the two-dimensional array must match the size of the range.
   * ```
   * var formulas = [
   *   ["=SUM(B2:B4)", "=SUM(C2:C4)", "=SUM(D2:D4)"],
   *   ["=AVERAGE(B2:B4)", "=AVERAGE(C2:C4)", "=AVERAGE(D2:D4)"]
   * ];
   * var cell = sheet.getRange("B5:D6");
   * cell.setFormulas(formulas);
   * ```
   */
  external Range setFormulas(List<List<String>> formulas);
  external Range setFormulaR1C1(String formula);

  /**
   * This creates formulas for a row of sums, followed by a row of averages.
   * ```
   * var sumOfRowsAbove = "=SUM(R[-3]C[0]:R[-1]C[0])";
   * var averageOfRowsAbove = "=AVERAGE(R[-4]C[0]:R[-2]C[0])";
   * ```
   *
   * The size of the two-dimensional array must match the size of the range.
   * ```
   * var formulas = [
   *   [sumOfRowsAbove, sumOfRowsAbove, sumOfRowsAbove],
   *   [averageOfRowsAbove, averageOfRowsAbove, averageOfRowsAbove]
   * ];
   * var cell = sheet.getRange("B5:D6");
   * cell.setFormulasR1C1(formulas);
   * ```
   */
  external Range setFormulasR1C1(List<List<String>> formulas);
  external Range offset(int row, int column, [int numRows, int numColumns]);
  external Sheet getSheet();
  external Range setBackground(String color);
  external Range setBackgroundRGB(int red, int green, int blue);
  external Range setBackgrounds(List<List<String>> colors);
  external String getBackgroundColor();
  external List<List<String>> getBackgrounds();
  external String getA1Notation();
  /// Relative to this range.
  external Range getCell(int row, int column);
  external int getNumRows();
  external int getNumColumns();
}
