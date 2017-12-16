/// Compile this example with
/// `dart2js --trust-type-annotations --csp -o hello.js example/hello_docs.dart`.
/// Then build the corresponding `.gs` with:
/// `dart bin/gsify.dart -o hello.gs -f onOpen -f sayHello hello.js`.
/// or use the `main` script to immediately upload it to Google Drive.

@JS()
library hello_docs;

import 'package:js/js.dart';
import 'package:google_apps/google_apps.dart';

@JS()
external set sayHello(value);

@JS()
external set onOpen(value);

void sayHelloDart() {
  DocumentApp.getUi().alert("Hello world");
}

void onOpenDart(e, [String prefix]) {
  DocumentApp
      .getUi()
      .createMenu("from dart")
      .addItem(
          "say hello", prefix == null ? "sayHello" : "$prefix.sayHello")
      .addToUi();
}

main(List<String> arguments) {
  onOpen = allowInterop(onOpenDart);
  sayHello = allowInterop(sayHelloDart);
}
