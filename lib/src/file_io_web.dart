import 'dart:typed_data';

String tempFilePath(String name) {
  return name;
}

Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('File access not available on web.');
}
