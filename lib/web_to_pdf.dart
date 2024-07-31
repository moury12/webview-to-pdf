import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_to_pdf/main.dart';

class WebToPdf extends StatefulWidget {
  @override
  _WebToPdfState createState() => _WebToPdfState();
}

class _WebToPdfState extends State<WebToPdf> {
  late WebViewController _controller;
  final ScreenshotController screenshotController = ScreenshotController();
  bool hasBottomReached = false;
  bool buttonDisable = false;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev'))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          _checkIfScrolledToBottom();
        },
      ));
  }

  void scrollToTop() {
    buttonDisable = false;
    setState(() {});
    _controller.runJavaScript("window.scrollTo({top: 0, behavior: 'smooth'});");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Screenshot'),
        actions: [
          IconButton(
              onPressed: scrollToTop,
              icon:  Icon(Icons.arrow_circle_up_outlined,color: loading ? Colors.grey : Colors.black,)),
          IconButton(
              onPressed: buttonDisable ||loading? () {} : _scrollToBottom,
              icon: Icon(
                Icons.arrow_circle_down_outlined,
                color: buttonDisable||loading ? Colors.grey : Colors.black,
              )),
          FutureBuilder<bool>(
              future: isImagesBoxEmpty(),
              builder: (context, snapshot) {
                return IconButton(
                    onPressed: () {
                      convertImageToPdf();
                    },
                    icon: Icon(
                      Icons.file_download,
                      color: snapshot.data == true ||loading? Colors.grey : Colors.black,
                    ));
              }),
        ],
      ),
      body: Stack(
        children: [
          Screenshot(
            controller: screenshotController,
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
          loading
              ? Center(
                  child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue,
                            backgroundColor: Colors.black,
                          ),
                          Text('pdf is downloading, please wait ')
                        ],
                      )),
                )
              : SizedBox.shrink()
        ],
      ),
    );
  }

  Future<bool> isImagesBoxEmpty() async {
    final box = await openImagesBox();
    return box.isEmpty;
  }

  Future<void> convertImageToPdf() async {
    final pdf = pw.Document();
    var box = await openImagesBox();
    final images = box.values.toList();
    if (box.isNotEmpty) {
      for (var image in images) {
        setState(() {
          loading = true;
        });
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
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Open pdf',
            onPressed: () {OpenFile.open(file.path);},
          )));

     await box.clear();
      scrollToTop();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image List is empty')));
    }
  }

  void _checkIfScrolledToBottom() async {
    Object result = await _controller.runJavaScriptReturningResult("""
        (function() {
          return (window.innerHeight + window.scrollY) >= document.body.scrollHeight;
        })();
        """);
    // The result will be "true" or "false", convert to boolean
    setState(() {
      hasBottomReached = result == true;
    });
    print('Reached the bottom: $hasBottomReached');
  }

  void _scrollToBottom() async {
//document.body.scrollHeight//bottom of screen

    String jsScrollDown = """(function() {
        var viewportHeight = window.innerHeight;
        var scrollPosition = window.scrollY;
        window.scrollTo(0, scrollPosition + viewportHeight);
        return (window.innerHeight + window.scrollY) >= document.body.offsetHeight;
      })();""";
    _checkIfScrolledToBottom();
    await _controller.runJavaScriptReturningResult(jsScrollDown);

    if (!hasBottomReached) {
      Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final box = await openImagesBox();

        box.add(imageBytes);
      }
    } else {
      buttonDisable = true;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reached bottom of the content. now capture pdf')));
      print('Reached bottom of the content.');
    }
  }

  Future<Box<Uint8List>> openImagesBox() async {
    return await Hive.openBox<Uint8List>('imagesBox');
  }
}
