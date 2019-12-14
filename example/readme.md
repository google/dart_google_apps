# Google Apps Libraries

This library wraps the existing Google Apps APIs so they can be used
in Dart.

A simple example creates a new file with content "Hello from Dart": 

``` dart
import 'package:google_apps/drive.dart';

main() {
  DriveApp.createFile("hello.txt", "Hello from Dart");
}
```

This example must be compiled with the `--csp` flag and uploaded with
apps_script_tools (https://pub.dartlang.org/packages/apps_script_tools):
```
`dart2js --csp -o drive.js example/drive.dart`.
apps_script_watch /tmp/drive.js drive
```

It can then be executed by opening the script and running the script. Since
the example doesn't expose any entry point, simply running the `dartPrint` function
is good enough.

## Other examples
There are other small examples in the "misc" directory.
A big example can be found in the "tournament" directory.