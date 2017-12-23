@JS()
library hello;

import 'package:js/js.dart';

@JS()
class HtmlService {
  // TODO: argument could also be a `BlobSource`. Don't need it yet.
  external static HtmlOutput createHtmlOutput([String html]);
}

@JS()
class HtmlOutput {
  external HtmlOutput setContent(String content);
  external HtmlOutput setWidth(int width);
  external HtmlOutput setHeight(int height);
  external HtmlOutput setTitle(String title);
  external int getWidth();
  external int getHeight();
  external String getTitle();
}

@JS()
class DocumentApp {
  external static UI getUi();
  external static Document create(String name);
  external static HorizontalAligmnentContainer get HorizontalAlignment;
}

@JS()
class Document {
  external Body getBody();
  external String getId();
}

@JS()
class Element {

}

@JS()
class Body implements Element {
  external Paragraph appendParagraph(String text);
  external PageBreak appendPageBreak();
  external Table appendTable([List<List<String>> cells]);
  external Element getChild(int childIndex);
}

@JS()
class Paragraph implements Element {
  external Paragraph setAlignment(HorizontalAlignment alignment);
  external Text editAsText();
  external void setText(String text);
}

// This class doesn't really exist in JS. Not sure if this will lead to
// problems.
@JS()
class HorizontalAligmnentContainer {
  external HorizontalAlignment get LEFT;
  external HorizontalAlignment get CENTER;
  external HorizontalAlignment get RIGHT;
  external HorizontalAlignment get JUSTIFY;
}

@JS()
class HorizontalAlignment {
}

@JS()
class Text implements Element {
  external Text setFontSize(int sizeOrStart, [int endInclusive, int size]);
}

@JS()
class Table implements Element {
  external TableCell getCell(int rowIndex, int cellIndex);
  external Table setBorderColor(String color);
}

@JS()
class TableCell implements Element {
  external Element getChild(int childIndex);
  external Text editAsText();
}

@JS()
class PageBreak implements Element {

}

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
  external Sheet insertRowAfter(int afterPosition);
  external Sheet insertRowBefore(int beforePosition);
  /// [numRows] is defaulting to 1.
  external void insertRows(rowIndex, [int numRows]);
  external Sheet insertRowsAfter(int afterPosition, int howMany);
  external Sheet insertRowsBefore(int beforePosition, int howMany);
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

@JS()
class UI {
  external void prompt(String msg);
  external void alert(String msg);
  external Menu createMenu(String caption);
  external Menu createAddonMenu();
  external void showModalDialog(HtmlOutput userInterface, String title);
  external void showSidebar(HtmlOutput userInterface);
}

@JS()
class Menu {
  external Menu addItem(String caption, String functionName);
  external Menu addSeparator();
  external Menu addSubMenu(Menu menu);
  external void addToUi();
}
