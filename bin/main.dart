import 'dart:io' as io;
import 'dart:async';
import 'package:watcher/watcher.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'gsify.dart';
import 'upload.dart';

Stream watchPath(String path, {bool emitAtListen: false}) async* {
  var file = new io.File(path);
  if (file.existsSync() && emitAtListen) yield null;

  while (true) {
    if (!file.existsSync()) {
      var directory = p.dirname(path);
      await for (var directoryEvent in new DirectoryWatcher(directory).events) {
        if (file.existsSync()) {
          yield null;
          break;
        }
      }
    }
    if (file.existsSync()) {
      await for (var event in new FileWatcher(path).events) {
        if (event.type != ChangeType.REMOVE) yield null;
      }
    }
  }
}

void help(ArgParser parser) {
  print("Watches the source-javaScript file and uploads it automatically as a");
  print("Google Apps Script whenever it changes.");
  print("");
  print(parser.usage);
}

main(List<String> args) async {
  var parser = new ArgParser();
  parser.addOption("client-id",
      help: "the client id "
          "(from https://console.developers.google.com/apis/credentials)");
  parser.addOption("client-secret",
      help: "the client secret "
          "(from https://console.developers.google.com/apis/credentials)");
  parser.addOption("function",
      abbr: 'f', help: "provides a function stub", allowMultiple: true);
  parser.addFlag("only-current-document",
      help: "only accesses the current document "
          "(https://developers.google.com/apps-script/"
          "guides/services/authorization)", negatable: false);
  parser.addFlag("not-only-current-document",
      help: "force multi-document access", negatable: false);
  parser.addFlag("help", abbr: "h", help: "this help", negatable: false);
  var parsedArgs = parser.parse(args);
  if (parsedArgs['help'] ||
      parsedArgs['client-id'] == null ||
      parsedArgs['client-secret'] == null ||
      parsedArgs.rest.length != 2) {
    help(parser);
    return parsedArgs['help'] ? 0 : 1;
  }

  var sourcePath = parsedArgs.rest.first;
  var destination = parsedArgs.rest.last;
  String clientId = parsedArgs['client-id'];
  String clientSecret = parsedArgs['client-secret'];
  List<String> interfaceFunctions = parsedArgs['function'];
  bool onlyCurrentDocument = parsedArgs['only-current-document'];
  bool notOnlyCurrentDocument = parsedArgs['not-only-current-document'];

  var uploader = new Uploader(destination);
  await uploader.authenticate(clientId, clientSecret);

  await for (var event in watchPath(sourcePath, emitAtListen: true)) {
    var source = new io.File(sourcePath).readAsStringSync();
    var gsified = gsify(source, interfaceFunctions, onlyCurrentDocument,
        notOnlyCurrentDocument);
    await uploader.uploadScript(gsified);
  }
  await uploader.close();
}
