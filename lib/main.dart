import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController controller;


  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev'));
  }


  Future<void> convertImageToPdf(Uint8List image) async {
    final pdf = pw.Document();
    final imageProvider = pw.MemoryImage(image);

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(child: pw.Image(imageProvider));
    }));

    Directory dir = Directory('/storage/emulated/0/Download');
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
      body: Screenshot( controller: screenshotController,
          child: RepaintBoundary(key: _globalKey,
              child: WebViewWidget(controller: controller))),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          // Uint8List? imageBytes = await screenshotController.capture();
          String? base64String =
          await ScrollScreenshot.captureAndSaveScreenshot(_globalKey);
          // Convert imageBytes to PDF
          Uint8List imageBytes = Uint8List.fromList(base64Decode(base64String!));
          await convertImageToPdf(imageBytes);
        },
        tooltip: 'Download',
        child: const Icon(Icons.save),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}
