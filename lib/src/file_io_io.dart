import 'dart:io';
import 'dart:typed_data';

String tempFilePath(String name) {
  return '${Directory.systemTemp.path}/$name';
}

Future<Uint8List> readFileBytes(String path) {
  return File(path).readAsBytes();
}
