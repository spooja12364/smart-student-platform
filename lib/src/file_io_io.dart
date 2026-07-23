import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

String tempFilePath(String name) {
  return '${Directory.systemTemp.path}/$name';
}

Future<Uint8List> readFileBytes(String path) {
  return File(path).readAsBytes();
}

void downloadOrOpenFile(String url, String fileName) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(uri);
  }
}

void openOrPlayVideo(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(uri);
  }
}

void registerVideoPlayerFactory(String viewType, String videoUrl) {
  // No-op for non-web platforms
}
