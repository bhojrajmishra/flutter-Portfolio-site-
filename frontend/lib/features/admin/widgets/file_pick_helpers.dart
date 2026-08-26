import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedFileBytes {
  final Uint8List bytes;
  final String name;
  const PickedFileBytes(this.bytes, this.name);
}

/// Opens the native file picker restricted to [type] (and, for
/// [FileType.custom], [allowedExtensions]) and returns the bytes + filename
/// of the selected file, or null if the user canceled.
Future<PickedFileBytes?> pickFileBytes({
  FileType type = FileType.any,
  List<String>? allowedExtensions,
}) async {
  final file = await FilePicker.pickFile(type: type, allowedExtensions: allowedExtensions);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return PickedFileBytes(bytes, file.name);
}
