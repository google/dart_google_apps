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
library html;

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
