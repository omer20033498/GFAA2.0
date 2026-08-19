/// Non-web platforms (Android/iOS/desktop): no browser to download through,
/// so the caller falls back to sharing the file via [SharePlus] instead.
bool downloadCsvInBrowser(String csv, String filename) => false;
