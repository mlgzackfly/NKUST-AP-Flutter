import 'dart:io';

/// Extension on [File] for convenient size calculations.
extension FileExtension on File {
  /// Returns the file size in megabytes.
  double get mb => lengthSync() / 1024 / 1024;

  /// Returns the file size in kilobytes.
  double get kb => lengthSync() / 1024;
}
