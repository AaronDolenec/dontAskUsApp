// Non-web stub - returns false because native web clipboard APIs are not
// available on non-web platforms here. This is used in conditional imports.
Future<bool> writeTextToClipboard(String text) async => false;
