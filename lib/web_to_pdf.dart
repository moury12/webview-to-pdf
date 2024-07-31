import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webview_flutter/webview_flutter.dart';

class WebToPdf extends StatefulWidget {
  @override
  _WebToPdfState createState() => _WebToPdfState();
}

class _WebToPdfState extends State<WebToPdf> {
  late WebViewController _controller;
  final ScreenshotController screenshotController = ScreenshotController();
  final List<Uint8List> images = [];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev'));
  }

  void scrollToTop() {
    _controller.runJavaScript("window.scrollTo({top: 0, behavior: 'smooth'});");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Screenshot'),
      ),
      body: Screenshot(
        controller: screenshotController,
        child: WebViewWidget(controller: _controller),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _scrollToBottom,
            child: const Icon(Icons.save),
          ),
          FloatingActionButton(
            onPressed: () {
              convertImageToPdf(images);
            },
            child: const Icon(Icons.file_copy),
          ),
        ],
      ),
    );
  }

  Future<void> convertImageToPdf(List<Uint8List> images) async {
    final pdf = pw.Document();
    for (var image in images) {
      final imageProvider = pw.MemoryImage(image);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Center(child: pw.Image(imageProvider)),
        ),
      );
    }

    Directory dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/webview_screenshot.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
    print('PDF saved to ${file.path}');
  }

  void _scrollToBottom() async {
//document.body.scrollHeight

    String jsScrollToBottom = """(function() {
        var viewportHeight = window.innerHeight;
        var scrollPosition = window.scrollY;
        window.scrollTo(0, scrollPosition + viewportHeight);
      })();""";

    await _controller.runJavaScript(jsScrollToBottom);
    Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      images.add(imageBytes);
    }
  }
}
