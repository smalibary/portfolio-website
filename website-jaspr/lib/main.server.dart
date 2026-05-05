/// The entrypoint for the **server** environment.
///
/// The [main] method runs only on the server during pre-rendering.
library;

import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);
  runApp(App());
}
