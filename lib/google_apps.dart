@JS()
library hello;

import 'package:js/js.dart';

@JS()
class DocumentApp {
  external static UI getUi();
}

@JS()
class SpreadsheetApp {
  external static UI getUi();
  external static Spreadsheet getActiveSpreadsheet();
}

@JS()
class Spreadsheet {
  external Sheet getSheetByName(String name);
  external Range getRangeByName(String name);
  external Sheet insertSheet([int index]);
  external void deleteSheet(Sheet sheet);
  external void deleteActiveSheet();
}

@JS()
class Sheet {
  external Range getActiveCell();
  external Range getRange(int row, int column, [int rumRows, int numColumns]);
  external int getMaxRows();
  external int getMaxColumns();
  external String getName();
  external Sheet setName(String name);
  external Sheet clear();
  external Sheet clearContents();
  external Sheet clearFormats();
  external Sheet setColumnWidth(int columnIndex, int width);
}

@JS()
class Range {
  external int getRow();
  external int getColumn();
  external dynamic getValue();
  external Range setValue(dynamic value);
  external List<List<dynamic>> getValues();
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
  external Range setBackgroundColor(String color);
  external Range setBackgroundRGB(int red, int green, int blue);
  external Range setBackgrounds(List<List<String>> colors);
  external String getA1Notation();
}

@JS()
class UI {
  external void prompt(String msg);
  external void alert(String msg);
  external Menu createMenu(String caption);
  external Menu createAddonMenu();
}

@JS()
class Menu {
  external Menu addItem(String caption, String functionName);
  external Menu addSeparator();
  external Menu addSubMenu(Menu menu);
  external void addToUi();
}
