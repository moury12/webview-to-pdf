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
  List<Uint8List> images = [];
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev'));
  }
Future<void> captureAndSaveScreenshots() async{
    try{
      await captureScrollableContent();
      await convertImageToPdf(images);
    }catch(e){

    }
}

  Future<void> convertImageToPdf(List<Uint8List> images) async {
    final pdf = pw.Document();
    for(var image in images){
      final imageProvider = pw.MemoryImage(image);

      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(imageProvider));
      }));
    }

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
      body: RepaintBoundary(key: _globalKey,
          child: SizedBox(  height: 2250, // Important Adjust the height as needed
              width: MediaQuery.of(context).size.width,

              child:  LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {

                    return WebViewWidget(controller: controller);
                }
              ))),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          // Uint8List? imageBytes = await screenshotController.capture();
          captureAndSaveScreenshots();
          images.clear();
        },
        tooltip: 'Download',
        child: const Icon(Icons.save),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

 Future<void> captureScrollableContent() async{
    double scrollPosition =0;
    bool reachend = false;
    while(!reachend){
      String? base64String =
      await ScrollScreenshot.captureAndSaveScreenshot(_globalKey);
      Uint8List imageBytes = Uint8List.fromList(base64Decode(base64String!));
      images.add(imageBytes);
      double maxScrollExtent =MediaQuery.of(context).size.height;
      scrollPosition +=maxScrollExtent;
      reachend=(scrollPosition>=maxScrollExtent);
      if(!reachend){
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
 }


}
