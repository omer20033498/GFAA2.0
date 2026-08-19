// This file is only ever reached via the `dart.library.html` conditional
// export in csv_download.dart, so it's never compiled into the
// Android/iOS/desktop app.

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a real browser download (straight to the Downloads folder, no
/// share-sheet detour) instead of routing the CSV through [SharePlus], which
/// on web/desktop opens the OS's generic Share panel rather than saving a
/// file.
bool downloadCsvInBrowser(String csv, String filename) {
  final blob = web.Blob(
    [utf8.encode(csv).toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}
