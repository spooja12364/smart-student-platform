import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';

String tempFilePath(String name) {
  return name;
}

Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('File access not available on web.');
}

void downloadOrOpenFile(String url, String fileName) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..target = '_blank';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    html.window.open(url, '_blank');
  }
}

void openOrPlayVideo(String url) {
  html.window.open(url, '_blank');
}

void registerVideoPlayerFactory(String viewType, String videoUrl) {
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final videoElement = html.VideoElement()
          ..src = videoUrl
          ..controls = true
          ..autoplay = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'black';
        return videoElement;
      },
    );
  } catch (_) {}
}
