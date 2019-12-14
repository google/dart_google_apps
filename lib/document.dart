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
library document;

import 'package:js/js.dart';
import 'ui.dart';

export 'html.dart';
export 'ui.dart';

@JS()
class DocumentApp {
  external static UI getUi();
  external static Document create(String name);
  external static HorizontalAlignmentContainer get HorizontalAlignment;
  external static ParagraphHeadingContainer get ParagraphHeading;
}

@JS()
class Document {
  external Body getBody();
  external String getId();
}

@JS()
class Element {}

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
  external Paragraph setHeading(ParagraphHeading heading);
  external ParagraphHeading getHeading();
}

// This class doesn't really exist in JS. Not sure if this will lead to
// problems.
@JS()
class HorizontalAlignmentContainer {
  external HorizontalAlignment get LEFT;
  external HorizontalAlignment get CENTER;
  external HorizontalAlignment get RIGHT;
  external HorizontalAlignment get JUSTIFY;
}

@JS()
class HorizontalAlignment {}

// This class doesn't really exist in JS. Not sure if this will lead to
// problems.
@JS()
class ParagraphHeadingContainer {
  external ParagraphHeading get NORMAL;
  external ParagraphHeading get HEADING1;
  external ParagraphHeading get HEADING2;
  external ParagraphHeading get HEADING3;
  external ParagraphHeading get HEADING4;
  external ParagraphHeading get HEADING5;
  external ParagraphHeading get HEADING6;
  external ParagraphHeading get TITLE;
  external ParagraphHeading get SUBTITLE;
}

@JS()
class ParagraphHeading {}

@JS()
class Text implements Element {
  external Text setFontSize(int sizeOrStart, [int endInclusive, int size]);
  external Text setBold(dynamic valueOrStart, [int endInclusive, bool value]);
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
class PageBreak implements Element {}
