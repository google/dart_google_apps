import 'dart:io';
import 'package:args/args.dart';
import 'package:google_apps/src/preamble.dart';

String gsify(String source, List<String> interfaceFunctions,
    bool onlyCurrentDocument, bool notOnlyCurrentDocument) {
  var result = new StringBuffer();
  if (onlyCurrentDocument) {
    result.writeln("/* @OnlyCurrentDoc */");
  }
  if (notOnlyCurrentDocument) {
    result.writeln("/* @NotOnlyCurrentDoc */");
  }
  for (var fun in interfaceFunctions) {
    // These functions can be overridden by the Dart program.
    result.writeln("function $fun() {}");
  }
  result.writeln(PREAMBLE);
  result.write(source);
  return result.toString();
}

void help(parser) {
  print("Transforms a JavaScript file into a Google Apps script.");
  print("Dart2js must have been invoked with --csp for the output to be valid");
  print("");
  print("Usage: script -o out.gs in.js");
  print(parser.usage);
}

main(args) {
  var parser = new ArgParser();
  parser.addOption("function",
      abbr: 'f', help: "provides a function stub", allowMultiple: true);
  parser.addFlag("only-current-document",
      help: "only accesses the current document "
          "(https://developers.google.com/apps-script/"
          "guides/services/authorization)", negatable: false);
  parser.addFlag("not-only-current-document",
      help: "force multi-document access", negatable: false);
  parser.addOption("out", abbr: "o", help: "path of generated gs script");
  parser.addFlag("help", abbr: "h", help: "this help", negatable: false);
  var parsedArgs = parser.parse(args);
  if (parsedArgs['out'] == null ||
      parsedArgs['help'] ||
      parsedArgs.rest.length != 1) {
    help(parser);
    return parsedArgs['help'] ? 0 : 1;
  }

  var sourcePath = parsedArgs.rest.first;
  String outPath = parsedArgs['out'];
  List<String> interfaceFunctions = parsedArgs['function'];
  bool onlyCurrentDocument = parsedArgs['only-current-document'];
  bool notOnlyCurrentDocument = parsedArgs['not-only-current-document'];

  var source = new File(sourcePath).readAsStringSync();
  var gsified = gsify(
      source, interfaceFunctions, onlyCurrentDocument, notOnlyCurrentDocument);
  new File(outPath).writeAsStringSync(gsified);
}
