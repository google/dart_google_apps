import 'dart:io' as io;
import 'dart:async';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' show Client;
import 'package:args/args.dart';

const List<String> _SCOPES = const [
  DriveApi.DriveScope,
  DriveApi.DriveScriptsScope
];

const String _SCRIPT_MIME_TYPE = "application/vnd.google-apps.script";
const String _CONTENT_TYPE = "application/vnd.google-apps.script+json";

class Uploader {
  final String _destination;
  DriveApi _drive;
  Client _baseClient;
  AuthClient _client;

  String _projectName;
  String _destinationFolderId;

  Uploader(this._destination);

  Future authenticate(String id, String secret) async {
    _baseClient = new Client();
    var clientId = new ClientId(id, secret);
    var credentials = _readSavedCredentials();
    if (credentials == null ||
        credentials.refreshToken == null && credentials.accessToken.hasExpired) {
      credentials = await obtainAccessCredentialsViaUserConsent(
          clientId, _SCOPES, _baseClient, (String str) {
        print("Please authorize at this URL: $str");
      });
      _saveCredentials(credentials);
    }
    _client = credentials.refreshToken == null
        ? authenticatedClient(_baseClient, credentials)
        : autoRefreshingClient(clientId, credentials, _baseClient);
    _drive = new DriveApi(_client);
  }

  Future close() async {
    await _client.close();
    await _baseClient.close();
  }

  String _createPayload(String source, String projectName,
      Map<String, dynamic> existing) {

    // See https://developers.google.com/apps-script/guides/import-export.
    var payload = {
      "name": projectName,
      "type": "server_js",
      "source": source,
    };
    if (existing != null) {
      payload["id"] = existing["files"][0]["id"];
    }
    return JSON.encode({
      "files": [payload]
    });
  }

  Future<String> _findFolder(DriveApi drive, Iterable<String> segments) async {
    var parentId = "root";
    for (var segment in segments) {
      var q = "name = '$segment' and '$parentId' in parents and trashed = false";
      var nestedFiles = (await drive.files.list(q: q)).files;
      if (nestedFiles.length == 1 &&
          nestedFiles[0].mimeType == "application/vnd.google-apps.folder") {
        parentId = nestedFiles[0].id;
      } else {
        throw "Couldn't find folder $segment";
      }
    }
    return parentId;
  }

  Future uploadScript(String source) async {
    if (_projectName == null) {
      var segments = _destination.split("/");
      var folderSegments = segments.take(segments.length - 1);
      _projectName = segments.last;
      _destinationFolderId = await _findFolder(_drive, folderSegments);
    }

    var query = "name = '$_projectName' and "
        "'$_destinationFolderId' in parents and "
        "trashed = false";
    var sameNamedFiles = (await _drive.files.list(q: query)).files;
    var existing = null;
    if (sameNamedFiles.isEmpty) {
      print("Need to create new project.");
    } else if (sameNamedFiles.length == 1) {
      print("Need to update existing project.");
      Media media = await _drive.files.export(
          sameNamedFiles[0].id, _CONTENT_TYPE,
          downloadOptions: DownloadOptions.FullMedia);
      existing = await media.stream
          .transform(UTF8.decoder)
          .transform(JSON.decoder)
          .first;
    } else {
      print("Multiple files of same name. Don't know which one to update.");
      return;
    }

    var file = new File()
      ..name = _projectName
      ..mimeType = _SCRIPT_MIME_TYPE;

    var payload = _createPayload(source, _projectName, existing);
    var utf8Encoded = UTF8.encode(payload);
    var media = new Media(
        new Stream<List<int>>.fromIterable([utf8Encoded]), utf8Encoded.length,
        contentType: _CONTENT_TYPE);

    if (sameNamedFiles.isEmpty) {
      print("Creating new file ${_projectName}");
      file.parents = [_destinationFolderId];
      await _drive.files.create(file, uploadMedia: media);
    } else if (sameNamedFiles.length == 1) {
      // Update the existing file.
      print("Updating existing file ${_projectName}");
      await _drive.files.update(file, sameNamedFiles[0].id, uploadMedia: media);
    }
    print("Uploading ${_projectName} done");
  }

  final String _savedCredentialsPath = () {
    if (io.Platform.environment.containsKey('UPLOAD_APPS_SCRIPT_CACHE')) {
      return io.Platform.environment['UPLOAD_APPS_SCRIPT_CACHE'];
    } else if (io.Platform.operatingSystem == 'windows') {
      var appData = io.Platform.environment['APPDATA'];
      return p.join(appData, 'UploadAppsScript', 'Cache');
    } else {
      return '${io.Platform.environment['HOME']}/.upload_apps_script-cache';
    }
  }();

  AccessCredentials _readSavedCredentials() {
    var file = new io.File(_savedCredentialsPath);
    if (!file.existsSync()) return null;
    var decoded = JSON.decode(file.readAsStringSync());
    var refreshToken = decoded['refreshToken'];
    if (refreshToken == null) {
      print("refreshToken missing. Users will have to authenticate again.");
    }
    var jsonAccessToken = decoded['accessToken'];
    var accessToken = new AccessToken(
        jsonAccessToken['type'],
        jsonAccessToken['data'],
        new DateTime.fromMillisecondsSinceEpoch(jsonAccessToken['expiry'],
            isUtc: true));
    var scopes = decoded['scopes'].map<String>((x) => x).toList();
    return new AccessCredentials(accessToken, refreshToken, scopes);
  }

  void _saveCredentials(AccessCredentials credentials) {
    var accessToken = credentials.accessToken;
    var encoded = JSON.encode({
      'refreshToken': credentials.refreshToken,
      'accessToken': {
        "type": accessToken.type,
        "data": accessToken.data,
        "expiry": accessToken.expiry.millisecondsSinceEpoch
      },
      'scopes': credentials.scopes
    });
    new io.File(_savedCredentialsPath).writeAsStringSync(encoded);
  }
}

void help(ArgParser parser) {
  print("Uploads a given '.gs' script to Google Drive as a Google Apps script");
  print("Usage: upload --client-id=<id> --client-secret=<secret> "
      "compiled.gs destination");
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

  var uploader = new Uploader(destination);
  await uploader.authenticate(parsedArgs['client-id'], parsedArgs['client-secret']);
  var source = new io.File(sourcePath).readAsStringSync();
  await uploader.uploadScript(source);
  await uploader.close();
}
