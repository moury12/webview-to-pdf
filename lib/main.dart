import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:scroll_screenshot/scroll_screenshot.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  MyHomePage(),
    );
  }
}



class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController controller;
  final ScreenshotController screenshotController = ScreenshotController();
  List<Uint8List> images = [];

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev'));
  }

  Future<void> captureAndSaveScreenshots() async {
    try {
      await captureScrollableContent();
      await convertImageToPdf(images);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> convertImageToPdf(List<Uint8List> images) async {
    final pdf = pw.Document();
    for (var image in images) {
      final imageProvider = pw.MemoryImage(image);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(child: pw.Image(imageProvider)),
        ),
      );
    }

    Directory dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/webview_screenshot.pdf');
    await file.writeAsBytes(await pdf.save());
    print('PDF saved to ${file.path}');
  }

  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Simple Example'),
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: SizedBox(
          height: MediaQuery.of(context).size.height, // Adjust height as needed
          width: MediaQuery.of(context).size.width,
          child: WebViewWidget(controller: controller),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          images.clear();
          await captureAndSaveScreenshots();
        },
        tooltip: 'Download',
        child: const Icon(Icons.save),
      ),
    );
  }

  Future<void> captureScrollableContent() async {
    double totalHeight = double.parse(
      (await controller.runJavaScriptReturningResult(
        'document.body.scrollHeight.toString();',
      )) as String,
    );

    double viewportHeight = MediaQuery.of(context).size.height;
    double scrollPosition = 0;

    while (scrollPosition < totalHeight) {
      Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        images.add(imageBytes);
      }

      scrollPosition += viewportHeight;
      if (scrollPosition < totalHeight) {
        await controller.runJavaScript('window.scrollTo(0, $scrollPosition);');
        await Future.delayed(Duration(milliseconds: 500)); // Wait for scroll
      }
    }
  }}

