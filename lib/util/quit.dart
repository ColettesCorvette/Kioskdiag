// Termine l'application. exit(0) sur la borne, no-op sur le web.
export 'quit_noop.dart' if (dart.library.io) 'quit_io.dart';
